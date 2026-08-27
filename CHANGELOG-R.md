# R pipeline changelog

This changelog covers the Hopla R package and command-line subtools. Changes to the Vue application under `UI/` are tracked separately.

## [2.0.0] - 2026-08-27

### Added

- Added a reproducible pixi environment and linux-64 lockfile with R 4.4 or newer.
- Added a minimal multi-stage Docker image built from the pixi lockfile.
- Added Roxygen-style parameter and return type information to the R scripts.
- Added a JSON Schema covering every supported analysis setting.
- Added validated YAML and JSON settings-file support.
- Added a standard CRAN source-package layout and testthat coverage.
- Added `run`, `convert`, `concordance`, and `transform` subtools to the `hopla` command.
- Added conversion from the legacy `key=value` settings format to schema-validated YAML.
- Added snake_case linting through lintr, available as the pixi `lint` task and
  enforced in CI.

### Changed

- Reworked haplotype window voting to bound temporary memory to one neighbourhood.
- Reduced repeated VCF, genotype-strand, concordance, and table parsing.
- Aligned helper-script flow tables with keyed `data.table` joins.
- Replaced individual command-line analysis options with one required settings-file argument.
- Replaced the standalone helper scripts with exported package functions.
- Updated the documented R dependency versions.

### Fixed

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
