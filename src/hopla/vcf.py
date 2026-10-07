"""Stream selected SNVs from a VCF into compact NumPy matrices."""

from __future__ import annotations

import logging
import os
import shutil
import subprocess
from collections.abc import Iterable
from concurrent.futures import ProcessPoolExecutor
from dataclasses import dataclass, field
from functools import partial
from multiprocessing import get_context
from pathlib import Path
from typing import Any

import numpy as np
from cyvcf2 import VCF  # type: ignore[import-untyped]

from hopla.models import CHROMOSOME_CODES, GenotypeMatrix, SiteTable
from hopla.settings import Settings

# cyvcf2 pads ragged genotype rows so that mixed-ploidy sites stay rectangular.
ABSENT_ALLELE = -2


@dataclass(slots=True)
class _CollectedSites:
    """Accumulate retained SNV columns before stacking into matrices."""

    chrom: list[int] = field(default_factory=list)
    pos: list[int] = field(default_factory=list)
    ref: list[str] = field(default_factory=list)
    alt: list[str] = field(default_factory=list)
    genotypes: list[np.ndarray] = field(default_factory=list)
    depths: list[np.ndarray] = field(default_factory=list)
    ref_depths: list[np.ndarray] = field(default_factory=list)
    alt_depths: list[np.ndarray] = field(default_factory=list)


@dataclass(slots=True, frozen=True)
class _ContigTable:
    """Stacked site and genotype columns for one contig."""

    chrom: np.ndarray
    pos: np.ndarray
    ref: np.ndarray
    alt: np.ndarray
    gt: np.ndarray
    dp: np.ndarray
    ad_ref: np.ndarray
    ad_alt: np.ndarray


def _format_matrix(variant: Any, key: str, samples: int, columns: int = 1) -> np.ndarray:
    """Read a FORMAT matrix and normalize absent or missing values to zero."""
    result = np.zeros((samples, columns), dtype=np.int64)
    try:
        raw = variant.format(key)
    except KeyError:
        return result
    if raw is None:
        return result
    values = np.asarray(raw)
    if values.ndim == 1:
        values = values[:, None]
    if values.ndim != 2 or values.shape[0] != samples:
        return result
    width = min(columns, values.shape[1])
    result[:, :width] = values[:, :width]
    result[result < 0] = 0
    return result


def _decode_genotypes(variant: Any, samples: int, haploid_is_homozygous: bool) -> np.ndarray:
    """Decode calls to 0, 1, 2, or -1, tolerating sites that mix haploid and diploid records."""
    raw = np.asarray(variant.genotype.array())
    alleles = raw[:, :-1]
    if alleles.shape[1] < 2:
        padding = ((0, 0), (0, 2 - alleles.shape[1]))
        alleles = np.pad(alleles, padding, constant_values=ABSENT_ALLELE)
    present = alleles != ABSENT_ALLELE
    ploidy = present.sum(axis=1)
    complete = np.all((alleles >= 0) | ~present, axis=1)
    result = np.full(samples, -1, dtype=np.int8)
    diploid = complete & (ploidy == 2)
    result[diploid] = np.clip(alleles[diploid, 0] + alleles[diploid, 1], 0, 2)
    if haploid_is_homozygous:
        # Hopla treats a haploid chromosome-X call as its homozygous diploid equivalent.
        haploid = complete & (ploidy == 1)
        result[haploid] = np.clip(alleles[haploid, 0] * 2, 0, 2)
    return result


def _canonical_chrom(name: object) -> str | None:
    """Return the Hopla chromosome label, or None when the contig is unsupported."""
    text = str(name)
    chrom = text if text.startswith("chr") else f"chr{text}"
    return chrom if chrom in CHROMOSOME_CODES else None


def _has_index(path: Path) -> bool:
    """Return whether a sibling tabix or CSI index exists."""
    return any(path.with_name(f"{path.name}{suffix}").is_file() for suffix in (".tbi", ".csi"))


def _looks_bgzf(path: Path) -> bool:
    """Return whether the file starts with gzip magic, as required for tabix."""
    with path.open("rb") as handle:
        return handle.read(2) == b"\x1f\x8b"


def _ensure_index(path: Path) -> bool:
    """Write a sibling tabix index for a BGZF VCF when none exists."""
    if _has_index(path):
        return True
    if not _looks_bgzf(path):
        return False
    tabix = shutil.which("tabix")
    if tabix is None:
        logging.warning("tabix is not on PATH; VCF loading will be single-threaded.")
        return False
    logging.info("No tabix/CSI index found for %s; writing a tabix index.", path)
    try:
        subprocess.run([tabix, "-p", "vcf", str(path)], check=True, capture_output=True, text=True)
    except (OSError, subprocess.CalledProcessError) as error:
        detail: object = error
        if isinstance(error, subprocess.CalledProcessError):
            detail = (error.stderr or error.stdout or str(error)).strip()
        logging.warning(
            "Could not write a tabix index for %s: %s; VCF loading will be single-threaded.",
            path,
            detail,
        )
        return False
    return _has_index(path)


