# HTML output

The analysis writes an interactive HTML file. Hovering, dragging, and related Plotly controls manipulate the figures, and raw data can often be inspected. A partial toy example is [`example/hopla.html`](../example/hopla.html).

Output names use `fam_id` (default `hopla`). Haplotyping colours are relative within a family: the same haplotype colour is not stable across different HTML files.

## Family/disease information

Text supplied by `info` is printed at the top of the HTML.

## Family tree

If two or more samples are provided, the family structure is shown as defined by `sample_ids`, `father_ids`, and `mother_ids`. Annotations follow `reference_ids`, `carrier_ids`, `affected_ids`, and `nonaffected_ids` (those labels are reused throughout the HTML). Squares are males and circles are females, from `genders`, or from `x_cutoff` / `y_cutoff` when gender is unknown.

## Filter 0: single nucleotide variants

Tables and plots applied to all raw single nucleotide variants.

### Variant statistics

Includes variant tables, allelic drop-out (ADO) and allelic drop-in (ADI) for every child/embryo, variant depth histograms, and a genome-wide number-of-variants profile.

- ADO uses variants that are `0/0` in the mother and `1/1` in the father, or vice versa: (homozygous variants in the child) / (total variants in the child).
- ADI uses variants that are `1/1` in both mother and father: (heterozygous variants in the child) / (total variants in the child).

### VCF-based copy number

The quality of these copy-number profiles depends on how the VCF files were generated. A BAM-based tool such as [WisecondorX](https://github.com/CenterForMedicalGeneticsGhent/WisecondorX/) is strongly recommended to verify copy number.

## Filter 1: filter 0 plus `dp_hard_limit`, `af_hard_limit`, and `dp_soft_limit`

Tables and plots applied to SNVs after those filters. See [settings.md](settings.md) for how hard versus soft filters behave and how default ID lists are derived.

### Variant statistics

Same kinds of tables and plots as filter 0.

### B-allele frequency (BAF), region(s) of interest

For each region in `regions`, a BAF profile is shown per sample.

### B-allele frequency (BAF), genome-wide

Genome-wide BAF profiles are included for samples in `baf_ids`. That option increases HTML size substantially and can hit the maximum number of plots per file, which hides other plots. `limit_baf_to_p` can randomly downsample genome-wide BAF to a fraction `value_of_p`.

### Mendelian errors

Mendelian errors are derived for every sample when at least one parent is available. Per child/embryo:

- trio errors, when both parents are available (for example a child cannot be `0/0` if the parents are `1/1` and `0/1`)
- father errors, checking only the father–child relation (or the only available parent relation) from homozygous inheritance (for example a child cannot be `0/0` if the father is `1/1`)
- mother errors, likewise for the mother

Useful for hetero/iso-uniparental disomy (UPD) detection, extra quality control, and spotting sample swaps.

### Parent mapping

Parent mapping runs for every sample when at least one parent is available. It helps detect hetero/iso-UPD and whether aberrations look meiotic or mitotic.

Child/embryo variants are split by parental origin. Symbols above the chromosome bands are informative paternal variants; symbols below are informative maternal variants. For each parent, the top track is heterozygous in the embryo and the bottom track is homozygous. `limit_pm_to_p` can randomly downsample these profiles to a fraction `value_of_p`.

## Filter 2: filter 0, filter 1, `keep_informative_ids`, and `keep_hetero_ids`

### Variant statistics

Same kinds of tables and plots as earlier variant-statistics sections, except ADO/ADI is not calculated.

### Haplotyping by Merlin

Merlin runs when more than one sample is in `sample_ids` and `run_merlin` is `true`. There is no haplotyping when the family structure does not allow it (no reference sample means no breakpoints in the haplotyping strands).

Haplotypes are coloured. Colours are relative between individuals and strands within a family. Hover a variant for details.

**Weighted neighbourhood voting (`window_size_voting`).** Raw Merlin haplotypes can be corrected by neighbourhood voting. At each variant X, nearby variants vote on the haplotype. A neighbour at distance `d` contributes

`window_size_voting / (d + window_size_voting / 2) - 1`

votes. Neighbours with a negative weight lie outside the window and are ignored. Closer neighbours influence X more. The winning haplotype is assigned to X. Set the window to `0` to disable. Chromosome X can use `window_size_voting_x` (default: the autosome window).

**Minimum segment size (`min_seg_var`).** A same-haplotype stretch must contain at least `min_seg_var` variants; otherwise it is corrected to neighbouring segments. Set to `0` to disable. Chromosome X can use `min_seg_var_x` (default `15`; if omitted after load, the autosome value is reused).

Corrected haplotypes are drawn as circles instead of squares. Raw uncorrected genotypes remain available on hover.

When the raw genotype is `NA`, it was removed by soft filtering and no symbol is shown.

`keep_chromosomes_only` (default `true`) drops raw haplotyping points except complete chromosomes that contain the region(s) of interest. `keep_regions_only` (default `false`) keeps only the regions. Both shrink the HTML.

### Haplotyping by Merlin: strand concordance

If `concordance_table` is `true`, a pairwise table compares haplotyping patterns between strands of different family members. Concordance per strand is (same-haplotype variants between strands) / (total evaluated variants). The `concordance` subtool can compare two flow tables the same way, including a relative (`-r`) mode.
