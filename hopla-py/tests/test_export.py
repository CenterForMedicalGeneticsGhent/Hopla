"""Portable Parquet export tests."""

from __future__ import annotations

import json
from pathlib import Path

import polars as pl
import pyarrow.parquet as pq

from hopla.export import export_parquet


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
