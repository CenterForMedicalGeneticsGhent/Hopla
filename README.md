# Hopla

Hopla performs classic genomic single, duo, trio, and larger-family analysis
from one (multisample) VCF, and writes interactive HTML visualizations. When
the pedigree allows it, it also runs offline haplotyping with
[Merlin](http://csg.sph.umich.edu/abecasis/merlin/index.html). Besides
post-natal work, the report is meant to support embryo selection during
preimplantation genetic testing, with the aim of healthy births in affected
families. The name is both a ‘haplo’ anagram and a children’s television show.

This repository holds the typed Python package `hopla` (version 3.0.0).

## Contents

- [Install and dependencies](docs/install.md)
- [Command line](docs/cli.md)
- [Local settings editor](docs/serve.md)
- [Settings](docs/settings.md)
- [HTML output](docs/output.md)
- [Portable and IGV exports](docs/exports.md)
- [Package and engine structure](docs/architecture.md)
- [igv.js feasibility evaluation](docs/igvjs-evaluation.md)
- [Contributing](docs/contributing.md)
- [Changelog](CHANGELOG.md)
- [Archived legacy pipeline changelog](docs/archive/legacy-pipeline-changelog.md)

## Input

- A (multisample) `vcf.gz` file.
- A YAML or JSON [settings file](docs/settings.md) describing the family and analysis options. Create it by hand or with the optional local [`hopla serve`](docs/serve.md) editor.
- The VCF path and output directory are command-line arguments, not settings keys.

## Quick start

```bash
git clone https://github.com/CenterForMedicalGeneticsGhent/Hopla
cd Hopla
pixi install --locked
pixi run hopla run example/settings.yaml path/to/family.vcf.gz
```

By default `hopla run` also writes `{fam_id}-export/` with Parquet tables and
IGV desktop tracks. See [exports.md](docs/exports.md). Example settings and a
legacy conversion fixture are in [`example/`](example/).

```bash
hopla run settings.yaml family.vcf.gz
hopla serve
hopla convert legacy-settings.txt
hopla concordance family-a-flow.txt family-b-flow.txt
hopla transform family-a-flow.txt family-b-flow.txt 1
```

## Development with Pixi

```bash
pixi install --locked
pixi run -e dev lint-py
pixi run -e dev test-py
pixi run hopla serve
```

## Container images

The image is published as `quay.io/cmgg/hopla` with `latest`, `stable`, a
package version such as `3.0.0`, or a commit SHA.

```bash
docker build -t hopla .
docker run --rm -p 8080:8080 hopla hopla serve --host 0.0.0.0 --no-open
```

## Maintainers and contact

- Matthias De Smet — package maintainer, <matthdsm@users.noreply.github.com>
- Center for Medical Genetics Ghent — institutional maintainer and copyright holder, <ict.cmgg@uzgent.be>
- Lennart Raman — original author, <leraman@users.noreply.github.com>

Bug reports: <https://github.com/CenterForMedicalGeneticsGhent/Hopla/issues>.