def _collect_variants(variants: Iterable[Any], sample_count: int) -> _CollectedSites:
    """Retain biallelic SNVs from a cyvcf2 iterator."""
    collected = _CollectedSites()
    for variant in variants:
        chrom = _canonical_chrom(variant.CHROM)
        alt = variant.ALT[0] if len(variant.ALT) == 1 else ""
        if chrom is None or len(variant.REF) != 1 or len(alt) != 1:
            continue
        gt = _decode_genotypes(variant, sample_count, haploid_is_homozygous=chrom == "chrX")
        ad = _format_matrix(variant, "AD", sample_count, 2)
        dp = _format_matrix(variant, "DP", sample_count)[:, 0]
        collected.chrom.append(CHROMOSOME_CODES[chrom])
        collected.pos.append(int(variant.POS))
        collected.ref.append(str(variant.REF))
        collected.alt.append(str(alt))
        collected.genotypes.append(gt)
        collected.depths.append(np.clip(dp, 0, np.iinfo(np.uint16).max).astype(np.uint16))
        collected.ref_depths.append(np.clip(ad[:, 0], 0, np.iinfo(np.uint16).max).astype(np.uint16))
        collected.alt_depths.append(np.clip(ad[:, 1], 0, np.iinfo(np.uint16).max).astype(np.uint16))
    return collected


def _load_contig(contig: str, path: Path, samples: tuple[str, ...]) -> _ContigTable | None:
    """Stream one contig through an independent cyvcf2 reader."""
    reader = VCF(str(path), samples=list(samples), lazy=True)
    try:
        return _stack_sites(_collect_variants(reader(contig), len(samples)))
    finally:
        reader.close()


def _supported_contigs(seqnames: Iterable[object]) -> list[str]:
    """Keep header contig names that map onto Hopla chromosomes, in header order."""
    return [str(name) for name in seqnames if _canonical_chrom(name) is not None]


def _stack_sites(collected: _CollectedSites) -> _ContigTable | None:
    """Stack retained columns for one contig, or None when nothing was kept."""
    if not collected.pos:
        return None
    return _ContigTable(
        chrom=np.asarray(collected.chrom, dtype=np.uint8),
        pos=np.asarray(collected.pos, dtype=np.uint32),
        ref=np.asarray(collected.ref, dtype=np.str_),
        alt=np.asarray(collected.alt, dtype=np.str_),
        gt=np.stack(collected.genotypes, axis=1),
        dp=np.stack(collected.depths, axis=1),
        ad_ref=np.stack(collected.ref_depths, axis=1),
        ad_alt=np.stack(collected.alt_depths, axis=1),
    )


def _concat_contigs(
    tables: Iterable[_ContigTable | None],
    samples: tuple[str, ...],
    permutation: np.ndarray,
) -> tuple[SiteTable, GenotypeMatrix]:
    """Join per-contig arrays in header order."""
    present = [table for table in tables if table is not None]
    if not present:
        raise ValueError("VCF contains no supported biallelic SNVs.")
    sites = SiteTable(
        chrom=np.concatenate([table.chrom for table in present]),
        pos=np.concatenate([table.pos for table in present]),
        ref=np.concatenate([table.ref for table in present]),
        alt=np.concatenate([table.alt for table in present]),
    )
    matrix = GenotypeMatrix(
        gt=np.concatenate([table.gt for table in present], axis=1)[permutation],
        dp=np.concatenate([table.dp for table in present], axis=1)[permutation],
        ad_ref=np.concatenate([table.ad_ref for table in present], axis=1)[permutation],
        ad_alt=np.concatenate([table.ad_alt for table in present], axis=1)[permutation],
        samples=samples,
        sample_index={sample: index for index, sample in enumerate(samples)},
    )
    return sites, matrix


def load_vcf(
    path: Path,
    samples: tuple[str, ...],
    *,
    threads: int | None = None,
) -> tuple[SiteTable, GenotypeMatrix]:
    """Stream biallelic SNVs and selected sample FORMAT fields from a VCF."""
    resolved = os.cpu_count() or 1 if threads is None else threads
    indexed = _ensure_index(path)
    reader = VCF(str(path), samples=list(samples), lazy=True)
    missing = set(samples) - set(reader.samples)
    if missing:
        reader.close()
        raise ValueError(f"Sample(s) not found in vcf_file: {', '.join(sorted(missing))}")
    # cyvcf2 yields subset columns in file order, so map them onto the requested order.
    file_order = list(reader.samples)
    permutation = np.asarray([file_order.index(sample) for sample in samples])
    contigs = _supported_contigs(reader.seqnames)
    workers = min(resolved, len(contigs)) if indexed else 1
    if resolved > 1 and not indexed:
        logging.warning(
            "No tabix/CSI index found for %s; VCF loading will be single-threaded.",
            path,
        )
    if workers <= 1:
        try:
            collected = _collect_variants(reader, len(samples))
        finally:
            reader.close()
        return _concat_contigs((_stack_sites(collected),), samples, permutation)
    reader.close()
    with ProcessPoolExecutor(max_workers=workers, mp_context=get_context("spawn")) as pool:
        return _concat_contigs(
            pool.map(partial(_load_contig, path=path, samples=samples), contigs),
            samples,
            permutation,
        )


def mask_male_x_heterozygotes(
    sites: SiteTable,
    matrix: GenotypeMatrix,
    settings: Settings,
) -> None:
    """Mark diploid heterozygous chromosome-X calls missing in male samples."""
    x_mask = sites.chrom == CHROMOSOME_CODES["chrX"]
    for sample in matrix.samples:
        if settings.family.member(sample).sex == "M":
            sample_index = matrix.sample_index[sample]
            matrix.gt[sample_index, x_mask & (matrix.gt[sample_index] == 1)] = -1
