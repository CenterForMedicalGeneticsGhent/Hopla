# Changelog

This changelog covers the Hopla Python package, settings editor, and command-line
subtools, including historical notes from the predecessor R analysis pipeline.

## [Unreleased]

### Added

- Added `sanitize_region` so settings load and the settings editor accept
  copy-pasted intervals such as `17:43,044,295-43,170,327` and store
  `chr17:43044295-43170327`.

### Changed

- Reduced the Galaxy `hopla3` wrapper to one `conditional` that selects `run`
  or `convert`, with each operation's parameters in its own `when` block. The
  compression and index conditionals are gone: one VCF parameter accepts `vcf`
  or `vcf_bgzip`, and the tabix index Galaxy already stores as `vcf_bgzip`
  metadata is staged automatically, so contig-parallel loading no longer
  depends on the user supplying an index dataset.
- Simplified the Galaxy command block to plain Cheetah: no `set -eu`, no shell
  variables, and no command substitution. The report is moved from the job
  working directory and the export archive now contains the
  `{family.id}-export/` directory instead of its bare contents.
- Renamed the `hopla3` outputs `run_report` and `run_exports` to `report` and
  `exports`, and gave each output a single filter expression.
- Turned the Galaxy cytoband parameter into a path with the default
  `/references/Hsapiens/hg38/hopla/cytoBand_hg38.txt`. It is no longer a
  history dataset; clearing the field still downloads the table from UCSC.
- Kept the container environment off the image `PATH`. `/usr/local/bin/hopla`
  activates it for Hopla alone, so `merlin` and `minx` still resolve while a
  bare `python` no longer does.

### Fixed

- Fixed the container entrypoint for job runners that pass a command to
  `docker run`. `ENTRYPOINT ["/app/entrypoint.sh", "bash"]` turned Galaxy's
  `docker run <image> /bin/sh tool_script.sh` into
  `bash /bin/sh tool_script.sh`, so every containerized job died with
  `cannot execute binary file` (exit 126). The image no longer sets an
  entrypoint; `CMD` provides the interactive shell and a passed command runs
  as given.
