"""Download and parse UCSC cytoband records."""

from __future__ import annotations

import gzip
import urllib.request
from pathlib import Path

import polars as pl

from hopla.models import CHROMOSOMES, Cytoband

DEFAULT_CYTOBAND_URL = "https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/cytoBand.txt.gz"


def fetch_hg38(destination: Path) -> Path:
    """Download and decompress the default hg38 cytoband table."""
    with urllib.request.urlopen(DEFAULT_CYTOBAND_URL, timeout=60) as response:
        content = gzip.decompress(response.read())
    if not content:
        raise ValueError("Downloaded cytoband file is empty.")
    destination.write_bytes(content)
    return destination


def load_cytobands(path: Path) -> tuple[Cytoband, ...]:
    """Read a UCSC cytoband TSV and normalize chromosome names."""
    frame = pl.read_csv(
        path,
        separator="\t",
        has_header=False,
        new_columns=["chrom", "start", "end", "name", "stain"],
    ).with_columns(
        pl.when(pl.col("chrom").str.starts_with("chr"))
        .then(pl.col("chrom"))
        .otherwise(pl.lit("chr") + pl.col("chrom"))
        .alias("chrom")
    )
    order = {chrom: index for index, chrom in enumerate(CHROMOSOMES)}
    records = [
        Cytoband(
            chrom=str(row["chrom"]),
            start=int(row["start"]) + 1,
            end=int(row["end"]),
            name=str(row["name"] or row["stain"]),
            stain=str(row["stain"]),
        )
        for row in frame.iter_rows(named=True)
        if str(row["chrom"]) in order
    ]
    return tuple(sorted(records, key=lambda record: (order[record.chrom], record.start)))


def chromosome_sizes(cytobands: tuple[Cytoband, ...]) -> dict[str, int]:
    """Return chromosome lengths inferred from the last cytoband endpoint."""
    sizes: dict[str, int] = {}
    for band in cytobands:
        sizes[band.chrom] = max(sizes.get(band.chrom, 0), band.end)
    return sizes
