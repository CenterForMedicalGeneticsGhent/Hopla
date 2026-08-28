# Install and dependencies

Hopla requires Python 3.12 or newer (and below 3.14 in the locked pixi
environment).

## Pixi (Linux and macOS)

The monorepo root includes a locked [pixi](https://pixi.sh) environment for
`linux-64`, `linux-aarch64`, and `osx-arm64`. Merlin 1.1.2 is included on each
of those platforms in the `hopla-py` feature.

```bash
pixi install --locked
pixi run -e hopla-py install-py
pixi run hopla --help
```

Use `pixi install --locked` so the committed `pixi.lock` is respected.

The `hopla-py` environment holds analysis dependencies. The `hopla-py-dev`
environment adds pytest, ruff, mypy, and typing stubs.

Pixi tasks (from the repository root):

- `hopla-py` environment `install-py` — editable install of `hopla-py` with
  `python -m pip install --no-deps -e hopla-py`
- `hopla-py` environment `hopla-py` — `python -m hopla.cli` (depends on
  `install-py`)
- default environment `hopla`, `serve`, `convert`, `concordance`, and `transform` —
  installed Python CLI entry points (depend on `install-py`)
- `hopla-py-dev` environment `lint-py` — `ruff check` and `mypy`
- `hopla-py-dev` environment `test-py` — `pytest hopla-py/tests`

After the editable install, the `hopla` console script is also available on the
environment `PATH`.

## Pip (development tree)

From the repository root, with a Python 3.12+ environment that already provides
Merlin on `$PATH` when haplotyping is needed:

```bash
python -m pip install -e 'hopla-py[dev]'
hopla --help
```

Runtime dependencies are declared in `hopla-py/pyproject.toml`. Optional `dev`
extras install mypy, pytest, ruff, and typing stubs.

## Dependencies

These are installed automatically with the pixi `hopla-py` environment or an
editable pip install:

- Python (v3.12 or newer)
- Python packages
  - cyvcf2
  - Jinja2
  - jsonschema
  - numpy
  - plotly
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
with the pixi `hopla-py` environment. If `merlin` or `minx` is missing, or only
one real sample is analyzed, the engine sets `run_merlin` to `false`.

Hopla must not invoke Pandoc. The HTML report always inlines the offline
`plotly.js` bundle shipped with the plotly package and gzip-compresses the
columnar analysis payload for the browser to expand with
`DecompressionStream`.

Prefer adding Python dependencies through the root `pixi.toml` `hopla-py`
feature and `hopla-py/pyproject.toml`, then regenerate the root `pixi.lock`
with pixi.

See [CHANGELOG.md](../CHANGELOG.md) for changes to the Python engine.
