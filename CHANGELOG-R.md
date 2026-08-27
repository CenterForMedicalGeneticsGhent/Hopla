# R pipeline changelog

This changelog covers the Hopla R package and command-line subtools. Changes to the Vue application under `UI/` are tracked separately.

## [2.0.0] - 2026-08-27

### Added

- Added a reproducible pixi environment and lockfile for `linux-64`,
  `linux-aarch64`, and `osx-arm64` with R 4.4 or newer.
- Added a minimal multi-stage Docker image built from the pixi lockfile.
- Added Roxygen-style parameter and return type information to the R scripts.
- Added a JSON Schema covering every supported analysis setting.
- Added validated YAML and JSON settings-file support.
- Added a standard CRAN source-package layout and testthat coverage.
- Added `run`, `convert`, `concordance`, and `transform` subtools to the `hopla` command.
- Added conversion from the legacy `key=value` settings format to schema-validated YAML.
- Added Matthias De Smet as author and package maintainer (`cre`), and Center
  for Medical Genetics Ghent as copyright holder and funder. R allows only one
  `cre` entry, so the institutional contact is documented in `docs/`.
- Added snake_case linting through lintr, available as the pixi `lint` task and
  enforced in CI.
- When `cytoband_file` is omitted, download and decompress the UCSC hg38
  `cytoBand.txt.gz` table.
- Added timestamped `error` / `warn` / `info` / `debug` logging, selected with
  `-L` / `--log-level` or `HOPLA_LOG_LEVEL`.
- Compiled the former scattered markdown into the [docs/](docs/README.md)
  manual (install, CLI, settings, output, UI, contributing).

### Changed

- Split the analysis engine into ordered private modules under `exec/lib/`;
  `hopla-run.R` now contains only module loading and pipeline orchestration.
- Switched the report text, plots, and tables to a modern sans-serif system
  font stack; no web font is downloaded or embedded.
- Binned every variant-depth histogram on shared breaks and pinned both axis
  ranges, so the panels are comparable.
- Widened the row spacing of the BAF panel grids so a chromosome or sample
  label stays with its own panel.
- Reworked haplotype window voting to bound temporary memory to one neighbourhood.
- Reduced repeated VCF, genotype-strand, concordance, and table parsing.
- Pre-binned variant-depth histograms and compressed embedded Plotly data to
  reduce self-contained HTML report size.
- Aligned helper-script flow tables with keyed `data.table` joins.
- Replaced individual command-line analysis options with one required settings-file argument.
- Moved `vcf_file`, `out_dir`, and `cytoband_file` from the settings file to
  `hopla run` (`[-o OUT_DIR] [-c CYTOBAND] SETTINGS VCF`). Supplied paths must
  exist; `OUT_DIR` defaults to the current working directory and an omitted
  cytoband table is downloaded from UCSC.
- Replaced the standalone helper scripts with exported package functions.
- Updated the documented R dependency versions.

### Fixed

- Region markers no longer fail with an `add_trace()` argument error; the local
  helper renamed during the snake_case migration shadowed `plotly::add_trace`.
- Copy-number segmentation again uses the DNAcopy API spelling: the
  `data.type` argument of `CNA()` and the `loc.start`, `loc.end`, and
  `seg.mean` output columns were wrongly snake_cased.
- The installed `hopla` and `hopla-run.R` scripts now load their logging
  helpers from the package namespace instead of the source `R/` directory,
  which is absent from an installed tree.
- Renamed the remaining engine helpers that shadowed package functions
  (`trim` and a local `parse`) to `trim_whitespace` and
  `parse_chromosome_tables`.
- Chromosome and sample labels are drawn under their own panel again. A title
  standoff on axes with hidden tick labels left every label stacked at the top
  of the figure.
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
