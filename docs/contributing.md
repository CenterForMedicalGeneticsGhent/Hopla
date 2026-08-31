# Contributing

These instructions apply to the Hopla Python package at the repository root.
Never merge a pull request unless the user explicitly requests it.

An agent-discoverable copy of this material lives in
[`AGENTS.md`](../AGENTS.md). Keep the two files in sync.

## Runtime and dependencies

- Use the root pixi environments (`default` and `dev`) and the committed
  `pixi.lock`.
- Keep `linux-64`, `linux-aarch64`, and `osx-arm64` supported. The
  `vendor/abecasis-lab-merlin` git submodule supplies the editable `merlinpy`
  dependency in each environment.
- Require Python 3.12 or newer.
- Add Python dependencies to both `[project]` / `[project.optional-dependencies]`
  and the matching pixi conda or PyPI dependency section in `pyproject.toml`;
  regenerate `pixi.lock` with pixi. Conda entries override the same-named PyPI
  requirements from `[project]`. Keep the bioconda `conda-pypi-map` entry for
  `pybigwig` so osx-arm64 does not pull a PyPI source build.
- Keep `pixi.lock` free of third-party PyPI source dependencies except for the
  editable `merlinpy` submodule path. The local Hopla package is the other
  editable `[tool.pixi.pypi-dependencies]` path entry.
- Prefer the pixi editable path install over unmanaged global pip installs.
- Hopla must not invoke Pandoc. The report always inlines the offline
  `plotly.js` bundle and compresses the columnar payload itself.

Details: [install.md](install.md).

## Package structure

- Maintain an installable Python package at the repository root
  (`pyproject.toml`, `src/hopla/`, `tests/`, and `docs/`).
- Public modules and functions should remain typed and documented.
- Keep the Typer entry point in `src/hopla/cli.py` as the orchestration surface
  for `run`, `serve`, `convert`, `concordance`, and `transform`.
- Keep the lightweight settings editor under `src/hopla/ui/` and its Starlette
  application in `src/hopla/serve.py`. Package all templates and static assets.
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
- Do not overwrite [exports.md](exports.md) when updating architecture notes.

## Settings and command line

- Analysis configuration is accepted only as YAML or JSON.
- Encode every supported setting, type, default, and basic constraint in
  `src/hopla/schema/hopla.schema.json`.
- Keep [settings.md](settings.md) aligned with that schema and with engine
  defaults.
- Validate settings against the schema before loading a VCF. Ignore
  unsupported properties after a warning. Reject mistyped values. Generated
  YAML must not include unused compatibility keys.
- Keep the CLI as documented in [cli.md](cli.md):
  - `hopla [-L LEVEL] run [-o OUT_DIR] [-c CYTOBAND] SETTINGS VCF`
  - `hopla convert LEGACY [OUTPUT]`
  - `hopla concordance FLOW1 FLOW2 [-r]`
  - `hopla transform FLOW1 FLOW2 MODE [OUTPUT]`
  - `hopla serve [--host HOST] [--port PORT] [--no-open] [--no-analysis]`
- `vcf_file`, `out_dir`, and `cytoband_file` are CLI paths, not settings
  properties. Validate that supplied paths exist. `OUT_DIR` defaults to the
  current working directory; an omitted cytoband table is downloaded from UCSC.
- `run` writes `{family.id}-export/` Parquet and IGV sidecars only when
  `--export-parquet` / `--export-bigwig` are given.
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

- Build `Dockerfile` from the repository-root context and `pixi.lock`, including
  the `vendor/abecasis-lab-merlin` submodule.
- Resolve every third-party dependency through `pixi install --locked`; after
  the shell hook, the image uninstalls the editable path packages and overlays
  non-editable `pip install --no-deps` installs of `merlinpy` and Hopla so the
  runtime stage does not need `src/` or the submodule tree.
- Do not ship the pixi binary in the runtime stage.

## Verification

- Run `pixi install --locked`.
- Run `pixi run -e dev lint-py`; CI lint and type-check failures must be
  fixed, not suppressed globally.
- Run `pixi run -e dev test-py`.
- Test YAML and JSON validation, including warnings for unsupported keys and
  rejection of mistyped settings.
- Test all CLI subtools and their failure exit statuses, including the export
  toggles.
- Build a wheel when verifying packaging:
  `pixi run -e dev python -m pip wheel --no-deps . -w dist`.
- Build the Docker image when Docker is available.

## Continuous integration and releases

- Build and check the Python package and its image for relevant pull requests
  targeting `main`.
- On pushes to `main` or `master`, tag the image with the full commit SHA and
  `latest`.
- On a published release, tag the image with the full commit SHA, package
  version, and `stable`.
- Do not publish `ui-*` tags.
- Upload the built Python wheel and compressed Docker image artifacts from CI.
- Attach the Python wheel and compressed Docker image to the GitHub release.
