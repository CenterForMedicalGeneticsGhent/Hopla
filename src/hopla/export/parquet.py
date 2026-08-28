"""Write portable, explicitly documented Parquet analysis exports."""

from __future__ import annotations

import json
from datetime import UTC, datetime
from pathlib import Path

import polars as pl

FILE_NAMES = {
    "variant_stats": "variant_stats.parquet",
    "genotype_counts": "genotype_counts.parquet",
    "variant_depth": "variant_depth.parquet",
    "variant_density": "variant_density.parquet",
    "ado_adi": "ado_adi.parquet",
    "baf": "baf.parquet",
    "copy_number": "copy_number.parquet",
    "cn_segments": "cn_segments.parquet",
    "mendelian": "mendelian.parquet",
    "parent_mapping": "parent_mapping.parquet",
    "haplotypes": "haplotypes.parquet",
    "haplotype_concordance": "haplotype_concordance.parquet",
}

COLUMN_DESCRIPTIONS = {
    "chrom": "Canonical hg38 chromosome name.",
    "pos": "One-based genomic position.",
    "start": "One-based inclusive interval start.",
    "end": "One-based inclusive interval end.",
    "af": "Alternate-allele fraction in the inclusive range 0 to 1.",
    "log2_ratio": "Base-2 normalized depth ratio.",
    "seg_mean": "Mean normalized log2 ratio in the segment.",
    "filter_level": "Hopla filter stage: 0 raw, 1 depth/AF, 2 informative/heterozygous.",
    "is_corrected": "Whether Hopla corrected the raw Merlin haplotype call.",
}


def export_parquet(
    directory: Path,
    family_id: str,
    tables: dict[str, pl.DataFrame],
    *,
    genome: str = "hg38",
) -> Path:
    """Write every visualized table as zstd Parquet and a portable manifest."""
    directory.mkdir(parents=True, exist_ok=True)
    files: list[dict[str, object]] = []
    for table_name, file_name in FILE_NAMES.items():
        frame = tables.get(table_name)
        if frame is None or frame.is_empty():
            continue
        target = directory / file_name
        frame.write_parquet(
            target,
            compression="zstd",
            statistics=True,
            row_group_size=100_000,
        )
        files.append(
            {
                "table": table_name,
                "path": file_name,
                "rows": frame.height,
                "columns": [
                    {
                        "name": name,
                        "type": str(dtype),
                        "description": COLUMN_DESCRIPTIONS.get(name, ""),
                    }
                    for name, dtype in frame.schema.items()
                ],
            }
        )
    manifest = {
        "format": "hopla-portable-export",
        "version": 1,
        "family_id": family_id,
        "genome": genome,
        "coordinates": "1-based inclusive",
        "created_at": datetime.now(UTC).isoformat(),
        "files": files,
    }
    (directory / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return directory
