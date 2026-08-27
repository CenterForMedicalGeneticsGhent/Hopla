"""Portable Parquet export tests."""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import polars as pl
import pyarrow.parquet as pq
import pyBigWig  # type: ignore[import-untyped]

from hopla.export import export_igv_tracks, export_parquet


def test_parquet_manifest_and_non_python_round_trip(tmp_path: Path) -> None:
    """Write zstd Parquet that both Polars and Arrow can read."""
    tables = {
        "baf": pl.DataFrame(
            {
                "chrom": ["chr1", "chr1"],
                "pos": pl.Series([10, 20], dtype=pl.UInt32),
                "sample": ["A", "A"],
                "af": pl.Series([0.25, 0.75], dtype=pl.Float32),
                "filter_level": pl.Series([1, 1], dtype=pl.Int8),
            }
        )
    }
    directory = export_parquet(tmp_path / "family-export", "family", tables)
    manifest = json.loads((directory / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["coordinates"] == "1-based inclusive"
    assert manifest["files"][0]["path"] == "baf.parquet"
    assert pl.read_parquet(directory / "baf.parquet").equals(tables["baf"])
    arrow = pq.read_table(directory / "baf.parquet")
    assert arrow.column("pos").to_pylist() == [10, 20]
    assert arrow.schema.field("af").type.bit_width == 32


def test_igv_tracks_match_portable_tables(tmp_path: Path) -> None:
    """Write BAF BigWig, CN SEG, categorical BED, and an IGV session."""
    tables = {
        "baf": pl.DataFrame(
            {
                "chrom": ["chr1", "chr1"],
                "pos": [10, 20],
                "sample": ["A", "A"],
                "af": [0.25, 0.75],
            }
        ),
        "cn_segments": pl.DataFrame(
            {
                "chrom": ["chr1"],
                "start": [1],
                "end": [100],
                "sample": ["A"],
                "seg_mean": [0.1],
            }
        ),
        "parent_mapping": pl.DataFrame(
            {
                "chrom": ["chr1"],
                "pos": [10],
                "child": ["A"],
                "origin": ["father"],
                "zygosity": ["heterozygous"],
            }
        ),
    }
    outputs = export_igv_tracks(tmp_path, tables, {"chr1": 1_000})
    names = {path.name for path in outputs}
    assert {"A-baf.bw", "copy-number.seg", "parent-mapping.bed", "igv-session.xml"} <= names
    reader = pyBigWig.open(str(tmp_path / "A-baf.bw"))
    try:
        values = reader.values("chr1", 9, 20)
        assert values[0] == 0.25
        assert np.all(np.isnan(values[1:10]))
        assert values[10] == 0.75
    finally:
        reader.close()
