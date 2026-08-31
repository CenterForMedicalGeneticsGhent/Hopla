"""Stream selected SNVs from a VCF into compact NumPy matrices."""

from __future__ import annotations

import logging
import os
from collections.abc import Iterable
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
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

    def extend(self, other: _CollectedSites) -> None:
        """Append another contig's retained sites in order."""
        self.chrom.extend(other.chrom)
        self.pos.extend(other.pos)
        self.ref.extend(other.ref)
        self.alt.extend(other.alt)
        self.genotypes.extend(other.genotypes)
        self.depths.extend(other.depths)
        self.ref_depths.extend(other.ref_depths)
        self.alt_depths.extend(other.alt_depths)


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


def _index_path(path: Path) -> Path | None:
    """Return a sibling tabix or CSI index when one exists."""
    for suffix in (".tbi", ".csi"):
        candidate = path.with_name(f"{path.name}{suffix}")
        if candidate.is_file():
            return candidate
    return None


def _thread_count(threads: int | None) -> int:
    """Resolve omitted thread counts to the host CPU count."""
    if threads is None:
        return os.cpu_count() or 1
    return threads


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


def _load_contig(contig: str, path: Path, samples: tuple[str, ...]) -> _CollectedSites:
    """Stream one contig through an independent cyvcf2 reader."""
    reader = VCF(str(path), samples=list(samples), lazy=True)
    try:
        return _collect_variants(reader(contig), len(samples))
    finally:
        reader.close()


def _supported_contigs(seqnames: Iterable[object]) -> list[str]:
    """Keep header contig names that map onto Hopla chromosomes, in header order."""
    contigs: list[str] = []
    seen: set[str] = set()
    for name in seqnames:
        text = str(name)
        if text in seen or _canonical_chrom(text) is None:
            continue
        seen.add(text)
        contigs.append(text)
    return contigs


def _assemble(
    collected: _CollectedSites,
    samples: tuple[str, ...],
    permutation: np.ndarray,
) -> tuple[SiteTable, GenotypeMatrix]:
    """Stack retained columns into the shared site table and genotype matrices."""
    if not collected.pos:
        raise ValueError("VCF contains no supported biallelic SNVs.")
    sites = SiteTable(
        chrom=np.asarray(collected.chrom, dtype=np.uint8),
        pos=np.asarray(collected.pos, dtype=np.uint32),
        ref=np.asarray(collected.ref, dtype=np.str_),
        alt=np.asarray(collected.alt, dtype=np.str_),
    )
    matrix = GenotypeMatrix(
        gt=np.stack(collected.genotypes, axis=1)[permutation],
        dp=np.stack(collected.depths, axis=1)[permutation],
        ad_ref=np.stack(collected.ref_depths, axis=1)[permutation],
        ad_alt=np.stack(collected.alt_depths, axis=1)[permutation],
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
    resolved = _thread_count(threads)
    reader = VCF(str(path), samples=list(samples), lazy=True)
    missing = set(samples) - set(reader.samples)
    if missing:
        reader.close()
        raise ValueError(f"Sample(s) not found in vcf_file: {', '.join(sorted(missing))}")
    # cyvcf2 yields subset columns in file order, so map them onto the requested order.
    file_order = list(reader.samples)
    permutation = np.asarray([file_order.index(sample) for sample in samples])
    indexed = _index_path(path) is not None
    contigs = _supported_contigs(reader.seqnames)
    workers = min(resolved, len(contigs)) if indexed else 1
    if resolved > 1 and not indexed:
        logging.warning(
            "No tabix/CSI index found for %s; VCF loading will be single-threaded.",
            path,
        )
    if workers > 1:
        reader.close()
        collected = _CollectedSites()
        with ThreadPoolExecutor(max_workers=workers) as pool:
            futures = [
                pool.submit(_load_contig, contig, path, samples) for contig in contigs
            ]
            for future in futures:
                collected.extend(future.result())
        return _assemble(collected, samples, permutation)
    try:
        collected = _collect_variants(reader, len(samples))
    finally:
        reader.close()
    return _assemble(collected, samples, permutation)


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
