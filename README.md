[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat)](http://bioconda.github.io/recipes/hopla/README.html)
[![Anaconda-Server Badge](https://anaconda.org/bioconda/hopla/badges/downloads.svg)](https://anaconda.org/bioconda/hopla)
[![Anaconda-Server Badge](https://anaconda.org/bioconda/hopla/badges/latest_release_date.svg)](https://anaconda.org/bioconda/hopla)
[![Anaconda-Server Badge](https://anaconda.org/bioconda/hopla/badges/version.svg)](https://anaconda.org/bioconda/hopla)
# Hopla's objective
Hopla enables classic genomic single, duo, trio, etc., analysis, by studying a single (multisample) vcf-file, eventually generating interactive visualizations. In addition, when possible, Hopla executes offline pedigree haplotyping through [Merlin](http://csg.sph.umich.edu/abecasis/merlin/index.html). Other than post-natal analyses, its all-inclusive output enables embryo selection during preimplantation genetic testing, ultimately intending birth of healthy children in affected families. The name 'Hopla' originates from being both a 'haplo' anagram and a popular kids' television show.

# Easy install

Hopla requires R 4.4 or newer. The repository includes a locked [pixi](https://pixi.sh) environment for Linux:

```bash
pixi install
pixi run hopla --help
```

Alternatively, install the published package through [conda](https://docs.conda.io/en/latest/):

```bash

conda install -c conda-forge -c bioconda hopla
```

## Docker

The root Dockerfile builds a minimal Linux image from `pixi.lock`; it is separate from the UI image:

```bash
docker build -t hopla .
docker run --rm hopla hopla --version
```

# Input
- A (multisample) vcf.gz file (in our tests generated using gatk-haplotype & gatk-haplotype-joint through [bcbio](https://bcbio-nextgen.readthedocs.io/en/latest/), **with a predefined target**)
- A YAML or JSON [settings file](#settings-file) describing the family and analysis options

# Settings file

The `run` subtool accepts exactly one `.yaml`, `.yml`, or `.json` settings file. It validates the complete document against [`inst/schema/hopla.schema.json`](inst/schema/hopla.schema.json) before loading the VCF or analysis packages. Unknown properties, invalid types, missing mandatory values, and out-of-range values fail immediately.

`vcf.file` and `sample.ids` are mandatory. All other properties use the defaults encoded in the schema and analysis engine. Lists must be YAML/JSON arrays; use `null` for an unknown parent or gender.

```yaml
vcf.file: /data/family.vcf.gz
sample.ids: [sample_C, sample_B, sample_A]
father.ids: [null, null, sample_C]
mother.ids: [null, null, sample_B]
genders: [M, F, null]
run.merlin: true
regions:
  - chr7:117480025-117668665
info:
  - "Disease: Cystic Fibrosis"
  - "Inheritance: Autosomal Recessive"
```

See [`example/settings.yaml`](example/settings.yaml) for a complete example and [`inst/schema/hopla.schema.json`](inst/schema/hopla.schema.json) for every option, type, default, and constraint.

# Dependencies (automatically installed with [easy install](#Easy-install))
- R (v4.4 or newer)
- R packages
    - vcfR (v1.16.0 or newer)
    - data.table (v1.17.0 or newer)
    - RColorBrewer (v1.1-3 or newer)
    - kinship2 (v1.9.0 or newer)
    - plotly (v4.12.0 or newer)
    - htmltools (v0.5.0)
    - base64enc (v0.1-3 or newer)
    - jsonlite, jsonvalidate, and yaml
    - scales (v1.4.0 or newer)
    - GenomicRanges and DNAcopy from the Bioconductor release matching the installed R version
- Standalone tools
    - [Merlin](http://csg.sph.umich.edu/abecasis/merlin/index.html) (v1.1.2)

Merlin's version should be exactly as given.  
Plotly's version is ideally no lower than given.  
For the remaining packages, other versions are very likely to work.  
Hopla does not invoke Pandoc. Conda may still resolve it transitively through plotly's htmlwidgets/rmarkdown dependency chain; the runtime Docker image removes the unused executable.

See [CHANGELOG-R.md](CHANGELOG-R.md) for changes to the R pipeline scripts.

# Running Hopla

```bash
pixi run hopla run path/to/settings.yaml
# or, in an installed Bioconda environment:
hopla run path/to/settings.json
```

Flow-table utilities are available as subtools:

```bash
pixi run hopla concordance family-a-flow.txt family-b-flow.txt
pixi run hopla transform family-a-flow.txt family-b-flow.txt 1
```

# Running the example

```bash
git clone https://github.com/CenterForMedicalGeneticsGhent/Hopla
cd hopla
pixi run hopla run example/settings.yaml
```

# Output

The output is an interactive HTML file. By mouse hovering, draging, etc., figures can be manipulated, and often, raw data can be consulted. A partial toy example is given at *example/hopla.html*.  

## Family/disease information

Info as provided by `info`.

## Family tree

If two or more samples are provided, the family structure is shown as defined by `sample.ids`, `father.ids` and `mother.ids`. Annotations are added according to `reference.ids`, `carrier.ids`, `affected.ids`, `nonaffected.ids` (these are re-used throughout the HTML). Squares are males and circles are females, as given by `genders`, or as predicted by `X.cutoff` and `Y.cutoff`.

## Filter 0: single nucleotide variants

This section contains tables/plots applied to all raw single nucleotide variants.

### Variant statistics

Includes variant tables, allelic drop-out (ADO) & allelic drop-in (ADI) for every child/embryo, variant depth histograms and a genome-wide number-of-variants profile.  

*Note 1*: ADO is calculated using all variants that are 0/0 in mother and 1/1 in father, or vice versa, as [(homozygous variants in child)/(total variants in child)].  
*Note 2*: ADI is calculated using all variants that are 1/1 in both mother and father, as [(heterozygous variants in child)/(total variants in child)].  

### Vcf-based copy number

The quality of these copy number profiles depends on how the vcf files were generated. It is highly advised to use a bam-based software to verify copy number, such as [WisecondorX](https://github.com/CenterForMedicalGeneticsGhent/WisecondorX/).

## Filter 1: filter 0, dp.hard.limit, af.hard.limit and dp.soft.limit

This section contains tables/plots applied to single nucleotide variants that are filtered by `dp.hard.limit`, `af.hard.limit` and `dp.soft.limit`.

### Variant statistics

Similar to previous 'Variant statistics' section.

### B-allele frequency (BAF), region(s) of interest

For each provided region, given by `regions`, a BAF profile is shown per sample.

### B-allele frequency (BAF), genome-wide

Genome-wide BAF profiles are included for samples given in `baf.ids`.

### Mendelian errors

Mendelian errors are derived for every sample when at least one parent is available. Shown per child/embryo:  
- 'trio errors', when both parents are available (e.g., child can't be 0/0 if parents are 1/1 and 0/1)
- 'father errors', where only the father-child relation is verified (or available), based on homozygous inheritance (e.g., child can't be 0/0 if father is 1/1)
- 'mother errors', where only the mother-child relation is verified (or available), based on homozygous inheritance (e.g., child can't be 0/0 if mother is 1/1)  

Useful for hetero/iso-uniparental disomy (UPD) detection, as an additional quality control, and to recognize sample swaps.  

### Parent mapping

'Parent mapping' is executed for every sample when at least one parent is available. Useful for hetero/iso-uniparental disomy (UPD) detection and to analyze whether aberrations are meiotic or mitotic.  

Variants of the child/embryo are distributed per parental origin. Symbols above the chromosome bands represent informative variants of the father, while symbols below represent informative variants of the mother. The top and bottom tracks per parental origin represent variants for which the embryo is heterozygous and homozygous, respectively.  

## Filter 2: filter 0, filer 1, keep.informative.ids and keep.hetero.ids

### Variant statistics

Similar to previous 'Variant statistics' sections, but ADO/ADI is not calculated.

### Haplotyping by Merlin

Merlin is executed if more than one sample is provided in `sample.ids`, and `run.merlin: true` is set.

Different haplotypes are given by colors. Haplotypes are relative between individuals/strands within a family (i.e., same-haplotype colors are not constant between HTML output files). Details at each variant can be obtained by mouse hovering.  

*Note 1*: Raw Merlin haplotypes can be corrected using `window.size.voting`. Nearby variants vote on the haplotype at each position, weighted by `window.size.voting / (distance + window.size.voting / 2) - 1`. Corrected haplotypes use a circle symbol; raw genotypes remain available on hover.

*Note 2*: haplotypes from Merlin can be further corrected using `min.seg.var`. A haplotype stretch needs to have at least `min.seg.var` variants. If not, the haplotype segment is corrected to its neighbouring haplotype segments. Corrected haplotypes are shown using a circle symbol (instead of squares). The raw uncorrected genotyping data can be consulted at any time by mouse hovering.

*Note 3*: There is no haplotyping executed when the given family structure does not allow it (i.e., when no reference sample is provided, there will be no breakpoints in the haplotyping strands).  

*Note 4*: When the raw genotype is `NA`, it has been removed by soft filtering and no symbol is shown.

### Haplotyping by Merlin: strand concordance

If `concordance.table: true` is set, the concordance in haplotyping patterns between strands of different family members is shown in form of a pairwise comparative table. The concordance per strand is calculated as [(same-haplotype variants between strands)/(total number of evaluated variants)].
