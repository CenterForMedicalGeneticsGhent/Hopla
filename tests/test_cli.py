"""CLI and subtool compatibility tests."""

from __future__ import annotations

from pathlib import Path

import polars as pl
from typer.testing import CliRunner

from hopla.cli import app

runner = CliRunner()


def _flow(path: Path, *, reverse: bool = False) -> None:
    """Write a minimal flow fixture."""
    frame = pl.DataFrame(
        {
            "chr": ["chr1", "chr2"],
            "pos": [1, 2],
            "flowA.hexcol": ["red", "blue"],
            "flowB.hexcol": ["green", "yellow"],
        }
    )
    if reverse:
        frame = frame.reverse()
    frame.write_csv(path, separator="\t")


def test_help_version_and_usage_status() -> None:
    """Expose help/version and reserve status two for usage errors."""
    assert runner.invoke(app, ["--help"]).exit_code == 0
    version = runner.invoke(app, ["--version"])
    assert version.exit_code == 0
    assert version.stdout == "v3.0.0\n"
    assert runner.invoke(app, ["serve", "--help"]).exit_code == 0
    assert runner.invoke(app, ["unknown"]).exit_code == 2


def test_convert_concordance_and_transform(tmp_path: Path) -> None:
    """Port all legacy CLI helper behavior."""
    legacy = tmp_path / "legacy.txt"
    legacy.write_text("sample.ids=A\ngenders=NA\nrun.merlin=FALSE\n", encoding="utf-8")
    converted = runner.invoke(app, ["convert", str(legacy)])
    assert converted.exit_code == 0
    assert legacy.with_suffix(".yaml").read_text(encoding="utf-8") == (
        "run_merlin: false\n"
        "family:\n"
        "  members:\n"
        "  - id: A\n"
        "    father: null\n"
        "    mother: null\n"
        "    sex: null\n"
    )
    first, second = tmp_path / "one-flow.txt", tmp_path / "two-flow.txt"
    _flow(first)
    _flow(second, reverse=True)
    concordance = runner.invoke(app, ["concordance", str(first), str(second)])
    assert concordance.exit_code == 0
    assert concordance.stdout.count("100.0%") == 2
    output = tmp_path / "relative.txt"
    transformed = runner.invoke(app, ["transform", str(first), str(second), "1", str(output)])
    assert transformed.exit_code == 0
    result = pl.read_csv(output, separator="\t")
    assert result["flowA.hexcol"].to_list() == [True, True]


def test_run_writes_report(tmp_path: Path, family_vcf: Path, settings_file: Path) -> None:
    """Exercise settings, VCF, filters, analyses, and report end to end."""
    cytobands = tmp_path / "cyto.txt"
    cytobands.write_text(
        "\n".join(
            f"chr{chrom}\t0\t1000000\tp1\tgneg"
            for chrom in [str(index) for index in range(1, 23)] + ["X"]
        ),
        encoding="utf-8",
    )
    result = runner.invoke(
        app,
        [
            "run",
            "-o",
            str(tmp_path),
            "-c",
            str(cytobands),
            str(settings_file),
            str(family_vcf),
        ],
    )
    assert result.exit_code == 0, result.output
    report = tmp_path / "hopla-output.html"
    assert report.exists()
    html = report.read_text(encoding="utf-8")
    assert "B-allele frequency" in html
    assert "<h4>Variant depth</h4>" in html
    assert "<h4>Number of variants profile</h4>" in html
    assert "<h4>Number of variants table</h4>" in html
    assert "application/gzip+json" in html
    assert "Plotly" in html
    assert not (tmp_path / "hopla-export").exists()


def test_run_export_flags_write_parquet_and_igv(
    tmp_path: Path, family_vcf: Path, settings_file: Path
) -> None:
    """Opt in to Parquet tables and IGV desktop sidecars from the CLI."""
    cytobands = tmp_path / "cyto.txt"
    cytobands.write_text(
        "\n".join(
            f"chr{chrom}\t0\t1000000\tp1\tgneg"
            for chrom in [str(index) for index in range(1, 23)] + ["X"]
        ),
        encoding="utf-8",
    )
    result = runner.invoke(
        app,
        [
            "run",
            "--export-parquet",
            "--export-bigwig",
            "-o",
            str(tmp_path),
            "-c",
            str(cytobands),
            str(settings_file),
            str(family_vcf),
        ],
    )
    assert result.exit_code == 0, result.output
    export_dir = tmp_path / "hopla-export"
    assert (export_dir / "manifest.json").exists()
    assert (export_dir / "baf.parquet").exists()
    assert (export_dir / "igv-session.xml").exists()


def test_run_threads_option_help_and_validation() -> None:
    """Expose -t/--threads and reject a zero thread count as usage."""
    help_result = runner.invoke(app, ["run", "--help"])
    assert help_result.exit_code == 0
    assert "-t" in help_result.stdout
    assert "--threads" in help_result.stdout
    invalid = runner.invoke(app, ["run", "-t", "0", "settings.yaml", "family.vcf"])
    assert invalid.exit_code == 2
