"""Typer command-line interface and analysis orchestration."""

from __future__ import annotations

import logging
import sys
import webbrowser
from enum import StrEnum
from pathlib import Path
from threading import Timer
from typing import Annotated

import polars as pl
import typer
import uvicorn

from hopla import __version__
from hopla.convert import convert_settings
from hopla.flow import concordance as compare_flows
from hopla.flow import transform as transform_flow
from hopla.pipeline import run_analysis
from hopla.serve import create_app
from hopla.settings import load_settings

app = typer.Typer(
    no_args_is_help=True,
    add_completion=False,
    pretty_exceptions_enable=False,
    help="Genomic family analysis and interactive reporting.",
)
DEFAULT_OUTPUT_DIRECTORY = Path.cwd()


class LogLevel(StrEnum):
    """Supported command log levels."""

    error = "error"
    warn = "warn"
    info = "info"
    debug = "debug"


def _version(value: bool) -> None:
    """Print the installed version and terminate."""
    if value:
        typer.echo(f"v{__version__}")
        raise typer.Exit()


def _configure_logging(level: str) -> None:
    """Configure deterministic command logging to standard error."""
    aliases = {"warning": "warn", "quiet": "error"}
    normalized = aliases.get(level.lower(), level.lower())
    if normalized not in {item.value for item in LogLevel}:
        raise typer.BadParameter("LEVEL must be error, warn, info, or debug")
    logging.basicConfig(
        level=getattr(logging, "WARNING" if normalized == "warn" else normalized.upper()),
        format="%(asctime)s %(levelname)s %(message)s",
    )


@app.callback()
def callback(
    version: Annotated[
        bool | None,
        typer.Option("-V", "--version", callback=_version, is_eager=True, help="Show version."),
    ] = None,
    log_level: Annotated[
        str,
        typer.Option("-L", "--log-level", envvar="HOPLA_LOG_LEVEL", help="Log verbosity."),
    ] = "info",
) -> None:
    """Configure global Hopla command options."""
    del version
    _configure_logging(log_level)


def _runtime_error(error: Exception) -> None:
    """Print a runtime error and terminate with status one."""
    logging.error("%s", error)
    raise typer.Exit(1) from error


@app.command("run")
def run_command(
    settings_path: Annotated[Path, typer.Argument(exists=True, dir_okay=False, readable=True)],
    vcf_path: Annotated[Path, typer.Argument(exists=True, dir_okay=False, readable=True)],
    out_dir: Annotated[
        Path,
        typer.Option("-o", exists=True, file_okay=False, writable=True, help="Output directory."),
    ] = DEFAULT_OUTPUT_DIRECTORY,
    cytoband_path: Annotated[
        Path | None,
        typer.Option("-c", exists=True, dir_okay=False, readable=True, help="UCSC cytobands."),
    ] = None,
    log_level: Annotated[
        str | None, typer.Option("-L", "--log-level", help="Log verbosity.")
    ] = None,
    export_parquet_data: Annotated[
        bool,
        typer.Option(
            "--export-parquet/--no-export-parquet",
            help="Write portable Parquet tables for visualized data.",
        ),
    ] = True,
    export_bigwig: Annotated[
        bool,
        typer.Option(
            "--export-bigwig/--no-export-bigwig",
            help="Write BigWig, BED, SEG, and an IGV desktop session.",
        ),
    ] = True,
) -> None:
    """Run the complete family analysis and write its report."""
    if log_level is not None:
        _configure_logging(log_level)
    try:
        logging.info("Validating settings")
        settings = load_settings(settings_path)
        report = run_analysis(
            settings,
            vcf_path,
            out_dir,
            cytoband_path=cytoband_path,
            export_parquet_data=export_parquet_data,
            export_bigwig=export_bigwig,
            progress=logging.info,
        )
        typer.echo(report)
    except (OSError, ValueError, RuntimeError, pl.exceptions.PolarsError) as error:
        _runtime_error(error)


@app.command("convert")
def convert_command(
    legacy: Annotated[Path, typer.Argument(exists=True, dir_okay=False, readable=True)],
    output: Annotated[Path | None, typer.Argument()] = None,
) -> None:
    """Convert a legacy settings file to validated YAML."""
    try:
        typer.echo(convert_settings(legacy, output))
    except (OSError, ValueError) as error:
        _runtime_error(error)


@app.command("serve")
def serve_command(
    host: Annotated[str, typer.Option("--host", help="Interface to bind.")] = "127.0.0.1",
    port: Annotated[int, typer.Option("--port", min=1, max=65535, help="Port to bind.")] = 8080,
    open_browser: Annotated[
        bool, typer.Option("--open/--no-open", help="Open the editor in a local browser.")
    ] = True,
    analysis: Annotated[
        bool,
        typer.Option("--analysis/--no-analysis", help="Offer the analysis runner."),
    ] = True,
) -> None:
    """Serve the local Hopla settings editor."""
    url = f"http://{host}:{port}/"
    if open_browser and sys.stdout.isatty() and host in {"127.0.0.1", "localhost", "::1"}:
        Timer(0.5, webbrowser.open, args=(url,)).start()
    logging.info("Serving the settings editor at %s", url)
    if not analysis:
        logging.info("Serving settings only; the analysis runner is disabled")
    uvicorn.run(create_app(analysis=analysis), host=host, port=port, log_level="warning")


@app.command("concordance")
def concordance_command(
    flow1: Annotated[Path, typer.Argument(exists=True, dir_okay=False, readable=True)],
    flow2: Annotated[Path, typer.Argument(exists=True, dir_okay=False, readable=True)],
    relative: Annotated[bool, typer.Option("-r", help="Compare relative to first marker.")] = False,
) -> None:
    """Compare two haplotype flow tables."""
    try:
        values = compare_flows(flow1, flow2, relative=relative)
        first, second = flow1.name.split("-", 1)[0], flow2.name.split("-", 1)[0]
        labels = (
            f"{first}-1 vs {second}-1",
            f"{first}-1 vs {second}-2",
            f"{first}-2 vs {second}-1",
            f"{first}-2 vs {second}-2",
        )
        typer.echo(
            "".join(f"{label}: {value}%\n" for label, value in zip(labels, values, strict=True)),
            nl=False,
        )
    except (OSError, ValueError, pl.exceptions.PolarsError) as error:
        _runtime_error(error)


@app.command("transform")
def transform_command(
    flow1: Annotated[Path, typer.Argument(exists=True, dir_okay=False, readable=True)],
    flow2: Annotated[Path, typer.Argument(exists=True, dir_okay=False, readable=True)],
    mode: Annotated[int, typer.Argument(min=1, max=2)],
    output: Annotated[Path | None, typer.Argument()] = None,
) -> None:
    """Transform a haplotype flow table relative to another."""
    try:
        typer.echo(transform_flow(flow1, flow2, mode, output))
    except (OSError, ValueError, pl.exceptions.PolarsError) as error:
        _runtime_error(error)


def main() -> None:
    """Run the Typer application."""
    app(prog_name="hopla")


if __name__ == "__main__":
    main()