- Fixed Galaxy's metadata step failing with `ModuleNotFoundError: No module
  named 'sqlalchemy'` when it runs where the Hopla container's `python` is on
  `PATH`. Galaxy's `metadata/set.py` needs Galaxy's own interpreter, so the
  image keeps its environment off `PATH`.
- Fixed `Illegal instruction` on every `hopla` command, including `--help`, on
  hosts without AVX2 such as QEMU guests using the default `qemu64` CPU model.
  `src/hopla/cli.py` imports Polars at module load, and conda-forge's default
  `polars-runtime-32` is compiled with AVX2 while shipping no build feature
  flags, so Polars' own CPU guard is inert and the process dies with SIGILL.
  Depending on `polars-runtime-compat` makes Polars load the baseline runtime,
  which it prefers whenever it is installed.
## [3.0.0] - 2026-08-28

### Added

- Added a typed Python analysis engine at `src/hopla/` with Typer CLI subtools `run`, `convert`, `concordance`, and `transform`.
- Added schema-validated YAML and JSON settings loading through jsonschema and pydantic, including rejection of unknown properties.
- Added columnar VCF loading with cyvcf2 into shared site tables and sample-by-site NumPy matrices.
- Added `hopla run -t` / `--threads` for contig-parallel VCF loading (default:
  all CPUs). Indexed VCFs (tabix or CSI) are read per contig in a process pool;
  a missing index logs a warning and falls back to a single sequential scan.
- Added filter 1 / filter 2 masks, variant statistics, ADO/ADI, BAF, Mendelian errors, parent mapping, and Merlin haplotyping with neighbourhood voting and short-segment correction.
- Added a self-contained offline HTML report that inlines packaged CSS, JS, and
  plotly.js basic, gzip-compresses columnar payloads, and draws SVG panels
  lazily on scroll.
- Added a contents list at the top of the HTML report with links to each
  section.
- Added optional `{family.id}-export/` Parquet tables plus BigWig / BED / SEG / `igv-session.xml` IGV desktop sidecars, enabled with `--export-parquet` and `--export-bigwig`.
- Added `hopla serve`, a loopback-only-by-default Starlette and Jinja settings editor packaged with the Python wheel.
- Added schema-validated YAML preview/download and legacy `.txt`, YAML, and JSON imports with pedigree reconstruction.
- Added browser-driven analysis to `hopla serve`: it runs the current configuration with an uploaded VCF and returns a temporary self-contained HTML report, with a live step log and a `--no-analysis` flag that serves settings editing only.
- Added a settings-editor guard for Merlin's 24-bit pedigree complexity limit.
  **Add sibling** and **Add embryo** refuse the member that would cross it, and
  a modal dialog explains why; the same dialog appears when an import or a newly
  named parent pushes an existing family past the limit.
- Added a Galaxy tool wrapper for `hopla run` and `hopla convert`, including
  optional tabix or CSI indexes for bgzip-compressed VCF input.
- Added `galaxy/.shed.yml` so the wrapper can be published to a Galaxy ToolShed
  and installed from there.
- Added the default and `dev` pixi environments, pytest coverage, and ruff / mypy lint tasks.
- Added the Python user and contributor manual under `docs/`.

### Changed

- `hopla run` writes Parquet and IGV desktop sidecars only when `--export-parquet` or `--export-bigwig` is given.
- Replaced order-aligned pedigree arrays in generated YAML/JSON with structured
  `family.id` and `family.members` objects. Existing parallel-array settings
  are remapped when loaded; the engine also uses member-by-ID lookup directly.
- Renamed legacy `genders` values to member `sex` values during conversion and import.
- `info` is multiline free text rather than a list of lines. The settings editor uses one text box instead of Disease / Inheritance / Sequencing note fields.
- Import, convert, and `hopla run` ignore unsupported keys after a warning instead of failing. Generated YAML omits unused compatibility keys.
- Flattened the repository so the installable Python package lives at the root (`src/hopla/`, `tests/`, `docs/`, `example/`) instead of the `hopla-r/` / `hopla-ui/` monorepo.
- Merged the pixi workspace into `pyproject.toml` (`[tool.pixi…]`) and dropped `pixi.toml`.
- Kept `pixi.lock` free of PyPI source dependencies; it resolves conda packages only.
- Consolidated settings conversion and validation in Python.
- Unified the settings editor and analysis CLI in one Python package and container image.
- Genome-wide BAF and parent-mapping downsampling (`limit_baf_to_p`, `limit_pm_to_p`) uses a deterministic stride rather than random sampling.
- Genotype-count and haplotype-concordance grids are HTML tables rather than Plotly tables.
- Copy-number segmentation uses a deterministic recursive CBS change statistic.
- Installed the local package as an editable pixi path dependency, so
  `pixi install` is enough and the `install-py` / CLI wrapper tasks are gone.
- Locked `default` and `dev` in one solve group. After the shell hook, the
  image replaces the editable path install with a non-editable `pip install`
  so the runtime stage does not need `src/`.
- Replaced verbose variant-total and ADO/ADI report lists with compact,
  horizontally scrollable HTML tables.
- Capped shared variant-depth histogram bins at the pooled 99.5th percentile,
  retaining higher observations in the final bin.
- Moved report CSS and JS into packaged sibling files and inlined plotly.js
  basic instead of the full library, shrinking typical HTML by about 3.7 MB.

### Fixed

- Render male chromosome-X Merlin results as one haplotype strand while
  preserving the absent second strand as `X` in compatibility outputs.
- Segment copy number from covered windows only. A single window without
  coverage produced an infinite ratio that suppressed segmentation and left
  whole chromosomes without a visible segment. Uncovered windows are now
  flagged in the `mask` column.
- Warn when Merlin returns no haplotypes for a chromosome. Merlin silently
  skips chromosomes whose pedigree complexity exceeds its 24-bit limit, so
  large families produced a report with missing haplotype panels and no
  explanation.
- Name newly added siblings and embryos with the next unused sample ID instead
  of the current list length, so removing a middle member no longer reuses an
  existing ID.

### Removed

- Dropped unused settings `color_palette`, `self_contained`, and `cairo` from the schema, engine, and editor.
- Removed the standalone Vue/Vuetify package, Node toolchain, UI CI workflow, nginx image, and `ui-*` container tags. Image tags remain commit SHA, `latest`, package version, and `stable`.

### Notes

- Merlin 1.1.2 remains an external dependency. The engine disables Merlin when `merlin` / `minx` are absent from `$PATH` or only one real sample is analyzed.

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
