# Changelog

This changelog covers the Hopla Python package. Releases 2.0.0 and 1.0.6
document the predecessor R analysis pipeline.

## [Unreleased]


## [3.0.0] - 2026-08-28

Hopla 3.0.0 is a complete rewrite of 2.0.0. The R package (`hopla-r`) and Vue
settings editor (`hopla-ui`) are replaced by one installable Python package at
the repository root.

The command line still exposes `run`, `convert`, `concordance`, and `transform`
with the same status conventions (`0` success, `2` usage, `1` runtime).
Analysis still takes a settings file and a VCF, still calls Merlin 1.1.2 for
haplotyping when the pedigree allows it, and still writes a self-contained HTML
report. The engine, editor, packaging, and container are new.

### Added

- Typed Python engine under `src/hopla/`, with pixi `default` / `dev`
  environments, pytest, ruff, and mypy.
- `hopla serve`, a packaged Starlette settings editor: YAML/JSON/legacy import,
  validated YAML preview and download, a Merlin 24-bit family-size guard, and
  optional in-browser analysis (`--no-analysis` serves settings only).
- `hopla run -t` / `--threads` for contig-parallel VCF loading (default: all
  CPUs). A missing tabix index on a bgzip VCF is written when possible.
- Optional `{family.id}-export/` Parquet tables and IGV desktop sidecars
  (`--export-parquet`, `--export-bigwig`).
- Galaxy wrapper for `hopla run` and `hopla convert`, with ToolShed metadata in
  `galaxy/.shed.yml`.
- Python user and contributor manual under `docs/`.

### Changed

Relative to 2.0.0 settings and CLI:

- Pedigree is a structured `family.id` / `family.members` object with
  member-by-ID parents and `sex`. Parallel-array files and `genders` still load
  through remap and `hopla convert`.
- `info` is one multiline string instead of a list of disease / inheritance /
  sequencing lines.
- Unsupported keys warn and are ignored; generated YAML omits unused
  compatibility keys.
- Copy-pasted intervals such as `17:43,044,295-43,170,327` are stored as
  `chr17:43044295-43170327`.
- An explicit `window_size_voting_x` of `0` is kept rather than replaced by the
  autosome window.

Relative to the 2.0.0 R report:

- BAF and parent-mapping downsampling (`limit_baf_to_p`, `limit_pm_to_p`) uses
  a deterministic stride, not random sampling.
- Genotype-count and haplotype-concordance grids are HTML tables.
- Copy-number panels share a −5 to +5 y-axis; `|log2(ratio)| > 5` is drawn on
  the boundary and shown on hover.
- Variant-depth histograms share bins capped at the pooled 99.5th percentile.
- Copy-number segmentation is a deterministic recursive CBS statistic, not
  DNAcopy with resampling.
- The report inlines packaged CSS, JS, and plotly.js basic (not the full
  library) and draws SVG panels lazily on scroll.

### Removed

- The R analysis engine, Vue/Vuetify editor, Node toolchain, UI container tags,
  and unused settings `color_palette`, `self_contained`, and `cairo`.

### Notes

- Merlin 1.1.2 remains an external binary. Haplotyping is skipped when `merlin`
  or `minx` is missing from `PATH`, or when only one real sample is analyzed.
- The container keeps the pixi environment off `PATH` and runs Hopla through
  `/usr/local/bin/hopla`, so Galaxy metadata and a bare `python` do not use the
  image interpreter.
- Polars uses the compat runtime so hosts without AVX2 (including default QEMU
  `qemu64` guests) do not die with `Illegal instruction`.

## [2.0.0] - 2026-08-27

### Added

- Added a reproducible pixi environment and lockfile for `linux-64`, `linux-aarch64`, and `osx-arm64` with R 4.4 or newer.
- Added a minimal multi-stage Docker image built from the pixi lockfile.
- Added Roxygen-style parameter and return type information to the R scripts.
- Added a JSON Schema covering every supported analysis setting.
- Added validated YAML and JSON settings-file support.
- Added a standard CRAN source-package layout and testthat coverage.
- Added `run`, `convert`, `concordance`, and `transform` subtools to the `hopla` command.
- Added conversion from the legacy `key=value` settings format to schema-validated YAML.
- Added Matthias De Smet as author and package maintainer (`cre`), and Center for Medical Genetics Ghent as copyright holder and funder. R allows only one `cre` entry, so the institutional contact is documented in `docs/`.
- Added snake_case linting through lintr, available as the pixi `lint` task and enforced in CI.
- When `cytoband_file` is omitted, download and decompress the UCSC hg38 `cytoBand.txt.gz` table.
- Added timestamped `error` / `warn` / `info` / `debug` logging, selected with `-L` / `--log-level` or `HOPLA_LOG_LEVEL`.
- Compiled the former scattered markdown into the package docs manual (install, CLI, settings, output, contributing).

### Changed

- Moved the CRAN-compatible package into `hopla-r/` as part of a monorepo with the separate `hopla-ui/` package and shared root pixi workspace.
- Split the analysis engine into ordered private modules under `inst/engine/`; `hopla-run.R` now contains only module loading and pipeline orchestration.
- Switched the report text, plots, and tables to a modern sans-serif system font stack; no web font is downloaded or embedded.
- Binned every variant-depth histogram on shared breaks and pinned both axis ranges, so the panels are comparable.
- Widened the row spacing of the BAF panel grids so a chromosome or sample label stays with its own panel.
- Reworked haplotype window voting to bound temporary memory to one neighbourhood.
- Reduced repeated VCF, genotype-strand, concordance, and table parsing.
- Pre-binned variant-depth histograms and compressed embedded Plotly data to reduce self-contained HTML report size.
- Aligned helper-script flow tables with keyed `data.table` joins.
- Replaced individual command-line analysis options with one required settings-file argument.
- Moved `vcf_file`, `out_dir`, and `cytoband_file` from the settings file to `hopla run` (`[-o OUT_DIR] [-c CYTOBAND] SETTINGS VCF`). Supplied paths must exist; `OUT_DIR` defaults to the current working directory and an omitted cytoband table is downloaded from UCSC.
- Replaced the standalone helper scripts with exported package functions.
- Updated the documented R dependency versions.

### Fixed

- Region markers no longer fail with an `add_trace()` argument error; the local helper renamed during the snake_case migration shadowed `plotly::add_trace`.
- Copy-number segmentation again uses the DNAcopy API spelling: the `data.type` argument of `CNA()` and the `loc.start`, `loc.end`, and `seg.mean` output columns were wrongly snake_cased.
- The installed `hopla` and `hopla-run.R` scripts now load their logging helpers from the package namespace instead of the source `R/` directory, which is absent from an installed tree.
- Renamed the remaining engine helpers that shadowed package functions (`trim` and a local `parse`) to `trim_whitespace` and `parse_chromosome_tables`.
- Chromosome and sample labels are drawn under their own panel again. A title standoff on axes with hidden tick labels left every label stacked at the top of the figure.
- User and input errors now return a non-zero process status.
- Help and version output no longer load the analysis package stack.
- DNAcopy output suppression no longer leaves an open sink after an error.
- Large report objects are released before self-contained HTML conversion.

### Removed

- Removed the Pandoc requirement by inlining local HTML dependencies in R.
- Removed the direct knitr dependency.
- Removed the legacy key/value settings format and root-level R scripts.

## [1.0.6]

Previous R pipeline release.
