# Hopla

Hopla is a monorepo for genomic family analysis and its browser-based
configuration editor.

## Packages

| Package | Description | Documentation |
|---------|-------------|---------------|
| [`hopla-py/`](hopla-py/) | Python package, CLI, analysis engine, and interactive report generator. | [Python package manual](hopla-py/docs/README.md) |
| [`hopla-ui/`](hopla-ui/) | Optional local helper for creating Hopla configuration files in the browser. | [UI README](hopla-ui/README.md) and [UI docs](hopla-ui/docs/README.md) |

The UI is not required to run Hopla. Analysis takes a YAML or JSON settings
file that can be created and edited by hand; the UI only helps write that file.
It is meant to run locally as a short-lived application, not as a standing
service.

The repository root owns the shared `pixi.toml`, `pixi.lock`, CI workflows, and
contributor guidance. Each package keeps its source, tests, Dockerfile,
changelog, and detailed documentation in its own directory.

## Development with Pixi

Install the locked environments from the repository root:

```bash
pixi install --locked
```

Run the Python CLI and checks:

```bash
pixi run -e hopla-py install-py
pixi run hopla run hopla-py/example/settings.yaml path/to/family.vcf.gz
pixi run -e hopla-py-dev lint-py
pixi run -e hopla-py-dev test-py
```

Run the UI:

```bash
pixi run -e hopla-ui serve
pixi run -e hopla-ui lint
pixi run -e hopla-ui test
pixi run -e hopla-ui build
```

## Container images

Both packages use `quay.io/cmgg/hopla`; tags identify the package:

- Python package: `latest`, `stable`, a package version such as `2.0.0`, or a commit SHA.
- UI package: `ui-latest`, `ui-stable`, a UI version such as `ui-0.2.0`, or `ui-<commit-sha>`.

Build either image locally from the repository root:

```bash
docker build -f hopla-py/Dockerfile -t hopla .
docker build -f hopla-ui/Dockerfile -t hopla:ui-local hopla-ui
```
