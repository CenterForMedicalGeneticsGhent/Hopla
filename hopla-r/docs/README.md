# Hopla documentation

Hopla performs classic genomic single, duo, trio, and larger-family analysis from one (multisample) VCF, and writes interactive HTML visualizations. When the pedigree allows it, it also runs offline haplotyping with [Merlin](http://csg.sph.umich.edu/abecasis/merlin/index.html). Besides post-natal work, the report is meant to support embryo selection during preimplantation genetic testing, with the aim of healthy births in affected families. The name is both a ‘haplo’ anagram and a children’s television show.

This manual documents the CRAN-compatible `hopla` R package in `hopla-r/`.
Repository-wide and UI documentation are available from the
[monorepo README](../../README.md).

## Contents

- [Install and dependencies](install.md)
- [Command line](cli.md)
- [Settings](settings.md)
- [HTML output](output.md)
- [Package and engine structure](architecture.md)
- [Contributing](contributing.md)
- [R pipeline changelog](../CHANGELOG-R.md)

Install badges for the published Bioconda package:

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat)](http://bioconda.github.io/recipes/hopla/README.html)
[![Anaconda-Server Badge](https://anaconda.org/bioconda/hopla/badges/downloads.svg)](https://anaconda.org/bioconda/hopla)
[![Anaconda-Server Badge](https://anaconda.org/bioconda/hopla/badges/latest_release_date.svg)](https://anaconda.org/bioconda/hopla)
[![Anaconda-Server Badge](https://anaconda.org/bioconda/hopla/badges/version.svg)](https://anaconda.org/bioconda/hopla)

## Input

- A (multisample) `vcf.gz` file. In the authors’ tests this was produced with gatk-haplotype and gatk-haplotype-joint through [bcbio](https://bcbio-nextgen.readthedocs.io/en/latest/), **with a predefined target**.
- A YAML or JSON [settings file](settings.md) describing the family and analysis options.
- The VCF path and output directory are command-line arguments, not settings keys.

## Quick start

```bash
git clone https://github.com/CenterForMedicalGeneticsGhent/Hopla
cd Hopla
pixi install --locked
pixi run hopla run hopla-r/example/settings.yaml path/to/family.vcf.gz
```

Example report archives and a complete settings example are in
[`hopla-r/example/`](../example/).

## Maintainers and contact

- Matthias De Smet — package maintainer, <matthdsm@users.noreply.github.com>
- Center for Medical Genetics Ghent — institutional maintainer and copyright holder, <ict.cmgg@uzgent.be>
- Lennart Raman — original author, <leraman@users.noreply.github.com>

R records exactly one `cre` (maintainer) entry in `DESCRIPTION`; that slot holds the package maintainer above, while the institutional contact is listed here and as copyright holder and funder.

Bug reports: <https://github.com/CenterForMedicalGeneticsGhent/Hopla/issues>.
