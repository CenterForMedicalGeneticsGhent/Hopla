# Install and dependencies

Hopla requires Python 3.12 or newer (and below 3.14 in the locked pixi
environment).

## Pixi (Linux and macOS)

The repository includes a locked [pixi](https://pixi.sh) environment for
`linux-64`, `linux-aarch64`, and `osx-arm64`. Clone with submodules so pixi
can install `merlinpy` from
[`vendor/abecasis-lab-merlin`](https://github.com/bioinformaticsorphanage/abecasis-lab-merlin):

```bash
git clone --recurse-submodules https://github.com/CenterForMedicalGeneticsGhent/Hopla
cd Hopla
pixi install --locked
pixi run hopla --help
```

If the clone already exists without the submodule, run
`git submodule update --init vendor/abecasis-lab-merlin`.

Use `pixi install --locked` so the committed `pixi.lock` is respected. The
local Hopla package and `merlinpy` submodule are editable pixi path
dependencies; other third-party lock entries are conda packages.

The default environment holds analysis dependencies, including `merlinpy`.
The `dev` environment adds pytest, ruff, mypy, and typing stubs.

Pixi tasks (from the repository root):

- `dev` environment `lint-py` — `ruff check` and `mypy`
- `dev` environment `test-py` — `pytest tests`

After install, `pixi run hopla` invokes the console script (for example
`pixi run hopla convert` or `pixi run hopla serve`).

## Pip (development tree)

From the Hopla repository root, with a Python 3.12+ environment and the Merlin
submodule initialized:

```bash
git submodule update --init vendor/abecasis-lab-merlin
python -m pip install -e vendor/abecasis-lab-merlin
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
  - merlinpy
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

Hopla calls `merlinpy` in-process; the native `merlin` and `minx` executables
are not required. If `merlinpy` is unavailable, or only one real sample is
analyzed, the engine sets `run_merlin` to `false`.

Build the container from the repository root after initializing the submodule:

```bash
git submodule update --init vendor/abecasis-lab-merlin
docker build -t hopla .
```

Hopla must not invoke Pandoc. The HTML report always inlines the offline
`plotly.js` bundle shipped with the plotly package and gzip-compresses the
columnar analysis payload for the browser to expand with
`DecompressionStream`.

Prefer adding Python dependencies in `pyproject.toml` under `[project]` and
the matching pixi conda or PyPI dependency section, then regenerate
`pixi.lock` with pixi. Keep dependencies available as conda packages where
possible; `merlinpy` is the explicit editable submodule-path exception.

See [CHANGELOG.md](../CHANGELOG.md) for changes to the Python engine.
