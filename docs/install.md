# Install and dependencies

Hopla requires Python 3.12 or newer (and below 3.14 in the locked pixi
environment).

## Pixi (Linux and macOS)

The repository includes a locked [pixi](https://pixi.sh) environment for
`linux-64`, `linux-aarch64`, and `osx-arm64`. Merlin 1.1.2 is included on each
of those platforms in the default environment.

```bash
pixi install --locked
pixi run hopla --help
```

Use `pixi install --locked` so the committed `pixi.lock` is respected. Third-party
lock entries are conda packages; the local package is the editable pixi path
dependency, so `pixi install` puts `hopla` on the environment `PATH`.

The default environment holds analysis dependencies and Merlin. The `dev`
environment adds pytest, ruff, mypy, and typing stubs. Both include the
editable local package through the `local` feature. The `prod` environment
holds the same conda dependencies without that pypi entry; the container image
installs it into `/usr/local` and adds `hopla` with pip.

Pixi tasks (from the repository root):

- `dev` environment `lint-py` — `ruff check` and `mypy`
- `dev` environment `test-py` — `pytest tests`

After install, `pixi run hopla` invokes the console script (for example
`pixi run hopla convert` or `pixi run hopla serve`).

## Pip (development tree)

From the repository root, with a Python 3.12+ environment that already provides
Merlin on `$PATH` when haplotyping is needed:

```bash
python -m pip install -e '.[dev]'
hopla --help
```

Runtime dependencies are declared in `pyproject.toml`. Optional `dev` extras
install mypy, pytest, ruff, and typing stubs.

## Dependencies

These are installed automatically with the pixi default environment or an
editable pip install:

- Python (v3.12 or newer)
- Python packages
  - cyvcf2
  - Jinja2
  - jsonschema
  - numpy
  - polars
  - pydantic (v2 or newer)
  - pyarrow
  - pybigwig
  - PyYAML
  - Starlette
  - typer
  - Uvicorn
- Standalone tools
  - [Merlin](http://csg.sph.umich.edu/abecasis/merlin/index.html) (v1.1.2),
    including the `merlin` and `minx` executables on `$PATH` when
    `run_merlin` is enabled

Merlin’s version should be exactly as given. The Merlin executables folder
(`path/to/merlin-1.1.2/executables`) must be on `$PATH`, which is automatic
with the pixi default environment. If `merlin` or `minx` is missing, or only
one real sample is analyzed, the engine sets `run_merlin` to `false`.

Hopla must not invoke Pandoc. The HTML report always inlines packaged
`report.css`, `report.js`, and plotly.js basic (not the full plotly.js
library) and gzip-compresses the columnar analysis payload for the browser
to expand with `DecompressionStream`.

Prefer adding Python dependencies in `pyproject.toml` under both `[project]`
and `[tool.pixi.dependencies]` (or the `dev` extra / `[tool.pixi.feature.dev]`),
then regenerate `pixi.lock` with pixi. Keep those dependencies available as
conda packages so the lock stays free of third-party PyPI source builds.

See [CHANGELOG.md](../CHANGELOG.md) for changes to the Python engine.
