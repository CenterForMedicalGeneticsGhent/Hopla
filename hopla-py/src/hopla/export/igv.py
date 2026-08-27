"""Export quantitative and categorical report series as IGV tracks."""

from __future__ import annotations

import re
from html import escape
from pathlib import Path

import polars as pl
import pyBigWig  # type: ignore[import-untyped]


def _safe_name(value: str) -> str:
    """Convert a sample or track label to a portable filename component."""
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value)


def _write_bigwig(
    path: Path,
    frame: pl.DataFrame,
    chromosome_sizes: dict[str, int],
    value_column: str,
) -> None:
    """Write sorted, de-duplicated one-based intervals to BigWig."""
    grouped = (
        frame.filter(pl.col("chrom").is_in(chromosome_sizes))
        .group_by("chrom", "start", "end")
        .agg(pl.col(value_column).mean())
    )
    ordered = [
        grouped.filter(pl.col("chrom") == chrom).sort("start")
        for chrom in chromosome_sizes
        if not grouped.filter(pl.col("chrom") == chrom).is_empty()
    ]
    normalized = pl.concat(ordered) if ordered else grouped.clear()
    writer = pyBigWig.open(str(path), "w")
    try:
        writer.addHeader(list(chromosome_sizes.items()))
        if not normalized.is_empty():
            writer.addEntries(
                normalized["chrom"].to_list(),
                (normalized["start"] - 1).to_list(),
                ends=normalized["end"].to_list(),
                values=normalized[value_column].cast(pl.Float64).to_list(),
            )
    finally:
        writer.close()


def _quantitative_tracks(
    directory: Path, tables: dict[str, pl.DataFrame], chromosome_sizes: dict[str, int]
) -> list[Path]:
    """Write BAF, copy-number, and Mendelian-error BigWigs."""
    outputs: list[Path] = []
    baf = tables.get("baf")
    if baf is not None and not baf.is_empty():
        for sample in baf["sample"].unique().sort().to_list():
            frame = baf.filter(pl.col("sample") == sample).with_columns(
                pl.col("pos").alias("start"), pl.col("pos").alias("end")
            )
            target = directory / f"{_safe_name(sample)}-baf.bw"
            _write_bigwig(target, frame, chromosome_sizes, "af")
            outputs.append(target)
    copy_number = tables.get("copy_number")
    if copy_number is not None and not copy_number.is_empty():
        for sample in copy_number["sample"].unique().sort().to_list():
            target = directory / f"{_safe_name(sample)}-copy-number.bw"
            _write_bigwig(
                target,
                copy_number.filter((pl.col("sample") == sample) & pl.col("mask")),
                chromosome_sizes,
                "log2_ratio",
            )
            outputs.append(target)
    mendelian = tables.get("mendelian")
    if mendelian is not None and not mendelian.is_empty():
        for sample in mendelian["sample"].unique().sort().to_list():
            for relation in ("trio", "father", "mother"):
                target = directory / f"{_safe_name(sample)}-mendelian-{relation}.bw"
                _write_bigwig(
                    target,
                    mendelian.filter(pl.col("sample") == sample),
                    chromosome_sizes,
                    relation,
                )
                outputs.append(target)
    return outputs


def _write_segments(directory: Path, tables: dict[str, pl.DataFrame]) -> list[Path]:
    """Write copy-number segments in IGV's tab-separated SEG format."""
    segments = tables.get("cn_segments")
    if segments is None or segments.is_empty():
        return []
    path = directory / "copy-number.seg"
    segments.select(
        pl.col("sample").alias("ID"),
        pl.col("chrom").alias("chrom"),
        pl.col("start").alias("loc.start"),
        pl.col("end").alias("loc.end"),
        pl.lit("").alias("num.mark"),
        pl.col("seg_mean").alias("seg.mean"),
    ).write_csv(path, separator="\t")
    return [path]


def _write_bed_tracks(directory: Path, tables: dict[str, pl.DataFrame]) -> list[Path]:
    """Write categorical parent-mapping and haplotype calls as BED."""
    outputs: list[Path] = []
    parent = tables.get("parent_mapping")
    if parent is not None and not parent.is_empty():
        path = directory / "parent-mapping.bed"
        parent.select(
            "chrom",
            (pl.col("pos") - 1).alias("chromStart"),
            pl.col("pos").alias("chromEnd"),
            pl.concat_str("child", "origin", "zygosity", separator=":").alias("name"),
        ).sort("chrom", "chromStart").write_csv(path, separator="\t", include_header=False)
        outputs.append(path)
    haplotypes = tables.get("haplotypes")
    if haplotypes is not None and not haplotypes.is_empty():
        path = directory / "haplotypes.bed"
        haplotypes.select(
            "chrom",
            (pl.col("pos") - 1).alias("chromStart"),
            pl.col("pos").alias("chromEnd"),
            pl.concat_str("sample", "strand", "letter", separator=":").alias("name"),
        ).sort("chrom", "chromStart").write_csv(path, separator="\t", include_header=False)
        outputs.append(path)
    return outputs


def _write_session(directory: Path, tracks: list[Path], genome: str) -> Path:
    """Write an IGV desktop session referencing sibling tracks relatively."""
    resources = "".join(
        f'<Resource path="{escape(track.name)}"/>' for track in tracks
    )
    session = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        f'<Session genome="{escape(genome)}" version="8"><Resources>{resources}'
        "</Resources></Session>"
    )
    path = directory / "igv-session.xml"
    path.write_text(session, encoding="utf-8")
    return path


def export_igv_tracks(
    directory: Path,
    tables: dict[str, pl.DataFrame],
    chromosome_sizes: dict[str, int],
    *,
    genome: str = "hg38",
) -> tuple[Path, ...]:
    """Write all applicable report tables as IGV-compatible track files."""
    directory.mkdir(parents=True, exist_ok=True)
    tracks = [
        *_quantitative_tracks(directory, tables, chromosome_sizes),
        *_write_segments(directory, tables),
        *_write_bed_tracks(directory, tables),
    ]
    tracks.append(_write_session(directory, tracks, genome))
    return tuple(tracks)
