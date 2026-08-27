"""Vectorized family analyses and portable report tables."""

from __future__ import annotations

from collections.abc import Iterable

import numpy as np
import polars as pl

from hopla.models import CHROMOSOMES, FilteredGenotypes, GenotypeMatrix, SiteTable
from hopla.settings import Settings


def _chrom_names(codes: np.ndarray) -> np.ndarray:
    """Map compact chromosome codes to canonical names."""
    labels = np.asarray([""] + list(CHROMOSOMES) + ["chrY"], dtype=np.str_)
    return labels[codes]


def _window_ids(sites: SiteTable, mask: np.ndarray, size: int) -> tuple[np.ndarray, np.ndarray]:
    """Return chromosome-aware window starts and grouping keys."""
    starts = ((sites.pos[mask].astype(np.int64) - 1) // size) * size + 1
    keys = sites.chrom[mask].astype(np.int64) * (2**32) + starts
    return starts, keys


def variant_statistics(
    sites: SiteTable,
    matrix: GenotypeMatrix,
    filtered1: FilteredGenotypes,
    filtered2: FilteredGenotypes,
    settings: Settings,
) -> pl.DataFrame:
    """Calculate sample counts for each filter and configured region."""
    rows: list[dict[str, object]] = []
    levels = [
        (0, np.ones(sites.size, dtype=np.bool_), matrix.gt),
        (1, filtered1.site_mask, filtered1.gt),
        (2, filtered2.site_mask, filtered2.gt),
    ]
    for level, site_mask, gt in levels:
        for sample_index, sample in enumerate(matrix.samples):
            rows.append(
                {
                    "filter_level": level,
                    "sample": sample,
                    "region": "genome",
                    "metric": "variants",
                    "value": float(np.count_nonzero(gt[sample_index] >= 0)),
                }
            )
            selected_positions = sites.pos[site_mask]
            selected_chrom = _chrom_names(sites.chrom[site_mask])
            for region in settings.regions:
                chrom, interval = region.split(":")
                start, end = (int(value) for value in interval.split("-"))
                region_mask = (
                    (selected_chrom == chrom)
                    & (selected_positions >= start)
                    & (selected_positions <= end)
                )
                rows.append(
                    {
                        "filter_level": level,
                        "sample": sample,
                        "region": region,
                        "metric": "variants",
                        "value": float(np.count_nonzero((gt[sample_index] >= 0) & region_mask)),
                    }
                )
    return pl.DataFrame(rows)


def genotype_counts(
    sites: SiteTable,
    matrix: GenotypeMatrix,
    filtered1: FilteredGenotypes,
    filtered2: FilteredGenotypes,
) -> pl.DataFrame:
    """Count missing, homozygous, and heterozygous calls per filter and sample."""
    del sites
    labels = {-1: "missing", 0: "0/0", 1: "0/1", 2: "1/1"}
    rows: list[dict[str, object]] = []
    for level, calls in ((0, matrix.gt), (1, filtered1.gt), (2, filtered2.gt)):
        for sample_index, sample in enumerate(matrix.samples):
            values, counts = np.unique(calls[sample_index], return_counts=True)
            rows.extend(
                {
                    "filter_level": level,
                    "sample": sample,
                    "genotype": labels[int(value)],
                    "count": int(count),
                }
                for value, count in zip(values, counts, strict=True)
            )
    return pl.DataFrame(rows)


def variant_depth_table(matrix: GenotypeMatrix, filtered1: FilteredGenotypes) -> pl.DataFrame:
    """Build compact depth histograms for raw and filter-one calls."""
    rows: list[dict[str, object]] = []
    for level, depths in ((0, matrix.dp.astype(np.float32)), (1, filtered1.dp)):
        for sample_index, sample in enumerate(matrix.samples):
            valid = depths[sample_index][np.isfinite(depths[sample_index])]
            values, counts = np.unique(valid.astype(np.uint32), return_counts=True)
            rows.extend(
                {
                    "filter_level": level,
                    "sample": sample,
                    "depth": int(value),
                    "count": int(count),
                }
                for value, count in zip(values, counts, strict=True)
            )
    return pl.DataFrame(rows)


def variant_density_table(
    sites: SiteTable,
    matrix: GenotypeMatrix,
    filtered1: FilteredGenotypes,
    filtered2: FilteredGenotypes,
    window_size: int,
) -> pl.DataFrame:
    """Count callable variants in chromosome-aware genomic windows."""
    rows: list[pl.DataFrame] = []
    levels = (
        (0, np.ones(sites.size, dtype=np.bool_), matrix.gt),
        (1, filtered1.site_mask, filtered1.gt),
        (2, filtered2.site_mask, filtered2.gt),
    )
    for level, site_mask, calls in levels:
        source = np.flatnonzero(site_mask)
        starts, keys = _window_ids(sites, site_mask, window_size)
        chrom = _chrom_names(sites.chrom[source])
        for sample_index, sample in enumerate(matrix.samples):
            frame = (
                pl.DataFrame(
                    {
                        "_key": keys,
                        "chrom": chrom,
                        "start": starts,
                        "called": calls[sample_index] >= 0,
                    }
                )
                .group_by("_key", "chrom", "start")
                .agg(pl.col("called").sum().alias("count"))
                .with_columns(
                    (pl.col("start") + window_size - 1).alias("end"),
                    pl.lit(level).cast(pl.Int8).alias("filter_level"),
                    pl.lit(sample).alias("sample"),
                )
                .drop("_key")
            )
            rows.append(frame)
    return pl.concat(rows)


def ado_adi(matrix: GenotypeMatrix, settings: Settings) -> pl.DataFrame:
    """Calculate allelic drop-out and drop-in percentages for complete trios."""
    rows: list[dict[str, object]] = []
    for child in matrix.samples:
        pedigree_index = settings.sample_ids.index(child)
        father = settings.father_ids[pedigree_index]
        mother = settings.mother_ids[pedigree_index]
        if father not in matrix.sample_index or mother not in matrix.sample_index:
            continue
        child_gt = matrix.gt[matrix.sample_index[child]]
        father_gt = matrix.gt[matrix.sample_index[father]]
        mother_gt = matrix.gt[matrix.sample_index[mother]]
        ado_sites = ((father_gt == 0) & (mother_gt == 2)) | ((father_gt == 2) & (mother_gt == 0))
        ado_denominator = np.count_nonzero(ado_sites & (child_gt >= 0))
        ado = (
            100 * np.count_nonzero(ado_sites & np.isin(child_gt, (0, 2))) / ado_denominator
            if ado_denominator
            else np.nan
        )
        adi_sites = (father_gt == 2) & (mother_gt == 2)
        adi_denominator = np.count_nonzero(adi_sites & (child_gt >= 0))
        adi = (
            100 * np.count_nonzero(adi_sites & (child_gt == 1)) / adi_denominator
            if adi_denominator
            else np.nan
        )
        rows.extend(
            [
                {"sample": child, "metric": "ADO", "value": round(float(ado), 2)},
                {"sample": child, "metric": "ADI", "value": round(float(adi), 2)},
            ]
        )
    return pl.DataFrame(
        rows, schema={"sample": pl.String, "metric": pl.String, "value": pl.Float64}
    )


def baf_table(
    sites: SiteTable, matrix: GenotypeMatrix, filtered: FilteredGenotypes
) -> pl.DataFrame:
    """Build full-resolution B-allele-frequency rows for every sample."""
    selected = np.flatnonzero(filtered.site_mask)
    chrom = _chrom_names(sites.chrom[selected])
    frames = []
    for index, sample in enumerate(matrix.samples):
        valid = ~np.isnan(filtered.af[index])
        frames.append(
            pl.DataFrame(
                {
                    "chrom": chrom[valid],
                    "pos": sites.pos[selected][valid],
                    "sample": [sample] * int(np.count_nonzero(valid)),
                    "af": filtered.af[index][valid],
                    "filter_level": np.ones(int(np.count_nonzero(valid)), dtype=np.int8),
                }
            )
        )
    return pl.concat(frames) if frames else pl.DataFrame()


def _trio_errors(child: np.ndarray, first: np.ndarray, second: np.ndarray) -> np.ndarray:
    """Mark impossible child genotypes for informative parent pairs."""
    result = np.zeros(child.size, dtype=np.int8)
    minimum = np.minimum(first, second)
    maximum = np.maximum(first, second)
    informative = (first >= 0) & (second >= 0)
    result[informative] = 1
    impossible = (
        ((minimum == 0) & (maximum == 0) & np.isin(child, (1, 2)))
        | ((minimum == 0) & (maximum == 1) & (child == 2))
        | ((minimum == 1) & (maximum == 2) & (child == 0))
        | ((minimum == 2) & (maximum == 2) & np.isin(child, (0, 1)))
        | ((minimum == 0) & (maximum == 2) & np.isin(child, (0, 2)))
    )
    result[impossible] = 2
    return result


def _duo_errors(child: np.ndarray, parent: np.ndarray) -> np.ndarray:
    """Mark impossible child genotypes for one homozygous parent."""
    result = np.zeros(child.size, dtype=np.int8)
    informative = np.isin(parent, (0, 2))
    result[informative] = 1
    result[((parent == 0) & (child == 2)) | ((parent == 2) & (child == 0))] = 2
    return result


def mendelian_table(
    sites: SiteTable, matrix: GenotypeMatrix, filtered: FilteredGenotypes, settings: Settings
) -> pl.DataFrame:
    """Aggregate trio and duo Mendelian errors into genomic windows."""
    source = np.flatnonzero(filtered.site_mask)
    starts, keys = _window_ids(sites, filtered.site_mask, settings.window_size)
    frames: list[pl.DataFrame] = []
    for child in matrix.samples:
        pedigree = settings.sample_ids.index(child)
        father = settings.father_ids[pedigree]
        mother = settings.mother_ids[pedigree]
        child_gt = filtered.gt[matrix.sample_index[child]]
        trio = np.zeros(child_gt.size, dtype=np.int8)
        fat = np.zeros(child_gt.size, dtype=np.int8)
        mot = np.zeros(child_gt.size, dtype=np.int8)
        if father in matrix.sample_index:
            fat = _duo_errors(child_gt, filtered.gt[matrix.sample_index[father]])
        if mother in matrix.sample_index:
            mot = _duo_errors(child_gt, filtered.gt[matrix.sample_index[mother]])
        if father in matrix.sample_index and mother in matrix.sample_index:
            trio = _trio_errors(
                child_gt,
                filtered.gt[matrix.sample_index[father]],
                filtered.gt[matrix.sample_index[mother]],
            )
        if not np.any((fat == 2) | (mot == 2) | (trio == 2)):
            continue
        frame = (
            pl.DataFrame(
                {
                    "_key": keys,
                    "chrom": _chrom_names(sites.chrom[source]),
                    "start": starts,
                    "sample": [child] * source.size,
                    "trio": trio == 2,
                    "father": fat == 2,
                    "mother": mot == 2,
                }
            )
            .group_by("_key", "chrom", "start", "sample")
            .agg(pl.col("trio").sum(), pl.col("father").sum(), pl.col("mother").sum())
            .with_columns((pl.col("start") + settings.window_size - 1).alias("end"))
            .drop("_key")
        )
        frames.append(frame)
    return pl.concat(frames) if frames else pl.DataFrame()


def parent_mapping_table(
    sites: SiteTable, matrix: GenotypeMatrix, filtered: FilteredGenotypes, settings: Settings
) -> pl.DataFrame:
    """Classify informative child markers by parental origin and zygosity."""
    source = np.flatnonzero(filtered.site_mask)
    rows: list[pl.DataFrame] = []
    for child in matrix.samples:
        pedigree = settings.sample_ids.index(child)
        father = settings.father_ids[pedigree]
        mother = settings.mother_ids[pedigree]
        child_gt = filtered.gt[matrix.sample_index[child]]
        masks: list[tuple[str, np.ndarray]] = []
        if father in matrix.sample_index:
            father_gt = filtered.gt[matrix.sample_index[father]]
            other_hom = (
                np.isin(filtered.gt[matrix.sample_index[mother]], (0, 2))
                if mother in matrix.sample_index
                else np.ones(child_gt.size, dtype=np.bool_)
            )
            masks.append(("father", (father_gt == 1) & other_hom))
        if mother in matrix.sample_index:
            mother_gt = filtered.gt[matrix.sample_index[mother]]
            other_hom = (
                np.isin(filtered.gt[matrix.sample_index[father]], (0, 2))
                if father in matrix.sample_index
                else np.ones(child_gt.size, dtype=np.bool_)
            )
            masks.append(("mother", (mother_gt == 1) & other_hom))
        for origin, mask in masks:
            valid = mask & (child_gt >= 0)
            if np.any(valid):
                rows.append(
                    pl.DataFrame(
                        {
                            "chrom": _chrom_names(sites.chrom[source][valid]),
                            "pos": sites.pos[source][valid],
                            "child": [child] * int(np.count_nonzero(valid)),
                            "origin": [origin] * int(np.count_nonzero(valid)),
                            "zygosity": np.where(
                                child_gt[valid] == 1, "heterozygous", "homozygous"
                            ),
                        }
                    )
                )
    return pl.concat(rows) if rows else pl.DataFrame()


def _cbs_boundaries(values: np.ndarray, threshold: float = 3.0) -> list[tuple[int, int]]:
    """Recursively split a chromosome using a standardized CBS change statistic."""
    segments: list[tuple[int, int]] = []

    def split(left: int, right: int) -> None:
        """Split one interval at its strongest significant mean shift."""
        length = right - left
        if length < 6:
            segments.append((left, right))
            return
        local = values[left:right].astype(np.float64)
        cumulative = np.cumsum(local)
        points = np.arange(2, length - 1)
        left_mean = cumulative[points - 1] / points
        right_mean = (cumulative[-1] - cumulative[points - 1]) / (length - points)
        scale = float(np.std(local, ddof=1))
        if not np.isfinite(scale) or scale == 0:
            segments.append((left, right))
            return
        statistic = np.abs(left_mean - right_mean) / (
            scale * np.sqrt(1 / points + 1 / (length - points))
        )
        best = int(np.argmax(statistic))
        if statistic[best] < threshold:
            segments.append((left, right))
            return
        boundary = left + int(points[best])
        split(left, boundary)
        split(boundary, right)

    split(0, values.size)
    return sorted(segments)


def copy_number_table(
    sites: SiteTable, matrix: GenotypeMatrix, settings: Settings
) -> tuple[pl.DataFrame, pl.DataFrame]:
    """Calculate normalized depth windows and contiguous median-shift segments."""
    starts, keys = _window_ids(sites, np.ones(sites.size, dtype=np.bool_), settings.window_size)
    windows: list[pl.DataFrame] = []
    segments: list[pl.DataFrame] = []
    chrom_names = _chrom_names(sites.chrom)
    for index, sample in enumerate(matrix.samples):
        frame = (
            pl.DataFrame(
                {"_key": keys, "chrom": chrom_names, "start": starts, "depth": matrix.dp[index]}
            )
            .group_by("_key", "chrom", "start")
            .agg(
                pl.col("depth").mean().alias("mean_depth"),
                pl.len().alias("weight"),
            )
            .sort("_key")
        )
        median_value = frame["mean_depth"].median()
        median = float(median_value) if isinstance(median_value, (int, float)) else 1.0
        frame = frame.with_columns(
            (pl.col("mean_depth") / median).log(base=2).cast(pl.Float32).alias("log2_ratio"),
            (pl.col("start") + settings.window_size - 1).alias("end"),
            pl.lit(sample).alias("sample"),
            pl.lit(True).alias("mask"),
        ).drop("_key")
        windows.append(frame)
        segment_rows = []
        for chrom in CHROMOSOMES:
            chromosome_frame = frame.filter(pl.col("chrom") == chrom)
            values = chromosome_frame["log2_ratio"].to_numpy()
            if values.size == 0:
                continue
            for left_index, right_index in _cbs_boundaries(values):
                segment_rows.append(
                    {
                        "chrom": chrom,
                        "start": int(chromosome_frame["start"][left_index]),
                        "end": int(chromosome_frame["end"][right_index - 1]),
                        "sample": sample,
                        "seg_mean": float(np.mean(values[left_index:right_index])),
                    }
                )
        segments.append(pl.DataFrame(segment_rows))
    return pl.concat(windows), pl.concat(segments)


def build_analysis_tables(
    sites: SiteTable,
    matrix: GenotypeMatrix,
    filtered1: FilteredGenotypes,
    filtered2: FilteredGenotypes,
    settings: Settings,
) -> dict[str, pl.DataFrame]:
    """Build all non-Merlin data tables consumed by reports and exports."""
    copy_number, segments = copy_number_table(sites, matrix, settings)
    return {
        "variant_stats": variant_statistics(sites, matrix, filtered1, filtered2, settings),
        "genotype_counts": genotype_counts(sites, matrix, filtered1, filtered2),
        "variant_depth": variant_depth_table(matrix, filtered1),
        "variant_density": variant_density_table(
            sites, matrix, filtered1, filtered2, settings.window_size
        ),
        "ado_adi": ado_adi(matrix, settings),
        "baf": baf_table(sites, matrix, filtered1),
        "copy_number": copy_number,
        "cn_segments": segments,
        "mendelian": mendelian_table(sites, matrix, filtered1, settings),
        "parent_mapping": parent_mapping_table(sites, matrix, filtered1, settings),
    }


def haplotype_concordance(haplotypes: pl.DataFrame) -> pl.DataFrame:
    """Calculate pairwise concordance for all Merlin sample strands."""
    rows: list[dict[str, object]] = []
    sample_strands = [
        (str(sample), int(strand))
        for sample, strand in haplotypes.select("sample", "strand").unique().iter_rows()
    ]
    for left_index, (left_sample, left_strand) in enumerate(sample_strands):
        left = haplotypes.filter(
            (pl.col("sample") == left_sample) & (pl.col("strand") == left_strand)
        ).select("chrom", "pos", pl.col("letter").alias("left"))
        for right_sample, right_strand in sample_strands[left_index + 1 :]:
            right = haplotypes.filter(
                (pl.col("sample") == right_sample) & (pl.col("strand") == right_strand)
            ).select("chrom", "pos", pl.col("letter").alias("right"))
            aligned = left.join(right, on=["chrom", "pos"], how="inner").filter(
                (pl.col("left") != "X") & (pl.col("right") != "X")
            )
            mean = (aligned["left"] == aligned["right"]).mean() if not aligned.is_empty() else None
            rows.append(
                {
                    "sample_a": left_sample,
                    "strand_a": left_strand,
                    "sample_b": right_sample,
                    "strand_b": right_strand,
                    "concordance_percent": (
                        round(float(mean) * 100, 2) if isinstance(mean, (int, float)) else None
                    ),
                }
            )
    return pl.DataFrame(rows)


def iter_nonempty(tables: dict[str, pl.DataFrame]) -> Iterable[tuple[str, pl.DataFrame]]:
    """Yield report tables that contain at least one row."""
    return ((name, frame) for name, frame in tables.items() if not frame.is_empty())
