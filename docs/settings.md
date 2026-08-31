# Hopla settings

[Documentation home](README.md) · [CLI](cli.md) · [Output](output.md)

Analysis options are supplied as a single YAML or JSON file to `hopla run`.
The file is validated against the packaged `hopla/schema/hopla.schema.json`
before the VCF is loaded. Unknown properties are ignored after a warning.
Invalid types, missing mandatory values, and out-of-range values fail
immediately. After schema validation, the
engine applies pedigree length checks, sample-reference checks, region pattern
checks, and filter-ID defaults.

The optional [`hopla serve`](serve.md) editor can help assemble that file, but
it is not required. Settings can be created and edited by hand. The editor is
intended as a local, short-lived helper rather than a standing service.

Command-line flags do not override individual analysis options. Paths for the
VCF, output directory, and cytoband table are CLI arguments, not settings
properties. Portable Parquet and IGV exports are controlled by CLI flags; see
[cli.md](cli.md) and [exports.md](exports.md).

```bash
pixi run hopla run path/to/settings.yaml path/to/family.vcf.gz
pixi run hopla run -o path/to/output path/to/settings.yaml path/to/family.vcf.gz
pixi run hopla run -c path/to/cytoband.hg38.txt path/to/settings.yaml path/to/family.vcf.gz
hopla run path/to/settings.json path/to/family.vcf.gz
```

Supplied paths must already exist. `-o OUT_DIR` defaults to the current working
directory (`$PWD`).

A complete example is [`example/settings.yaml`](../example/settings.yaml).

## Format

- Use a `.yaml`, `.yml`, or `.json` extension.
- The document root must be a mapping of snake_case property names.
- Lists must be YAML/JSON arrays, not comma-separated strings.
- Use `null` for an unknown parent or sex. Do not use `NA`.
- Omitted properties take the defaults below (also encoded in the schema and
  analysis engine).
- Empty arrays are allowed where the schema permits them; they mean “unset” for
  optional ID lists.
- Boolean values are `true` / `false`.
- `regions` entries must match `chrNAME:start-end` (for example
  `chr7:117480025-117668665`).
- `keep_informative_ids` accepts at most two sample IDs, and when set must
  contain exactly two.

```yaml
family:
  id: example
  members:
    - {id: sample_C, sex: M}
    - {id: sample_B, sex: F}
    - {id: sample_A, father: sample_C, mother: sample_B}
run_merlin: true
regions:
  - chr7:117480025-117668665
info: |
  Disease: Cystic Fibrosis
  Inheritance: Autosomal Recessive
```

Equivalent JSON is accepted. Types and constraints are identical.

Files using the former parallel `sample_ids`, `father_ids`, `mother_ids`,
`sexes`, and `fam_id` properties are remapped when loaded. New and generated
configurations use `family`; if both representations are present, `family`
wins and the parallel properties are ignored with a warning.

## Mandatory settings

- **`family`** (`object`) Family description containing a `members` array and
  optional `id`.
- **`family.members`** (`object` array) Samples and pedigree members. Every
  member requires a unique, non-empty `id`. VCF-backed IDs must be present in
  the VCF given on the CLI. Missing pedigree members can use IDs `U1`, `U2`, …;
  IDs matching `U[0-9]+` are pedigree ghosts and are not loaded from the VCF.
  A member can name its `father` and `mother` by ID, independent of where either
  member appears in the array.

The VCF file is the `VCF` operand to `hopla run`. The output directory is
optional `-o OUT_DIR` (default `$PWD`) and the cytoband table is optional
`-c CYTOBAND`. Supplied paths are checked for existence before analysis starts.
The engine does not create a missing output directory.

When more than one member is listed, at least one member must name a non-null
`father` or `mother`.

## Optional settings

### Important optional settings

- **`family.id`** (`string`, default `hopla`) Family ID used in output file
  names. Non-word characters are replaced with `.` after load.
- **`family.members[].father`** / **`family.members[].mother`**
  (`string | null`, default `null`) Parent IDs. A named parent must be another
  member of the same family.
- **`family.members[].sex`** (`M` / `F` / `null`, default `null`) Sample sex.
  When omitted or `null`, the model predicts sex (see `x_cutoff` and
  `y_cutoff`).
- **`run_merlin`** (`boolean`, default `true`) Whether Merlin haplotyping should
  run through the in-process `merlinpy` package. The engine forces
  `run_merlin` to `false` when only one real (non-ghost) sample is present or
  `merlinpy` is unavailable.

The cytoband table is a CLI path (`-c CYTOBAND`), not a settings property. See
[cli.md](cli.md).

Omitted `father`, `mother`, and `sex` properties are treated as `null`.

### Important optional variant inclusion settings: filter 1

- Every sample in **`dp_hard_limit_ids`** (`string` array, default all but last
  line children/embryos from `family.members`) should have variants with coverage
  of at least **`dp_hard_limit`** (`number ≥ 0`, default `10`). This is a hard
  filter: variants that do not comply are removed from all samples.
