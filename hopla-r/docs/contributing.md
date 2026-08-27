# Contributing

These instructions apply to the R package under `hopla-r/`. Work under
`hopla-ui/` is out of scope unless a task explicitly names it. Never merge a
pull request unless the user explicitly requests it.

Agents should also read the autodiscovered [AGENTS.md](../../AGENTS.md) at the
repository root. That file is the parallel copy of these rules; keep them in
sync.

## Runtime and dependencies

- Use the root `hopla-r` / `hopla-r-dev` pixi environments and committed
  `pixi.lock`.
- Keep `linux-64`, `linux-aarch64`, and `osx-arm64` supported. Merlin 1.1.2 is
  available on each of those platforms.
- Require R 4.4 or newer.
- Add R dependencies to both the root `pixi.toml` and `hopla-r/DESCRIPTION`;
  regenerate the root `pixi.lock` with pixi.
- Do not install CRAN packages outside pixi.
- Hopla must not invoke Pandoc. Self-contained HTML is produced by the internal asset inliner.

Details: [install.md](install.md).

## Package structure

- Maintain a CRAN-compatible R package (`DESCRIPTION`, `NAMESPACE`, `R/`, `man/`, `tests/`, and `inst/`).
- Public R functions require Roxygen-style source comments and matching Rd documentation.
- The installed analysis engine lives under `exec/`; the schema lives under `inst/schema/`.
- Keep `exec/hopla-run.R` as the orchestration entry point. Put private engine
  functions in the ordered `inst/engine/` modules documented in
  [architecture.md](architecture.md).
- CRAN does not install nested `exec/` directories; `inst/engine/` is installed
  as `engine/`. Do not source those modules from `R/`, add their functions to
  `NAMESPACE`, or expose them as package APIs. Preserve module load order and
  verify the files survive `R CMD build` and `R CMD INSTALL`.
- Keep the package version, CLI version, pixi version, and R changelog release in sync. CLI-breaking changes require a major version bump.
- Record R pipeline changes in [`CHANGELOG-R.md`](../CHANGELOG-R.md).
- Keep this manual in `docs/` in sync with the schema, engine defaults, and CLI.

## Settings and command line

- Analysis configuration is accepted only as YAML or JSON.
- Encode every supported setting, type, default, and basic constraint in `inst/schema/hopla.schema.json`.
- Keep [settings.md](settings.md) aligned with that schema and with engine defaults.
- Validate settings against the schema before loading a VCF or the heavy analysis packages. Reject unknown properties.
- Keep the CLI as documented in [cli.md](cli.md).
- `vcf_file`, `out_dir`, and `cytoband_file` are CLI paths, not settings properties. Validate that supplied paths exist. `OUT_DIR` defaults to the current working directory; an omitted cytoband table is downloaded from UCSC.
- `convert` maps the legacy `key=value` settings format to schema-validated YAML.
- Return zero for help, version, and successful commands; return status 2 for invalid usage and status 1 for runtime failures.
- Global options are `-h`, `-V` (not `-v`), and `-L LEVEL` (`error`, `warn`, `info`, `debug`; default `info`). Use `--` to terminate option parsing. Options must precede operands. `concordance` accepts `-r` for relative comparison. `run` also accepts `-L` before its operands.

## Performance and output

- Avoid growing R objects with repeated `rbind()` in loops.
- Avoid retaining whole-genome intermediate copies or per-marker neighbour lists when bounded-memory processing is possible.
- Use keyed joins for flow-table alignment.
- Preserve report contents and calculations when optimizing code.

## Containers

- Build `hopla-r/Dockerfile` from the repository-root context and `pixi.lock`.
- Do not copy `hopla-ui/` into the R image.
- Do not ship the pixi binary or the unused Pandoc executable in the runtime stage.

## Verification

- Run `pixi install --locked`.
- Run `pixi run -e hopla-r-dev lint`; CI lint failures must be fixed, not
  suppressed globally.
- Run package tests and `R CMD check --no-manual`.
- Test YAML and JSON validation, including rejection of unknown or mistyped settings.
- Test all CLI subtools and their failure exit statuses.
- Confirm no task-scoped changes appear under `hopla-ui/` unless the task named
  that tree.
- Build the R Docker image when Docker is available.

## Continuous integration and releases

- Build and check the R package and build its Docker image in the R-only
  workflow for every relevant pull request targeting `main`.
- On pushes to `main` or `master`, tag the image with the full commit SHA and `latest`.
- On a published release, tag the image with the full commit SHA, package version, and `stable`.
- Attach the R source package and compressed Docker image to the GitHub release.
