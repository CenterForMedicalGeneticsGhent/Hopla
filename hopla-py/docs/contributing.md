# Contributing

These instructions apply to the Python package under `hopla-py/`. Work under
`hopla-ui/` is out of scope unless a task explicitly names it. Never merge a
pull request unless the user explicitly requests it.

An agent-discoverable copy of this material lives in the repository-root
[`AGENTS.md`](../../AGENTS.md). Keep the two files in sync.

## Runtime and dependencies

- Use the root `hopla-py` / `hopla-py-dev` pixi environments and committed
  `pixi.lock`.
- Keep `linux-64`, `linux-aarch64`, and `osx-arm64` supported. Merlin 1.1.2 is
  available on each of those platforms in the `hopla-py` feature.
- Require Python 3.12 or newer.
- Add Python dependencies to both the root `pixi.toml` `hopla-py` feature and
  `hopla-py/pyproject.toml`; regenerate the root `pixi.lock` with pixi.
- Prefer editable installs through `pixi run -e hopla-py install-py` rather than
  unmanaged global pip installs.
- Hopla must not invoke Pandoc. The report always inlines the offline
  `plotly.js` bundle and compresses the columnar payload itself.

Details: [install.md](install.md).

## Package structure

- Maintain an installable Python package under `hopla-py/` (`pyproject.toml`,
  `src/hopla/`, `tests/`, and `docs/`).
- Public modules and functions should remain typed and documented.
- Keep the Typer entry point in `src/hopla/cli.py` as the orchestration surface
  for `run`, `convert`, `concordance`, and `transform`.
- Put private analysis helpers in the narrowest relevant module documented in
  [architecture.md](architecture.md).
- Keep portable Parquet and IGV exporters under `src/hopla/export/`.
- Keep the settings schema in `src/hopla/schema/hopla.schema.json` (packaged as
  `hopla/schema/hopla.schema.json`). There is no runtime fallback to another
  package tree.
- Keep [architecture.md](architecture.md) aligned with this structure.
- Keep the package version, CLI version, pixi version, and
  [CHANGELOG.md](../CHANGELOG.md) release entry in sync. CLI-breaking changes
  require a major version bump.
- Record Python pipeline changes in [CHANGELOG.md](../CHANGELOG.md).
- Keep this manual in `docs/` in sync with the schema, engine defaults, and
  CLI. Keep [`example/`](../example/) fixtures aligned with documented
  settings and convert behaviour.
- Do not overwrite [exports.md](exports.md) or
  [igvjs-evaluation.md](igvjs-evaluation.md) when updating architecture notes.

## Settings and command line

- Analysis configuration is accepted only as YAML or JSON.
- Encode every supported setting, type, default, and basic constraint in
  `src/hopla/schema/hopla.schema.json`.
- Keep [settings.md](settings.md) aligned with that schema and with engine
  defaults. Document intentional schema-compatibility settings that the Python
  engine ignores or always overrides (`color_palette`, `self_contained`,
  `cairo`).
- Validate settings against the schema before loading a VCF. Reject unknown
  properties.
- Keep the CLI as documented in [cli.md](cli.md):
  - `hopla [-L LEVEL] run [-o OUT_DIR] [-c CYTOBAND] SETTINGS VCF`
  - `hopla convert LEGACY [OUTPUT]`
  - `hopla concordance FLOW1 FLOW2 [-r]`
  - `hopla transform FLOW1 FLOW2 MODE [OUTPUT]`
- `vcf_file`, `out_dir`, and `cytoband_file` are CLI paths, not settings
  properties. Validate that supplied paths exist. `OUT_DIR` defaults to the
  current working directory; an omitted cytoband table is downloaded from UCSC.
- Default `run` also writes `{fam_id}-export/` Parquet and IGV sidecars unless
  disabled with `--no-export-parquet` / `--no-export-bigwig`.
- `convert` maps the legacy `key=value` settings format to schema-validated
  YAML.
- Return zero for help, version, and successful commands; return status 2 for
  invalid usage and status 1 for runtime failures.
- Global options are `-h`, `-V` (not `-v`), and `-L LEVEL` (`error`, `warn`,
  `info`, `debug`; default `info`). Use `--` to terminate option parsing.
  Options must precede operands. `concordance` accepts `-r` for relative
  comparison. `run` also accepts `-L` before its operands.

## Performance and output

- Prefer columnar NumPy / Polars operations over growing tables row by row.
- Avoid retaining whole-genome intermediate copies or per-marker neighbour
  lists when bounded-memory processing is possible.
- Use keyed joins for flow-table alignment.
- Preserve report contents and calculations when optimizing code.
- Keep the report payload columnar and compressed; draw figures lazily in the
  browser.

## Containers

- Build `hopla-py/Dockerfile` from the repository-root context and `pixi.lock`.
- Do not copy `hopla-ui/` into the Python image.
- Do not ship the pixi binary in the runtime stage.

## Verification

- Run `pixi install --locked`.
- Run `pixi run -e hopla-py-dev lint-py`; CI lint and type-check failures must
  be fixed, not suppressed globally.
- Run `pixi run -e hopla-py-dev test-py`.
- Test YAML and JSON validation, including rejection of unknown or mistyped
  settings.
- Test all CLI subtools and their failure exit statuses, including the export
  toggles.
- Confirm no task-scoped changes appear under `hopla-ui/` unless the task named
  that tree.
- Build a wheel when verifying packaging:
  `pixi run -e hopla-py-dev python -m pip wheel --no-deps ./hopla-py -w dist`.
- Build the relevant package Docker image when Docker is available.

## Continuous integration and releases

- Keep Python and UI CI in separate workflows. Build and check each package and
  its image for relevant pull requests targeting `main`.
- On pushes to `main` or `master`, tag the Python image with the full commit SHA
  and `latest`; tag the UI image with `ui-<commit-sha>` and `ui-latest`.
- On a published release, tag the Python image with the full commit SHA, package
  version, and `stable`; prefix every equivalent UI tag with `ui-`.
- Upload the built Python wheel and compressed Docker image artifacts from CI.
- Attach the Python wheel and compressed Docker image to the GitHub release.