- At least one sample in **`af_hard_limit_ids`** (`string` array, default all
  but last line children/embryos from `family.members`) should have variants with
  an allele fraction of at least **`af_hard_limit`** (`number` in `[0, 1)`,
  default `0`). This is a hard filter: variants that do not comply are removed
  from all samples.
- Variants from samples in **`dp_soft_limit_ids`** (`string` array, default last
  line children/embryos from `family.members`) should have coverage of at least
  **`dp_soft_limit`** (`number ≥ 0`, default `10`). This is a soft filter:
  variants that do not comply are removed from the given samples only.

The ID-list defaults are derived after the pedigree is resolved: “last line”
samples are those that are not used as a father or mother of another analyzed
real sample. For a single-sample analysis, the hard and soft ID defaults both
cover that sample.

### Important optional variant inclusion settings: filter 2

- **`keep_informative_ids`** (`string` array, at most 2, no default) Keep only
  variants that are `0/1` in sample 1 and `0/0` or `1/1` in sample 2, and vice
  versa. Effective when exactly two samples are given. In a classic trio this
  corresponds to the parents. Example: `[sample_C, sample_B]`. When present,
  the list must contain exactly two IDs.
- **`keep_hetero_ids`** (`string` array, no default) Keep only variants that are
  `0/1` in at least one of the given samples. Effective when one or more samples
  are given. A soft filter excludes `0/0` and `1/1` variants. Applies only to
  autosomes. In a classic setting this corresponds to children/embryos.
  Example: `[sample_A]`.

### Sample/disease annotation

- **`regions`** (`string` array, no default) Region(s) of interest as
  `chr:start-end` in base pairs. When given, regions are marked throughout the
  output, detailed B-allele frequency (BAF) profiles are generated, and
  corresponding raw data is kept. Example: `[chr7:117480025-117668665]`.
- **`reference_ids`** (`string` array, no default) When given, the family tree
  and sample names are colored/annotated accordingly. None or more expected.
- **`carrier_ids`** (`string` array, no default) When given, the family tree and
  sample names are colored/annotated accordingly. None or more expected.
- **`affected_ids`** (`string` array, no default) When given, the family tree
  and sample names are colored/annotated accordingly. None or more expected.
- **`nonaffected_ids`** (`string` array, no default) When given, the family tree
  and sample names are colored/annotated accordingly. None or more expected.
- **`info`** (`string`, no default) Free text printed at the top of the HTML
  output. Line breaks are preserved. The value is not parsed as key-value
  pairs.

  ```yaml
  info: |
    Some information.
    Disease: Cystic Fibrosis
    Inheritance: Autosomal Recessive
    Some more information.
  ```

### B-allele frequency (BAF) profiles

- **`baf_ids`** (`string` array, no default) BAF profiles are generated for the
  region(s) of interest for all samples. Include samples here if a genome-wide
  BAF profile is desired. Example: `[sample_B, sample_C]`. **Warning:** this
  increases the HTML size significantly, which can reduce usability.

### Merlin haplotyping profiles

