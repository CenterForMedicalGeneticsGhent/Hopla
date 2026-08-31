"""Orchestrate the complete Hopla analysis pipeline."""

from __future__ import annotations

import tempfile
from collections.abc import Callable
from pathlib import Path

from hopla.analysis import build_analysis_tables, haplotype_concordance
from hopla.cytobands import chromosome_sizes, fetch_hg38, load_cytobands
from hopla.export import export_igv_tracks, export_parquet
from hopla.filters import apply_filter1, apply_filter2
from hopla.merlin import run_merlin
from hopla.pedigree import add_ghosts, predict_sexes
from hopla.report import render_report
from hopla.settings import Settings
from hopla.vcf import load_vcf, mask_male_x_heterozygotes

ProgressCallback = Callable[[str], None]


def run_analysis(
    settings: Settings,
    vcf_path: Path,
    out_dir: Path,
    *,
    cytoband_path: Path | None = None,
    export_parquet_data: bool = True,
    export_bigwig: bool = True,
    progress: ProgressCallback | None = None,
) -> Path:
    """Run an analysis and return the generated HTML report path."""

    def update(message: str) -> None:
        if progress is not None:
            progress(message)

    update("Loading VCF")
    sites, matrix = load_vcf(vcf_path, settings.real_samples)
    settings.sexes = predict_sexes(settings, sites, matrix)
    mask_male_x_heterozygotes(sites, matrix, settings.sample_ids, settings.sexes)
    add_ghosts(settings)
    update("Applying filters")
    filtered1 = apply_filter1(sites, matrix, settings)
    filtered2 = apply_filter2(sites, matrix, filtered1, settings)
    with tempfile.TemporaryDirectory(prefix="hopla-cytobands-") as temporary:
        cytobands_file = cytoband_path or fetch_hg38(Path(temporary) / "cytoBand.txt")
        cytobands = load_cytobands(cytobands_file)
        sizes = chromosome_sizes(cytobands)
        update("Computing analyses")
        tables = build_analysis_tables(sites, matrix, filtered1, filtered2, settings)
        if settings.run_merlin:
            update("Running Merlin")
            tables["haplotypes"] = run_merlin(
                out_dir / f"{settings.fam_id}-merlin", sites, matrix, filtered2, settings
            )
            if settings.concordance_table:
                tables["haplotype_concordance"] = haplotype_concordance(tables["haplotypes"])
        if export_parquet_data:
            update("Writing portable Parquet exports")
            export_parquet(out_dir / f"{settings.fam_id}-export", settings.fam_id, tables)
        if export_bigwig:
            update("Writing IGV tracks")
            export_igv_tracks(out_dir / f"{settings.fam_id}-export", tables, sizes)
        update("Rendering report")
        report = out_dir / f"{settings.fam_id}-output.html"
        render_report(report, settings, tables, matrix.samples, cytobands)
    return report
