# Hopla R package

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat)](http://bioconda.github.io/recipes/hopla/README.html)
[![Bioconda downloads](https://anaconda.org/bioconda/hopla/badges/downloads.svg)](https://anaconda.org/bioconda/hopla)
[![Bioconda version](https://anaconda.org/bioconda/hopla/badges/version.svg)](https://anaconda.org/bioconda/hopla)

This directory is the CRAN-compatible source tree for the `hopla` R package,
CLI, genomic family analysis engine, and self-contained interactive reports.
The monorepo directory is named `hopla-r`; the installed R package and command
remain `hopla`.

Read the [full R package manual](docs/README.md) for installation, CLI,
settings, output, architecture, and contribution guidance.

From the repository root:

```bash
pixi install --locked
pixi run hopla run hopla-r/example/settings.yaml path/to/family.vcf.gz
pixi run -e hopla-r-dev lint
pixi run -e hopla-r-dev check
```

Install the published package with:

```bash
conda install -c conda-forge -c bioconda hopla
```

The R container is published as `quay.io/cmgg/hopla` with unprefixed tags such
as `latest`, `stable`, and the package version.