- **`merlin_model`** (`sample` or `best`, default `best`) Underlying
  [Merlin haplotyping
  model](http://csg.sph.umich.edu/abecasis/merlin/tour/haplotyping.html).
  `merlinpy` currently supports `sample` only for zero-bit families and raises
  an error for informative pedigrees; use the default `best` for those
  families.
- **`min_seg_var`** (`number ≥ 0`, default `5`) Minimum number of variants in a
  same-haplotype segment. Segments that do not comply are corrected to the
  neighbouring haplotype. Corrected haplotypes use a circle symbol. Set to `0`
  to disable.
- **`min_seg_var_x`** (`number ≥ 0`, default `15`) `min_seg_var` for chromosome
  X.
- **`window_size_voting`** (`number ≥ 0`, default `10000000`) Size in bp used to
  correct haplotypes by weighted neighbourhood voting. Corrected haplotypes use
  a circle symbol. Set to `0` to disable.
- **`window_size_voting_x`** (`number ≥ 0`, default `window_size_voting`)
  `window_size_voting` for chromosome X. If omitted, the autosome value is
  reused after settings are loaded.
- **`keep_chromosomes_only`** (`boolean`, default `true`) Whether raw data
  points in haplotyping profiles should be omitted except for the complete
  chromosomes that contain the region(s) of interest. Significantly lowers HTML
  size.
- **`keep_regions_only`** (`boolean`, default `false`) Whether raw data points
  in haplotyping profiles should be omitted except for the region(s) of
  interest. Significantly lowers HTML size.
- **`concordance_table`** (`boolean`, default `true`) Whether a haplotyping
  strand-wise concordance table should be added. Useful for validation.

Weighted neighbourhood voting: at each variant X, nearby variants vote on the
haplotype. A neighbour at distance `d` contributes

`window_size_voting / (d + window_size_voting / 2) - 1`

votes. Neighbours with a negative weight lie outside the window and are
ignored. The closer a neighbour is, the more it influences variant X. The
winning haplotype is assigned to X. Corrected haplotypes are drawn as circles;
raw uncorrected genotypes remain available on hover.

### Remaining features

- **`x_cutoff`** (`number`, default `1.5`) X chromosome copy-number cutoff for
  sex prediction (one copy assumed in males, two in females).
- **`y_cutoff`** (`number`, default `0.6`) Y chromosome copy-number cutoff for
  sex prediction (one copy assumed in males, noise expected in females).
- **`window_size`** (`number > 0`, default `1000000`) Bin size in bp for several
  genome-wide profiles.
- **`regions_flanking_size`** (`number ≥ 0`, default `2000000`) Flanking size in
  bp used to mark region(s) of interest.
- **`limit_baf_to_p`** (`boolean`, default `false`) Whether genome-wide BAF
  profiles should be subsampled to include only a fraction `P` of the data.
  Significantly lowers HTML size. Subsampling is deterministic (fixed stride),
  not random.
- **`limit_pm_to_p`** (`boolean`, default `false`) Whether parent-mapping
  profiles should be subsampled to include only a fraction `P` of the data.
  Significantly lowers HTML size. Subsampling is deterministic (fixed stride),
  not random.
- **`value_of_p`** (`number` in `(0, 1]`, default `0.25`) Value of `P` for the
  two options above.
- **`dot_factor`** (`number > 0`, default `2`) Multiplier for the size of every
  dot in the visualizations.

The report is always a single offline HTML file: local `plotly.js` is inlined
and analysis data is gzip-compressed for the browser to expand before
rendering. The report requires JavaScript and a current browser with
`DecompressionStream` support. Hopla does not invoke Pandoc. Unused historical
keys (`color_palette`, `self_contained`, `cairo`) are ignored with a warning
and are not written when generating YAML.

## Legacy `key=value` files

The historical settings format (`argument=value`, `#` comments, and a
`start.info` … `end.info` block) is no longer accepted by `hopla run`. Convert
it to validated YAML:

```bash
pixi run hopla convert path/to/legacy-settings.txt
pixi run hopla convert path/to/legacy-settings.txt path/to/settings.yaml
```

An example legacy file is
[`example/legacy-settings.txt`](../example/legacy-settings.txt).

Conversion rules:

- Dotted keys are mapped to snake_case schema properties
  (`min.seg.var.X` → `min_seg_var_x`).
- `vcf.file`, `out.dir`, and `cytoband.file` are omitted; pass those paths on
  the CLI instead.
- Empty assignments are omitted so schema/engine defaults apply.
- Comma-separated lists become YAML arrays.
- `NA` in parent and sex lists becomes YAML `null`.
- `T` / `F` become `true` / `false`.
- The converted document is validated before it is written.
- Unsupported keys are omitted after a warning. Missing mandatory fields fail
  the conversion.
- Legacy parallel pedigree fields are written as structured `family.members`.
  The `start.info` … `end.info` block becomes a multiline `info` string.

| Legacy key | YAML / JSON key |
| --- | --- |
| `vcf.file` | *(CLI `VCF` operand; omitted from YAML)* |
| `out.dir` | *(CLI `-o OUT_DIR`; omitted from YAML)* |
| `sample.ids` | `family.members[].id` |
| `father.ids` | `family.members[].father` |
| `mother.ids` | `family.members[].mother` |
| `genders` | `family.members[].sex` |
| `run.merlin` | `run_merlin` |
| `cytoband.file` | *(CLI `-c CYTOBAND`; omitted from YAML)* |
| `dp.hard.limit.ids` | `dp_hard_limit_ids` |
| `dp.hard.limit` | `dp_hard_limit` |
| `af.hard.limit.ids` | `af_hard_limit_ids` |
| `af.hard.limit` | `af_hard_limit` |
| `dp.soft.limit.ids` | `dp_soft_limit_ids` |
| `dp.soft.limit` | `dp_soft_limit` |
| `keep.informative.ids` | `keep_informative_ids` |
| `keep.hetero.ids` | `keep_hetero_ids` |
| `regions` | `regions` |
| `reference.ids` | `reference_ids` |
| `carrier.ids` | `carrier_ids` |
| `affected.ids` | `affected_ids` |
| `nonaffected.ids` | `nonaffected_ids` |
| `info` / `start.info`…`end.info` | `info` |
| `baf.ids` | `baf_ids` |
| `merlin.model` | `merlin_model` |
| `min.seg.var` | `min_seg_var` |
| `min.seg.var.X` | `min_seg_var_x` |
| `window.size.voting` | `window_size_voting` |
| `window.size.voting.X` | `window_size_voting_x` |
| `keep.chromosomes.only` | `keep_chromosomes_only` |
| `keep.regions.only` | `keep_regions_only` |
| `concordance.table` | `concordance_table` |
| `fam.id` / `fam.ID` | `family.id` |
| `X.cutoff` | `x_cutoff` |
| `Y.cutoff` | `y_cutoff` |
| `window.size` | `window_size` |
| `regions.flanking.size` | `regions_flanking_size` |
| `limit.baf.to.P` | `limit_baf_to_p` |
| `limit.pm.to.P` | `limit_pm_to_p` |
| `value.of.P` | `value_of_p` |
| `dot.factor` | `dot_factor` |
