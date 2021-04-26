[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat)](http://bioconda.github.io/recipes/hopla/README.html)
[![Anaconda-Server Badge](https://anaconda.org/bioconda/hopla/badges/downloads.svg)](https://anaconda.org/bioconda/hopla)
[![Anaconda-Server Badge](https://anaconda.org/bioconda/hopla/badges/latest_release_date.svg)](https://anaconda.org/bioconda/hopla)
[![Anaconda-Server Badge](https://anaconda.org/bioconda/hopla/badges/version.svg)](https://anaconda.org/bioconda/hopla)
# Hopla's objective
Hopla enables classic genomic single, duo, trio, etc., analysis, by studying a single (multisample) vcf-file, eventually generating interactive visualizations. In addition, when possible, Hopla executes offline pedigree haplotyping through [Merlin](http://csg.sph.umich.edu/abecasis/merlin/index.html). Other than post-natal analyses, its all-inclusive output enables embryo selection during preimplantation genetic testing, ultimately intending birth of healthy children in affected families. The name 'Hopla' originates from being both a 'haplo' anagram and a popular kids' television show.

# Easy install

Hopla and all [necessary dependencies](#Dependencies-automatically-installed-with-easy-install) can be installed through [conda](https://docs.conda.io/en/latest/), using:  

```bash

conda install -c conda-forge -c bioconda hopla
```

# Input
- A (multisample) vcf.gz file (in our tests generated using gatk-haplotype & gatk-haplotype-joint through [bcbio](https://bcbio-nextgen.readthedocs.io/en/latest/), **with a predefined target**)
- Several parameter arguments, required to, e.g., define the family pedigree structure, in form of a [settings file](#Settings-file) and/or command line arguments

# Arguments

## Mandatory arguments

- **`--vcf.file [string]`** Path to (multisample) vcf.gz file
- **`--out.dir [string]`** Path to output folder
- **`--sample.ids [string list, comma sep]`** Sample IDs as given in the file at `--vcf.file`; e.g., sample_C,sample_B,sample_A; missing samples can be added using 'unknown' IDs U1,U2,... which is useful to, e.g., define uncle/niece/... relations, by reusing these IDs in `--father.ids` and `--mother.ids`

## Optional arguments
### **Important** optional arguments

- **`--father.ids [string list, comma sep, no default]`** Sample IDs fathers; when not available, use NA; order matches `--sample.ids`; e.g., NA,NA,sample_C
- **`--mother.ids [string list, comma sep, no default]`** Sample IDs mothers; when not available, use NA; order matches `--sample.ids`; e.g., NA,NA,sample_B
- **`--genders [char (M/F/NA) list, comma sep, no default]`** Sample genders; when not available, use NA, model will predict gender (see below); order matches `--sample.ids`; e.g., M,F,NA
- **`--run.merlin [boolean, default = T]`** Whether Merlin (i.e., haplotyping) should be executed; **Note that the Merlin executables folder (i.e., path/to/merlin-1.1.2/executables) should be located in $PATH, which should be automatically the case when using [Easy install](#easy-install); Merlin only runs in Linux**
- **`--cytoband.file [string, no default]`** [UCSC cytoband file](https://hgdownload.soe.ucsc.edu/downloads.html#human); when given, chromosome bands are shown on top of chromosome-wise figures; highly improves interpretability of figures; e.g., path/to/cytoband.hg38.txt

### **Important** optional variant inclusion arguments: filter 1

- EVERY sample in **`--dp.hard.limit.samples [string list, comma sep, default=--sample.ids]`** should have variants with a coverage of at least **`--dp.hard.limit [integer, default=10]`**; applies hard filter: variants that do not comply will be removed from all samples
- AT LEAST ONE sample in **`--af.hard.limit.samples [string list, comma sep, default=--sample.ids]`** should have variants with an allele fraction of at least **`--af.hard.limit [numeric (range 0-1), default=0]`**; applies hard filter: variants that do not comply will be removed from all samples
- Variants from samples in **`--dp.soft.limit.samples [string list, comma sep, default=--sample.ids]`** should have a coverage of at least **`--dp.soft.limit [integer, default=15]`**; applies soft filter: variants that do not comply will be removed from the given samples only

### **Important** optional variant inclusion arguments: filter 2

- **`--keep.informative.ids [string list, comma sep, no default]`** Only keep variants that are 0/1 in sample 1 and 0/0|1/1 in sample 2, and vice versa; effective if exactly two samples are given; translates to 'parents' in classic setting; e.g., sample_C,sample_B
- **`--keep.hetero.ids [string list, comma sep, no default]`** Only keep variants that are 0/1 in at least one of the given samples; effective if one or more samples are given; soft filter will be used to exclude 0/0 and 1/1 variants; only applies to autosomes; translates to 'children/embryos' in classic setting; e.g., sample_A

### Sample/disease annotation

- **`--regions [string list, comma sep, no default]`** Region(s) of interest; define using 'chr:start-end' (in bp); when given, will mark regions in output at any time, generate detailed B-allele frequency (BAF) profiles, and keep corresponding raw data at any time; e.g., chr7:117480025-117668665
- **`--reference.ids [string list, comma sep, no default]`** When given, family tree and sample names are colored/annotated accordingly; none or more expected
- **`--carrier.ids [string list, comma sep, no default]`** When given, family tree and sample names are colored/annotated accordingly; none or more expected
- **`--affected.ids [string list, comma sep, no default]`** When given, family tree and sample names are colored/annotated accordingly; none or more expected
- **`--nonaffected.ids [string list, comma sep, no default]`** When given, family tree and sample names are colored/annotated accordingly; none or more expected
- **`--info [string list, comma sep, no default]`** Additional information to print at the top of the HTML output; when using a [settings file](#Settings-file), following alternative structure is advised:
    
      start.info  
      Some information.  
      Disease: Cystic Fybrosis  
      Inheritance: Autosomal Recessive  
      Some more information.  
      end.info  

### B-allele frequency (BAF) profiles

- **`--baf.ids [string list, comma sep, no default]`** BAF profiles will be generated for the region(s) of interest for all samples; include samples here if a genome-wide BAF profile is desired; e.g., sample_B,sample_C; **WARNING**: this increases the HTML size significantly, which might decrease usability; and, the maximum number of plots per HTML output could be reached, which hides other plots

### Merlin haplotyping profiles
- **`--merlin.model [string, default=best]`** Underlying [Merlin haplotyping model](http://csg.sph.umich.edu/abecasis/merlin/tour/haplotyping.html) to be used; choose between 'sample' and 'best'
- **`--min.seg.var [integer, default=5]`** Minimum number of variants in a same-haplotype segment; haplotype segments that do not comply are corrected to neighbouring haplotype; corrected haplotypes are shown using a circle symbol; will not be applied when set to 0
- **`--min.seg.var.X [integer, default=--min.seg.var]`** The parameter `--min.seg.var` can be set separately for chromosome X
- **`--window.size.voting [integer, default=5000000]`** Size (in bp) to correct haplotypes by 'weighted neighbourhood voting'; corrected haplotypes are shown using a circle symbol; will not be applied when set to 0
- **`--window.size.voting.X [integer, default=--window.size.voting]`** The parameter `--window.size.voting` can be set separately for chromosome X
- **`--keep.chromosomes.only [boolean, default=T]`** Whether raw data points in haplotyping profiles, with the exception of the complete chromosomes in the region(s) of interest, should be omitted; significantly lowers HTML size
- **`--keep.regions.only [boolean, default=F]`** Whether raw data points in haplotyping profiles, with the exception of the region(s) of interest, should be omitted; significantly lowers HTML size
- **`--concordance.table [boolean, default=T]`** Whether a haplotyping strand-wise concordance table should be added; useful for validation purposes

### Remaining features
- **`--X.cutoff [numeric, default = 1.5]`** Used as 'X chromosome copy number cutoff' for gender prediction (one copy assumed in males, two in females)
- **`--Y.cutoff [numeric, default = 0.5']`** Used as 'Y chromosome copy number cutoff' for gender prediction (one copy assumed in males, noise expected in females)
- **`--window.size [integer, default=1000000]`** Several genome-wide profiles are made in a bin-wise manner; define size (in bp) of bin
- **`--regions.flanking.size [integer, default=5000000]`** Flanking size (in bp) to mark region(s) of interest
- **`--limit.baf.to.P [boolean, default=F]`** Whether the genome-wide BAF profiles should be randomly sampled to include only a % (defined by P) of the data; significantly lowers HTML output size
- **`--limit.pm.to.P [boolean, default=F]`** Whether the parent mapping profiles should be randomly sampled to include only a % (defined by P) of the data; significantly lowers HTML output size
- **`--value.of.P [numeric (range 0-1), default=.25]`** Value of P (see two parameters above)
- **`--color.palette [string, default=Paired]`** [Color palette](https://rdrr.io/cran/RColorBrewer/man/ColorBrewer.html) to be used in visualizations
- **`--dot.factor [numeric, default=2]`** The size of every dot in the visualizations is multiplied by this number
- **`--self.contained [boolean, default=F]`** Whether to generate a self-contained HTML; requires [Pandoc](https://github.com/rstudio/rmarkdown/blob/master/PANDOC.md)
- **`--cairo [boolean, default=F]`** Whether the cairo bitmap should be used (required by some systems for plotting)

# Settings file
- Arguments (one line each, with the exception of the `--info` argument) can be provided using 'argument=value'
- Unset (or unprovided) arguments will be given their respective default value (see above)
- Every parameter in this file is overridden by command line arguments when given
- Everything following '#' will be ignored, serving as a comment
- Example at *example/example-settings.txt*

# Dependencies (automatically installed with [easy install](#Easy-install))
- R packages
    - vcfR (v1.12.0)
    - data.table (v1.13.2)
    - RColorBrewer (v1.1-2)
    - kinship2 (v1.8.5)
    - plotly (v4.9.2.1)
    - htmltools (v0.5.0)
    - GenomicRanges (v1.42.0)
    - DNAcopy (v1.64.0)
    - knitr (v1.29)
- Standalone tools
    - [Merlin](http://csg.sph.umich.edu/abecasis/merlin/index.html) (v1.1.2)
    - ([Pandoc](https://github.com/rstudio/rmarkdown/blob/master/PANDOC.md) (v2.10))  

Merlin's version should be exactly as given.  
Plotly's version is ideally no lower than given.  
For the remaining packages, other versions are very likely to work.  

# Running Hopla

There are **three ways** to execute Hopla:

- Using a [settings file](#Settings-file):

```bash

hopla --settings path/to/settings.txt
```

- Using command line arguments:

```bash

hopla --sample.ids sample_C,sample_B,sample_A --out.dir path/to/output --vcf.file path/to/vcf.gz 
```

- Combining the above, where command line arguments override [settings file](#Settings-file) arguments

```bash

hopla --settings path/to/settings.txt --keep.chromosomes.only F --limit.baf.to.P T
```

# Running the example

```bash

git clone https://github.com/leraman/hopla
cd hopla
hopla --settings example/example-settings.txt
```

# Output

The output is an interactive HTML file. By mouse hovering, draging, etc., figures can be manipulated, and often, raw data can be consulted. A partial toy example is given at *example/hopla.html*.  

## Family/disease information

Info as provided by `--info`.

## Family tree

If two or more samples are provided, the family structure is shown as defined by `--sample.ids`, `--father.ids` and `--mother.ids`. Annotations are added according to `--reference.ids`, `--carrier.ids`, `--affected.ids`, `--nonaffected.ids` (these are re-used throughout the HTML). Squares are males and circles are females, as given by `--genders`, or as predicted by `--X.cutoff` and `--Y.cutoff`.

## Filter 0: single nucleotide variants

This section contains tables/plots applied to all raw single nucleotide variants.

### Variant statistics

Includes variant tables, allelic drop-out (ADO) & allelic drop-in (ADI) for every child/embryo, variant depth histograms and a genome-wide number-of-variants profile.  

*Note 1*: ADO is calculated using all variants that are 0/0 in mother and 1/1 in father, or vice versa, as [(homozygous variants in child)/(total variants in child)].  
*Note 2*: ADI is calculated using all variants that are 1/1 in both mother and father, as [(heterozygous variants in child)/(total variants in child)].  

### Vcf-based copy number

The quality of these copy number profiles depends on how the vcf files were generated. It is highly advised to use a bam-based software to verify copy number, such as [WisecondorX](https://github.com/CenterForMedicalGeneticsGhent/WisecondorX/).

## Filter 1: filter 0, --dp.hard.limit, --af.hard.limit and --dp.soft.limit

This section contains tables/plots applied to single nucleotide variants that are filtered by `--dp.hard.limit`, `--af.hard.limit` and `--dp.soft.limit`.

### Variant statistics

Similar to previous 'Variant statistics' section.

### B-allele frequency (BAF), region(s) of interest

For each provided region, given by `--regions`, a BAF profile is shown per sample.

### B-allele frequency (BAF), genome-wide

Genome-wide BAF profiles are included for samples given in `--baf.ids`.

### Mendelian errors

Mendelian errors are derived for every sample when at least one parent is available. Shown per child/embryo:  
- 'trio errors', when both parents are available (e.g., child can't be 0/0 if parents are 1/1 and 0/1)
- 'father errors', where only the father-child relation is verified (or available), based on homozygous inheritance (e.g., child can't be 0/0 if father is 1/1)
- 'mother errors', where only the mother-child relation is verified (or available), based on homozygous inheritance (e.g., child can't be 0/0 if mother is 1/1)  

Useful for hetero/iso-uniparental disomy (UPD) detection, as an additional quality control, and to recognize sample swaps.  

### Parent mapping

'Parent mapping' is executed for every sample when at least one parent is available. Useful for hetero/iso-uniparental disomy (UPD) detection and to analyze whether aberrations are meiotic or mitotic.  

Variants of the child/embryo are distributed per parental origin. Dots above the chromosome bands represent informative variants of the father, while dots below represent informative variants of the mother. The top and bottom tracks per parental origin represent variants for which the embryo is heterozygous and homozygous, respectively.  

## Filter 2: filter 0, filer 1, --keep.informative.ids and --keep.hetero.ids

### Variant statistics

Similar to previous 'Variant statistics' sections, but ADO/ADI is not calculated.

### Haplotyping by Merlin

Merlin is executed if more than one sample is provided in `--sample.ids`, and `--run.merlin T` is given.  

Different haplotypes are given by colors. Haplotypes are relative between individuals/strands within a family (i.e., same-haplotype colors are not constant between HTML output files). Details at each variant can be obtained by mouse hovering.  

*Note 1*: 'raw' haplotypes from Merlin can be corrected using `--window.size.voting`. At each variant (e.g., variant X), haplotypes (e.g., haplotype A) can be 'corrected' in accordance to their neighbourhood, defined by argument `--window.size.voting`. The algorithm we created is dubbed 'weighted neighbourhood voting': the closer variant Y (with, e.g., haplotype B; located in the neighbourhood) is to the current variant X, the more votes (for haplotype B) variant Y has to influence the haplotype of variant X. All votes (for haplotype A and B) within the neighbourhood of X are summed; variant X is given the winning haplotype. The number of votes each variant has to influence the haplotype of variant X is proportional to: [((`--window.size.voting`) / (distance to variant X + `--window.size.voting`/2)) - 1]; this way, variants with a negative number of votes lay beyound the bounds of the neighbourhood defined by `--window.size.voting`, and are ignored. Corrected haplotypes are shown using a circle symbol. The raw uncorrected genotyping data can be consulted at any time by mouse hovering.  

*Note 2*: haplotypes from Merlin can be further corrected using `--min.seg.var`. A haplotype stretch needs to have at least `--min.seg.var` variants. If not, the haplotype segment is corrected to its neighbouring haplotype segments. Corrected haplotypes are shown using a circle symbol (instead of squares). The raw uncorrected genotyping data can be consulted at any time by mouse hovering.  

*Note 3*: There is no haplotyping executed when the given family structure does not allow it (i.e., when no reference sample is provided, there will be no breakpoints in the haplotyping strands).  

*Note 4*: When the raw genotype is 'NA', it has been removed by soft filtering, as explained in the [Arguments](#Arguments), and no symbol is shown.  

### Haplotyping by Merlin: strand concordance

If `--concordance.table T` is set, the concordance in haplotyping patterns between strands of different family members is shown in form of a pairwise comparative table. The concordance per strand is calculated as [(same-haplotype variants between strands)/(total number of evaluated variants)].
