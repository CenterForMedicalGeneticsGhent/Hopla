# HTML output

The analysis writes an interactive HTML file (`{family.id}-output.html`). Hovering,
dragging, and related Plotly controls manipulate the figures, and raw data can
often be inspected. Pass `--export-parquet` and `--export-bigwig` to also write
portable Parquet tables and IGV desktop tracks under `{family.id}-export/`; see
[exports.md](exports.md).

The report is always a single offline document: packaged `report.css`,
`report.js`, and plotly.js basic are inlined, analysis tables are serialized
column-wise and gzip-compressed inside the HTML, and the browser expands them
with `DecompressionStream` before drawing. A contents list at the top links to
each `h2` and `h3` section. Figures are built in the browser from that single
payload and drawn only when they scroll into view. The file requires JavaScript
and a current browser with `DecompressionStream` support. Report size still
grows with the number of samples and plotted variants. Restrict `baf_ids`,
enable `limit_baf_to_p` or `limit_pm_to_p`, and use the haplotyping region
controls when further reduction is needed.

Output names use `family.id` (default `hopla`). Haplotyping colours are relative
within a family: the same haplotype colour is not stable across different HTML
files.

Deliberate report differences from earlier Hopla HTML layouts:

- genotype-count and haplotype-concordance grids are HTML tables rather than
  Plotly tables
- every panel is drawn as SVG rather than WebGL, because browsers cap the
  number of simultaneous WebGL contexts well below the panel count
- `limit_baf_to_p` / `limit_pm_to_p` subsample with a deterministic stride
  instead of randomly
- VCF-based copy-number segmentation uses a deterministic recursive
  circular-binary-segmentation change statistic

## Family/disease information

Text supplied by `info` is printed at the top of the HTML. Line breaks are
preserved. The text is not interpreted as key-value pairs.

## Family tree

If two or more samples are provided, the family structure is shown as defined
by `family.members` and each member's `father` and `mother`. Annotations follow
`reference_ids`, `carrier_ids`, `affected_ids`, and `nonaffected_ids` (those
labels are reused throughout the HTML). Squares are males and circles are
females, from each member's `sex`, or from `x_cutoff` / `y_cutoff` when sex is
unknown. The pedigree is an inline SVG.

## Filter 0: single nucleotide variants

Tables and plots applied to all raw single nucleotide variants.

### Variant statistics

Includes variant tables, allelic drop-out (ADO) and allelic drop-in (ADI) for
every child/embryo, variant depth histograms, and a genome-wide
number-of-variants profile. Total counts use scopes as rows and samples as
columns. ADO and ADI use one row per sample. Both tables scroll horizontally
when a family is wider than the report.

- ADO uses variants that are `0/0` in the mother and `1/1` in the father, or
  vice versa: (homozygous variants in the child) / (total variants in the
  child).
- ADI uses variants that are `1/1` in both mother and father: (heterozygous
  variants in the child) / (total variants in the child).

Variant-depth histograms share bins and axis ranges across every sample in one
filter section. The upper edge is the pooled 99.5th depth percentile so an
extreme depth does not flatten the useful range; higher values are counted in
the final bin.

### VCF-based copy number

