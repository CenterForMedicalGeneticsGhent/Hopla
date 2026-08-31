"""Apply pedigree-aware genotype filters using vectorized NumPy operations."""

from __future__ import annotations

import numpy as np

from hopla.models import CHROMOSOME_CODES, FilteredGenotypes, GenotypeMatrix, SiteTable
from hopla.settings import Settings


def apply_filter1(
    sites: SiteTable, matrix: GenotypeMatrix, settings: Settings
) -> FilteredGenotypes:
    """Apply hard site filters and soft per-sample depth masking."""
    af = matrix.allele_fraction()
    if settings.af_hard_limit_ids:
        indices = [matrix.sample_index[sample] for sample in settings.af_hard_limit_ids]
        af_keep = np.any(af[indices] >= settings.af_hard_limit, axis=0)
    else:
        af_keep = np.ones(sites.size, dtype=np.bool_)
    if settings.dp_hard_limit_ids:
        indices = [matrix.sample_index[sample] for sample in settings.dp_hard_limit_ids]
        dp_keep = np.all(matrix.dp[indices] >= settings.dp_hard_limit, axis=0)
    else:
        dp_keep = np.ones(sites.size, dtype=np.bool_)
    site_mask = af_keep & dp_keep
    if not np.any(site_mask):
        raise ValueError("No variants remain after applying filter 1.")
    gt = matrix.gt[:, site_mask].copy()
    filtered_dp = matrix.dp[:, site_mask].astype(np.float32)
    filtered_af = af[:, site_mask].copy()
    for sample in settings.dp_soft_limit_ids:
        index = matrix.sample_index[sample]
        soft = filtered_dp[index] >= settings.dp_soft_limit
        gt[index, ~soft] = -1
        filtered_dp[index, ~soft] = np.nan
        filtered_af[index, ~soft] = np.nan
    if np.any(np.all(gt < 0, axis=1)):
        sample = matrix.samples[int(np.flatnonzero(np.all(gt < 0, axis=1))[0])]
        raise ValueError(f"No variants remain for sample {sample} after applying filter 1.")
    return FilteredGenotypes(site_mask=site_mask, gt=gt, dp=filtered_dp, af=filtered_af)


def apply_filter2(
    sites: SiteTable,
    matrix: GenotypeMatrix,
    filtered: FilteredGenotypes,
    settings: Settings,
) -> FilteredGenotypes:
    """Keep informative and requested heterozygous markers."""
    selected_chrom = sites.chrom[filtered.site_mask]
    site_keep = np.ones(selected_chrom.size, dtype=np.bool_)
    gt = filtered.gt.copy()
    if len(settings.keep_informative_ids) == 2:
        first, second = (matrix.sample_index[s] for s in settings.keep_informative_ids)
        informative = ((gt[first] == 1) & np.isin(gt[second], (0, 2))) | (
            (gt[second] == 1) & np.isin(gt[first], (0, 2))
        )
        sexes = [
            settings.sexes[settings.sample_ids.index(sample)]
            for sample in settings.keep_informative_ids
        ]
        if sexes == ["M", "M"]:
            informative[selected_chrom == CHROMOSOME_CODES["chrX"]] = True
        site_keep &= informative
    if settings.keep_hetero_ids:
        indices = [matrix.sample_index[sample] for sample in settings.keep_hetero_ids]
        hetero = np.any(gt[indices] == 1, axis=0)
        hetero[selected_chrom == CHROMOSOME_CODES["chrX"]] = True
        site_keep &= hetero
    retained = set(int(value) for value in np.unique(selected_chrom[site_keep]))
    if not set(range(1, 24)).issubset(retained):
        raise ValueError("No variants remain in at least one chromosome after applying filter 2.")
    gt = gt[:, site_keep]
    dp = filtered.dp[:, site_keep]
    af = filtered.af[:, site_keep]
    autosomal = selected_chrom[site_keep] <= 22
    for sample in settings.keep_hetero_ids:
        index = matrix.sample_index[sample]
        non_hetero = (gt[index] != 1) & autosomal
        gt[index, non_hetero] = -1
        dp[index, non_hetero] = np.nan
        af[index, non_hetero] = np.nan
    source_indices = np.flatnonzero(filtered.site_mask)[site_keep]
    complete_mask = np.zeros(sites.size, dtype=np.bool_)
    complete_mask[source_indices] = True
    return FilteredGenotypes(site_mask=complete_mask, gt=gt, dp=dp, af=af)
