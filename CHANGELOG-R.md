# R pipeline changelog

This changelog covers `hopla.R`, `concordance.R`, and `transform.R`. Changes to the Vue application under `UI/` are tracked separately.

## [1.1.0] - 2026-08-27

### Added

- Added a reproducible pixi environment and linux-64 lockfile with R 4.4 or newer.
- Added a minimal multi-stage Docker image built from the pixi lockfile.
- Added Roxygen-style parameter and return type information to the R scripts.
- Added generated command-line help and support for `--option=value`.

### Changed

- Reworked haplotype window voting to bound temporary memory to one neighbourhood.
- Reduced repeated VCF, genotype-strand, concordance, and table parsing.
- Aligned helper-script flow tables with keyed `data.table` joins.
- Boolean options can now be enabled without an explicit value.
- Updated the documented R dependency versions.

### Fixed

- User and input errors now return a non-zero process status.
- Help and version output no longer load the analysis package stack.
- DNAcopy output suppression no longer leaves an open sink after an error.
- Large report objects are released before self-contained HTML conversion.

### Removed

- Removed the Pandoc requirement by inlining local HTML dependencies in R.
- Removed the direct knitr dependency.

## [1.0.6]

Previous R pipeline release.
