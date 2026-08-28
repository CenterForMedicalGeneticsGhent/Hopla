# Hopla documentation

Hopla performs classic genomic single, duo, trio, and larger-family analysis
from one (multisample) VCF, and writes interactive HTML visualizations. When
the pedigree allows it, it also runs offline haplotyping with
[Merlin](http://csg.sph.umich.edu/abecasis/merlin/index.html). Besides
post-natal work, the report is meant to support embryo selection during
preimplantation genetic testing, with the aim of healthy births in affected
families. The name is both a ‘haplo’ anagram and a children’s television show.

This manual documents the Python package at the repository root. Start from the
[README](../README.md) for a short overview.

## Contents

- [Install and dependencies](install.md)
- [Command line](cli.md)
- [Local settings editor](serve.md)
- [Settings](settings.md)
- [HTML output](output.md)
- [Portable and IGV exports](exports.md)
- [Package and engine structure](architecture.md)
- [igv.js feasibility evaluation](igvjs-evaluation.md)
- [Contributing](contributing.md)
- [Changelog](../CHANGELOG.md)
- [Archived legacy pipeline changelog](archive/legacy-pipeline-changelog.md)

## Input

- A (multisample) `vcf.gz` file. In the authors’ tests this was produced with
  gatk-haplotype and gatk-haplotype-joint through
  [bcbio](https://bcbio-nextgen.readthedocs.io/en/latest/), **with a predefined
  target**.
- A YAML or JSON [settings file](settings.md) describing the family and
  analysis options. Create it by hand or with the optional local
  [`hopla serve`](serve.md) editor.
- The VCF path and output directory are command-line arguments, not settings
  keys.

## Quick start

```bash
git clone https://github.com/CenterForMedicalGeneticsGhent/Hopla
cd Hopla
pixi install --locked
pixi run hopla run example/settings.yaml path/to/family.vcf.gz
```

The command validates settings before reading the VCF and writes a compact,
offline HTML report. By default it also writes portable Parquet tables and IGV
desktop tracks under `{fam_id}-export/`. Merlin 1.1.2 remains an optional
external dependency for haplotyping. Example settings live in
[`example/`](../example/).

## Maintainers and contact

- Matthias De Smet — package maintainer, <matthdsm@users.noreply.github.com>
- Center for Medical Genetics Ghent — institutional maintainer and copyright
  holder, <ict.cmgg@uzgent.be>
- Lennart Raman — original author, <leraman@users.noreply.github.com>

Bug reports: <https://github.com/CenterForMedicalGeneticsGhent/Hopla/issues>.
