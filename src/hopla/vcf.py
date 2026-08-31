"""Stream selected SNVs from a VCF into compact NumPy matrices."""

from __future__ import annotations

from collections.abc import Sequence
from pathlib import Path
from typing import Any

import numpy as np
from cyvcf2 import VCF  # type: ignore[import-untyped]

from hopla.models import CHROMOSOME_CODES, GenotypeMatrix, SiteTable

# cyvcf2 pads ragged genotype rows so that mixed-ploidy sites stay rectangular.
ABSENT_ALLELE = -2


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


def load_vcf(path: Path, samples: tuple[str, ...]) -> tuple[SiteTable, GenotypeMatrix]:
    """Stream biallelic SNVs and selected sample FORMAT fields from a VCF."""
    reader = VCF(str(path), samples=list(samples), lazy=True)
    missing = set(samples) - set(reader.samples)
    if missing:
        raise ValueError(f"Sample(s) not found in vcf_file: {', '.join(sorted(missing))}")
    # cyvcf2 yields subset columns in file order, so map them onto the requested order.
    file_order = list(reader.samples)
    permutation = np.asarray([file_order.index(sample) for sample in samples])
    chroms: list[int] = []
    positions: list[int] = []
    refs: list[str] = []
    alts: list[str] = []
    genotypes: list[np.ndarray] = []
    depths: list[np.ndarray] = []
    ref_depths: list[np.ndarray] = []
    alt_depths: list[np.ndarray] = []
    for variant in reader:
        chrom = variant.CHROM if str(variant.CHROM).startswith("chr") else f"chr{variant.CHROM}"
        alt = variant.ALT[0] if len(variant.ALT) == 1 else ""
        if chrom not in CHROMOSOME_CODES or len(variant.REF) != 1 or len(alt) != 1:
            continue
        gt = _decode_genotypes(variant, len(samples), haploid_is_homozygous=chrom == "chrX")
        ad = _format_matrix(variant, "AD", len(samples), 2)
        dp = _format_matrix(variant, "DP", len(samples))[:, 0]
        chroms.append(CHROMOSOME_CODES[chrom])
        positions.append(int(variant.POS))
        refs.append(str(variant.REF))
        alts.append(str(alt))
        genotypes.append(gt)
        depths.append(np.clip(dp, 0, np.iinfo(np.uint16).max).astype(np.uint16))
        ref_depths.append(np.clip(ad[:, 0], 0, np.iinfo(np.uint16).max).astype(np.uint16))
        alt_depths.append(np.clip(ad[:, 1], 0, np.iinfo(np.uint16).max).astype(np.uint16))
    reader.close()
    if not positions:
        raise ValueError("VCF contains no supported biallelic SNVs.")
    sites = SiteTable(
        chrom=np.asarray(chroms, dtype=np.uint8),
        pos=np.asarray(positions, dtype=np.uint32),
        ref=np.asarray(refs, dtype=np.str_),
        alt=np.asarray(alts, dtype=np.str_),
    )
    matrix = GenotypeMatrix(
        gt=np.stack(genotypes, axis=1)[permutation],
        dp=np.stack(depths, axis=1)[permutation],
        ad_ref=np.stack(ref_depths, axis=1)[permutation],
        ad_alt=np.stack(alt_depths, axis=1)[permutation],
        samples=samples,
        sample_index={sample: index for index, sample in enumerate(samples)},
    )
    return sites, matrix


def mask_male_x_heterozygotes(
    sites: SiteTable,
    matrix: GenotypeMatrix,
    sample_ids: Sequence[str],
    sexes: Sequence[str | None],
) -> None:
    """Mark diploid heterozygous chromosome-X calls missing in male samples."""
    x_mask = sites.chrom == CHROMOSOME_CODES["chrX"]
    for sample in matrix.samples:
        if sexes[sample_ids.index(sample)] == "M":
            sample_index = matrix.sample_index[sample]
            matrix.gt[sample_index, x_mask & (matrix.gt[sample_index] == 1)] = -1