The quality of these copy-number profiles depends on how the VCF files were
generated. A BAM-based tool such as
[WisecondorX](https://github.com/CenterForMedicalGeneticsGhent/WisecondorX/)
is strongly recommended to verify copy number.

Windows without coverage have no finite log2 ratio. They are excluded from
segmentation and from IGV tracks, and are flagged as `mask = false` in the
portable `copy_number` table. Segments span across such gaps.

Every sample panel uses a fixed y-axis from -5 to +5. Windows whose
`|log2(ratio)|` is greater than 5 are drawn as red triangles on the
corresponding boundary; hover still shows the true value.

## Filter 1: filter 0 plus `dp_hard_limit`, `af_hard_limit`, and `dp_soft_limit`

Tables and plots applied to SNVs after those filters. See
[settings.md](settings.md) for how hard versus soft filters behave and how
default ID lists are derived.

### Variant statistics

Same kinds of tables and plots as filter 0.

### B-allele frequency (BAF), region(s) of interest

For each region in `regions`, a BAF profile is shown per sample.

### B-allele frequency (BAF), genome-wide

Genome-wide BAF profiles are included for samples in `baf_ids`. That option
increases HTML size substantially. `limit_baf_to_p` can deterministically
downsample genome-wide BAF to a fraction `value_of_p`.

### Mendelian errors

Mendelian errors are derived for every sample when at least one parent is
available. Per child/embryo:

- trio errors, when both parents are available (for example a child cannot be
  `0/0` if the parents are `1/1` and `0/1`)
- father errors, checking only the father–child relation (or the only available
  parent relation) from homozygous inheritance (for example a child cannot be
  `0/0` if the father is `1/1`)
- mother errors, likewise for the mother

Useful for hetero/iso-uniparental disomy (UPD) detection, extra quality
control, and spotting sample swaps.

### Parent mapping

Parent mapping runs for every sample when at least one parent is available. It
helps detect hetero/iso-UPD and whether aberrations look meiotic or mitotic.

Child/embryo variants are split by parental origin. Symbols above the
chromosome bands are informative paternal variants; symbols below are
informative maternal variants. For each parent, the top track is heterozygous
in the embryo and the bottom track is homozygous. `limit_pm_to_p` can
deterministically downsample these profiles to a fraction `value_of_p`.

## Filter 2: filter 0, filter 1, `keep_informative_ids`, and `keep_hetero_ids`

### Variant statistics

Same kinds of tables and plots as earlier variant-statistics sections, except
ADO/ADI is not calculated.

### Haplotyping by Merlin

Merlin runs when more than one real sample is in `family.members`, `run_merlin` is
`true`, and the `merlin` / `minx` executables are on `$PATH`. There is no
haplotyping when the family structure does not allow it (no reference sample
means no breakpoints in the haplotyping strands).

Merlin refuses chromosomes whose pedigree complexity exceeds its built-in
24-bit limit, scored as `2 x descendants - founders`. A family with two parents
and fourteen children scores 26 bits, so Merlin skips every autosome and only
chromosome X is haplotyped, because `minx` treats males as hemizygous and
scores the same family lower. Hopla logs a warning naming the skipped
chromosomes and still writes the report; those chromosomes simply have no
haplotype panel.

Haplotypes are coloured. Colours are relative between individuals and strands
within a family. Hover a variant for details.

**Weighted neighbourhood voting (`window_size_voting`).** Raw Merlin haplotypes
can be corrected by neighbourhood voting. At each variant X, nearby variants
vote on the haplotype. A neighbour at distance `d` contributes

`window_size_voting / (d + window_size_voting / 2) - 1`

votes. Neighbours with a negative weight lie outside the window and are
ignored. Closer neighbours influence X more. The winning haplotype is assigned
to X. Set the window to `0` to disable. Chromosome X can use
`window_size_voting_x` (default: the autosome window).

**Minimum segment size (`min_seg_var`).** A same-haplotype stretch must contain
at least `min_seg_var` variants; otherwise it is corrected to neighbouring
segments. Set to `0` to disable. Chromosome X can use `min_seg_var_x` (default
`15`).

Corrected haplotypes are drawn as circles instead of squares. Raw uncorrected
genotypes remain available on hover.

When the raw genotype is `NA`, it was removed by soft filtering and no symbol
is shown. Male chromosome X is hemizygous and is therefore drawn as one
haplotype strand. The absent second minx strand is retained as `X` in portable
tables and compatibility flow files, but is not drawn.

`keep_chromosomes_only` (default `true`) drops raw haplotyping points except
complete chromosomes that contain the region(s) of interest.
`keep_regions_only` (default `false`) keeps only the regions. Both shrink the
HTML.

### Haplotyping by Merlin: strand concordance

If `concordance_table` is `true`, a pairwise HTML table compares haplotyping
patterns between strands of different family members. Concordance per strand is
(same-haplotype variants between strands) / (total evaluated variants). The
absent `X` sentinel strand is ignored. The
`concordance` subtool can compare two flow tables the same way, including a
relative (`-r`) mode.
