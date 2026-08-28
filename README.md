# Hopla

Hopla is a Python package for genomic family analysis, interactive reporting,
and browser-assisted configuration.

## Packages

| Package | Description | Documentation |
|---------|-------------|---------------|
| [`hopla-py/`](hopla-py/) | Python CLI, settings editor, analysis engine, and interactive report generator. | [Package manual](hopla-py/docs/README.md) |

Analysis takes a YAML or JSON settings file that can be created by hand or with
the optional `hopla serve` local browser editor.

The repository root owns `pixi.toml`, `pixi.lock`, CI workflows, and contributor
guidance. Package source, tests, the Dockerfile, changelog, and detailed
documentation live under `hopla-py/`.

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

Run the settings editor:

```bash
pixi run hopla serve
```

## Container images

The package image is published as `quay.io/cmgg/hopla` with `latest`, `stable`,
a package version such as `2.1.0`, or a commit SHA.

Build and run the image locally from the repository root:

```bash
docker build -f hopla-py/Dockerfile -t hopla .
docker run --rm -p 8080:8080 hopla hopla serve --host 0.0.0.0 --no-open
```
