[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat)](http://bioconda.github.io/recipes/hopla/README.html)
[![Anaconda-Server Badge](https://anaconda.org/bioconda/hopla/badges/downloads.svg)](https://anaconda.org/bioconda/hopla)
[![Anaconda-Server Badge](https://anaconda.org/bioconda/hopla/badges/latest_release_date.svg)](https://anaconda.org/bioconda/hopla)
[![Anaconda-Server Badge](https://anaconda.org/bioconda/hopla/badges/version.svg)](https://anaconda.org/bioconda/hopla)

# Hopla

Hopla enables classic genomic single, duo, trio, and larger-family analysis from one (multisample) VCF, producing interactive visualizations. When possible it runs offline pedigree haplotyping with [Merlin](http://csg.sph.umich.edu/abecasis/merlin/index.html). The report also supports embryo selection during preimplantation genetic testing. The name is both a ‘haplo’ anagram and a children’s television show.

**Full manual:** [docs/README.md](docs/README.md)

```bash
pixi install
pixi run hopla run example/settings.yaml path/to/family.vcf.gz
```

```bash
conda install -c conda-forge -c bioconda hopla
```

```bash
docker build -t hopla .
docker run --rm hopla hopla -V
```
