# Hopla contributor instructions

This file is the agent-discoverable copy of the contributor rules. The same
material lives in
[hopla-r/docs/contributing.md](hopla-r/docs/contributing.md) for the human
manual. Keep the two in sync.

The monorepo contains the R package under `hopla-r/` and the Vue application
under `hopla-ui/`. Keep changes scoped to the package named by the task. Never
merge a pull request unless the user explicitly requests it.

The package manuals are [hopla-r/docs/README.md](hopla-r/docs/README.md) and
[hopla-ui/docs/README.md](hopla-ui/docs/README.md).

## Runtime and dependencies

- Use the named root pixi environment for the package and the committed
  `pixi.lock`.
- Keep `linux-64`, `linux-aarch64`, and `osx-arm64` supported. Merlin 1.1.2 is
  available on each of those platforms.
- Require R 4.4 or newer.
- Add R dependencies to both `pixi.toml` and `hopla-r/DESCRIPTION`; regenerate
  `pixi.lock` with pixi.
- Do not install CRAN packages outside pixi.
- Hopla must not invoke Pandoc. Self-contained HTML is produced by the internal
  asset inliner.

## Package structure

- Maintain a CRAN-compatible R package under `hopla-r/` (`DESCRIPTION`,
  `NAMESPACE`, `R/`, `man/`, `tests/`, and `inst/`).
- Public R functions require Roxygen-style source comments and matching Rd
  documentation.
- The installed analysis engine lives under `exec/`; the schema lives under
  `inst/schema/`.
- Keep `exec/hopla-run.R` as the orchestration entry point. Private engine
  functions belong in the ordered `inst/engine/` modules:
  - `00-input.R` — settings, inputs, cytobands, and filters
  - `10-merlin.R` — Merlin execution, parsing, and correction
  - `20-plot-helpers.R` — shared visualization helpers
  - `30-haplotype-plots.R` — haplotype profiles and tables
  - `40-analysis-plots.R` — analysis-specific plots
  - `50-report.R` — report assembly and self-contained HTML serialization
- Files in `inst/engine/` are private executable modules. CRAN installs them as
  `engine/` because nested `exec/` directories are not installed. Do not source
  them from `R/`, add them to `NAMESPACE`, or expose them as package APIs.
  Preserve their numeric load order and verify they survive `R CMD build` and
  `R CMD INSTALL`.
- Keep
  [hopla-r/docs/architecture.md](hopla-r/docs/architecture.md)
  aligned with this structure.
- Keep the package version, CLI version, pixi version, and R changelog release
  in sync. CLI-breaking changes require a major version bump.
- Record R pipeline changes in `hopla-r/CHANGELOG-R.md`.
- Keep the manual in `hopla-r/docs/` in sync with the schema, engine defaults,
  and CLI.

## Settings and command line

- Analysis configuration is accepted only as YAML or JSON.
- Encode every supported setting, type, default, and basic constraint in
  `inst/schema/hopla.schema.json`.
- Keep `hopla-r/docs/settings.md` aligned with that schema and with engine
  defaults.
- Validate settings against the schema before loading a VCF or the heavy
  analysis packages. Reject unknown properties.
- Keep the CLI small:
  - `hopla [-L LEVEL] run [-o OUT_DIR] [-c CYTOBAND] SETTINGS VCF`
  - `hopla convert LEGACY [OUTPUT]`
  - `hopla concordance FLOW1 FLOW2 [-r]`
  - `hopla transform FLOW1 FLOW2 MODE [OUTPUT]`
- `vcf_file`, `out_dir`, and `cytoband_file` are CLI paths, not settings
  properties. Validate that supplied paths exist. `OUT_DIR` defaults to the
  current working directory; an omitted cytoband table is downloaded from UCSC.
- `convert` maps the legacy `key=value` settings format to schema-validated YAML.
- Return zero for help, version, and successful commands; return status 2 for
  invalid usage and status 1 for runtime failures.
- Global options are `-h`, `-V` (not `-v`), and `-L LEVEL` (`error`, `warn`,
  `info`, `debug`; default `info`). Use `--` to terminate option parsing.
  Options must precede operands. `concordance` accepts `-r` for relative
  comparison. `run` also accepts `-L` before its operands.

## Performance and output

- Avoid growing R objects with repeated `rbind()` in loops.
- Avoid retaining whole-genome intermediate copies or per-marker neighbour
  lists when bounded-memory processing is possible.
- Use keyed joins for flow-table alignment.
- Preserve report contents and calculations when optimizing code.

## Containers

- Build `hopla-r/Dockerfile` from the repository-root context and `pixi.lock`.
- Do not copy `hopla-ui/` into the R image.
- Do not ship the pixi binary or the unused Pandoc executable in the runtime
  stage.

## Verification

- Run `pixi install --locked`.
- Run `pixi run -e hopla-r-dev lint`; CI lint failures must be fixed, not
  suppressed globally.
- Run package tests and `R CMD check --no-manual`.
- Test YAML and JSON validation, including rejection of unknown or mistyped
  settings.
- Test all CLI subtools and their failure exit statuses.
- Confirm no task-scoped changes appear under the other package unless the task
  named that tree.
- Build the relevant package Docker image when Docker is available.

## Continuous integration and releases

- Keep R and UI CI in separate workflows. Build and check each package and its
  image for relevant pull requests targeting `main`.
- On pushes to `main` or `master`, tag the image with the full commit SHA and
  `latest` for R or `ui-latest` for UI.
- On a published release, tag R with the full commit SHA, package version, and
  `stable`; prefix every equivalent UI tag with `ui-`.
- Attach the R source package and compressed Docker image to the GitHub release.
