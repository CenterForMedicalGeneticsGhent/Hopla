# Hopla Python

Hopla performs classic genomic single, duo, trio, and larger-family analysis
from one (multisample) VCF, and writes interactive HTML visualizations. When
the pedigree allows it, it also runs offline haplotyping with
[Merlin](http://csg.sph.umich.edu/abecasis/merlin/index.html). Besides
post-natal work, the report is meant to support embryo selection during
preimplantation genetic testing, with the aim of healthy births in affected
families. The name is both a ‘haplo’ anagram and a children’s television show.

This directory holds the typed Python package `hopla` (version 2.0.0).
Repository-wide and UI documentation are available from the
[monorepo README](../README.md).

## Contents

- [Install and dependencies](docs/install.md)
- [Command line](docs/cli.md)
- [Settings](docs/settings.md)
- [HTML output](docs/output.md)
- [Portable and IGV exports](docs/exports.md)
- [Package and engine structure](docs/architecture.md)
- [igv.js feasibility evaluation](docs/igvjs-evaluation.md)
- [Contributing](docs/contributing.md)
- [Changelog](CHANGELOG.md)
- [Archived legacy pipeline changelog](docs/archive/legacy-pipeline-changelog.md)

## Input

- A (multisample) `vcf.gz` file. In the authors’ tests this was produced with
  gatk-haplotype and gatk-haplotype-joint through
  [bcbio](https://bcbio-nextgen.readthedocs.io/en/latest/), **with a predefined
  target**.
- A YAML or JSON [settings file](docs/settings.md) describing the family and
  analysis options. Create it by hand or with the optional local
  [web UI](../hopla-ui/docs/README.md); the UI is not required to run Hopla.
- The VCF path and output directory are command-line arguments, not settings
  keys.

## Quick start

```bash
git clone https://github.com/CenterForMedicalGeneticsGhent/Hopla
cd Hopla
pixi install --locked
pixi run -e hopla-py install-py
pixi run hopla run hopla-py/example/settings.yaml path/to/family.vcf.gz
```

By default `hopla run` also writes `{fam_id}-export/` with Parquet tables and
IGV desktop tracks. See [exports.md](docs/exports.md). Example settings and a
legacy conversion fixture are in [`example/`](example/).

```bash
hopla run settings.yaml family.vcf.gz
hopla convert legacy-settings.txt
hopla concordance family-a-flow.txt family-b-flow.txt
hopla transform family-a-flow.txt family-b-flow.txt 1
```

## Maintainers and contact

- Matthias De Smet — package maintainer, <matthdsm@users.noreply.github.com>
- Center for Medical Genetics Ghent — institutional maintainer and copyright
  holder, <ict.cmgg@uzgent.be>
- Lennart Raman — original author, <leraman@users.noreply.github.com>

Bug reports: <https://github.com/CenterForMedicalGeneticsGhent/Hopla/issues>.
