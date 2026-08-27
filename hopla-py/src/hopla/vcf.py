"""Stream selected SNVs from a VCF into compact NumPy matrices."""

from __future__ import annotations

from collections.abc import Sequence
from pathlib import Path
from typing import Any

import numpy as np
from cyvcf2 import VCF  # type: ignore[import-untyped]

from hopla.models import CHROMOSOME_CODES, GenotypeMatrix, SiteTable


def _format_matrix(variant: Any, key: str, samples: int, columns: int = 1) -> np.ndarray:
    """Read a FORMAT matrix and normalize absent values to zero."""
    try:
        values = np.asarray(variant.format(key))
    except (KeyError, TypeError):
        values = np.zeros((samples, columns), dtype=np.int32)
    if values.ndim == 1:
        values = values[:, None]
    result = np.zeros((samples, columns), dtype=np.int64)
    width = min(columns, values.shape[1])
    result[:, :width] = values[:, :width]
    result[result < 0] = 0
    return result


def load_vcf(path: Path, samples: tuple[str, ...]) -> tuple[SiteTable, GenotypeMatrix]:
    """Stream biallelic SNVs and selected sample FORMAT fields from a VCF."""
    reader = VCF(str(path), samples=list(samples), lazy=True)
    missing = set(samples) - set(reader.samples)
    if missing:
        raise ValueError(f"Sample(s) not found in vcf_file: {', '.join(sorted(missing))}")
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
        raw_gt = np.asarray(variant.genotypes, dtype=np.int16)
        gt = np.full(len(samples), -1, dtype=np.int8)
        called = (raw_gt[:, 0] >= 0) & (raw_gt[:, 1] >= 0)
        gt[called] = (raw_gt[called, 0] + raw_gt[called, 1]).astype(np.int8)
        if chrom == "chrX":
            haploid = (raw_gt[:, 0] >= 0) & (raw_gt[:, 1] < 0)
            gt[haploid] = (raw_gt[haploid, 0] * 2).astype(np.int8)
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
        gt=np.stack(genotypes, axis=1),
        dp=np.stack(depths, axis=1),
        ad_ref=np.stack(ref_depths, axis=1),
        ad_alt=np.stack(alt_depths, axis=1),
        samples=samples,
        sample_index={sample: index for index, sample in enumerate(samples)},
    )
    return sites, matrix


def mask_male_x_heterozygotes(
    sites: SiteTable,
    matrix: GenotypeMatrix,
    sample_ids: Sequence[str],
    genders: Sequence[str | None],
) -> None:
    """Mark diploid heterozygous chromosome-X calls missing in male samples."""
    x_mask = sites.chrom == CHROMOSOME_CODES["chrX"]
    for sample in matrix.samples:
        if genders[sample_ids.index(sample)] == "M":
            sample_index = matrix.sample_index[sample]
            matrix.gt[sample_index, x_mask & (matrix.gt[sample_index] == 1)] = -1
