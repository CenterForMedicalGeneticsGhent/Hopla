# Hopla contributor instructions

This file is the agent-discoverable copy of the contributor rules. The same
material lives in [docs/contributing.md](docs/contributing.md) for the human
manual. Keep the two in sync.

Work under `UI/` is out of scope unless a task explicitly names it. Never merge
a pull request unless the user explicitly requests it.

The rest of the manual is [docs/README.md](docs/README.md).

## Runtime and dependencies

- Use the root pixi environment and committed `pixi.lock`.
- Keep `linux-64`, `linux-aarch64`, and `osx-arm64` supported. Merlin 1.1.2 is
  available on each of those platforms.
- Require R 4.4 or newer.
- Add R dependencies to both `pixi.toml` and `DESCRIPTION`; regenerate
  `pixi.lock` with pixi.
- Do not install CRAN packages outside pixi.
- Hopla must not invoke Pandoc. Self-contained HTML is produced by the internal
  asset inliner.

## Package structure

- Maintain a CRAN-compatible R package (`DESCRIPTION`, `NAMESPACE`, `R/`,
  `man/`, `tests/`, and `inst/`).
- Public R functions require Roxygen-style source comments and matching Rd
  documentation.
- The installed analysis engine lives under `exec/`; the schema lives under
  `inst/schema/`.
- Keep the package version, CLI version, pixi version, and R changelog release
  in sync. CLI-breaking changes require a major version bump.
- Record R pipeline changes in `CHANGELOG-R.md`.
- Keep the manual in `docs/` in sync with the schema, engine defaults, and CLI.

## Settings and command line

- Analysis configuration is accepted only as YAML or JSON.
- Encode every supported setting, type, default, and basic constraint in
  `inst/schema/hopla.schema.json`.
- Keep `docs/settings.md` aligned with that schema and with engine defaults.
- Validate settings against the schema before loading a VCF or the heavy
  analysis packages. Reject unknown properties.
- Keep the CLI small:
  - `hopla [-L LEVEL] run [-o OUT_DIR] SETTINGS VCF`
  - `hopla convert LEGACY [OUTPUT]`
  - `hopla concordance FLOW1 FLOW2 [-r]`
  - `hopla transform FLOW1 FLOW2 MODE [OUTPUT]`
- `vcf_file` and `out_dir` are CLI paths, not settings properties. Validate that
  the VCF file and output directory exist. `OUT_DIR` defaults to the current
  working directory.
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

- Build the root Docker image from `pixi.lock` using a multi-stage Dockerfile.
- Do not copy `UI/` into the R image.
- Do not ship the pixi binary or the unused Pandoc executable in the runtime
  stage.

## Verification

- Run `pixi install --locked`.
- Run `pixi run -e dev lint`; CI lint failures must be fixed, not suppressed
  globally.
- Run package tests and `R CMD check --no-manual`.
- Test YAML and JSON validation, including rejection of unknown or mistyped
  settings.
- Test all CLI subtools and their failure exit statuses.
- Confirm no task-scoped changes appear under `UI/` unless the task named that
  tree.
- Build the root Docker image when Docker is available.

## Continuous integration and releases

- Build and check the R package and build the root Docker image for every pull
  request targeting `main`.
- On pushes to `main` or `master`, tag the image with the full commit SHA and
  `latest`.
- On a published release, tag the image with the full commit SHA, package
  version, and `stable`.
- Attach the R source package and compressed Docker image to the GitHub release.
