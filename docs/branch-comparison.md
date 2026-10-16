# Comparison between `main` (R engine) and `3.0.0` (Python engine)

This document compares the legacy R pipeline on the `main` branch (`hopla.R`, `concordance.R`, `transform.R`) with the Python package on the `3.0.0` branch (`src/hopla/`). In particular, it explains why `main` reports fewer variants than `3.0.0` on identical VCF inputs, and summarizes all behavioral and architectural differences across the pipeline stages.

---

## 1. Why `main` reports fewer variants than `3.0.0`

Three differences in VCF ingestion and chromosome retention cause `3.0.0` to retain and count more variants than `main`.

### 1.1 VCF `FILTER == "PASS"` enforcement (primary cause)

On `main` (introduced in commit `d6997a4` / merge `0b1c871`), `load.samples` in `hopla.R` restricts retained sites to records whose VCF `FILTER` column is literally `"PASS"`:

```r
# main: hopla.R (lines 307-310)
snp.mask <- nchar(vcf.A$REF) == 1 &
            nchar(vcf.A$ALT) == 1 &
            vcf.A$CHROM %in% c(chrs, 'chrY') &
            vcf.A$FILTER == "PASS"
```

In `vcfR`, an unannotated VCF `FILTER` entry (`.` in the VCF text) is parsed as `NA`, so `vcf.A$FILTER == "PASS"` evaluates to `NA` and is excluded by `which(snp.mask)`. Any record with `FILTER` set to `.` or to a soft-filter tag (for example `LowQual`, `VQSRTrancheSNP...`, or `PASS;...`) is dropped before Filter 0 on `main`.

On `3.0.0`, `_collect_variants` in `src/hopla/vcf.py` does not inspect `variant.FILTER`:

```python
# 3.0.0: src/hopla/vcf.py (lines 142-146)
for variant in variants:
    chrom = _canonical_chrom(variant.CHROM)
    alt = variant.ALT[0] if len(variant.ALT) == 1 else ""
    if chrom is None or len(variant.REF) != 1 or len(alt) != 1:
        continue
```

Every biallelic SNV on `chr1`–`chr22`, `chrX`, and `chrY` is loaded into `SiteTable` regardless of its `FILTER` status. Consequently, any VCF containing unfiltered (`.`) or non-`PASS` SNVs yields higher variant counts on `3.0.0` at Filter 0, Filter 1, and Filter 2.

### 1.2 Retention of `chrY` after sex prediction (secondary cause)

Both branches load `chrY` variants initially so sex prediction can compute coverage on the non-recombining Y interval (`chrY:11,700,002–21,799,999`).

On `main`, immediately after `predict.genders`, `hopla.R` strips `chrY` from all sample tables before Filter 0 statistics, Filter 1, and Filter 2 run:

```r
# main: hopla.R (lines 2224-2226)
if (any(is.na(args$genders))) args$genders <- predict.genders(args$genders)

vcfs <- lapply(vcfs, function(x) x[vcfs[[1]]$CHROM %in% chrs,])
```

Because `chrs` is `paste0('chr', c(1:22, 'X'))`, `chrY` variants are excluded from all reported totals and downstream analyses on `main`.

On `3.0.0`, `CHROMOSOME_CODES` in `src/hopla/models.py` maps `chrY` to code `24`, and `src/hopla/pipeline.py` keeps `chrY` sites in `SiteTable` and `GenotypeMatrix` after `predict_sexes`. As a result, `chrY` SNVs are included in:

- **Filter 0 and Filter 1**: genome-wide variant totals (`variant_statistics`), genotype count and pairwise genotype tables (`genotype_counts`, `genotype_pair_counts`), ADO/ADI calculations (`ado_adi`), depth histograms (`variant_depth_table`), and internal BAF / Mendelian / parent-mapping / copy-number window tables (though chromosome-iterated plots only render `CHROMOSOMES` = `chr1`–`chr22`, `chrX`).
- **Filter 2**: `chrY` sites can survive `apply_filter2` when `keep_informative_ids` or `keep_hetero_ids` are satisfied on `chrY` (or left empty), whereas `apply_filter2` only masks non-heterozygous calls on autosomes (`selected_chrom[site_keep] <= 22`) and `run_merlin` explicitly selects `sites.chrom <= 22` and `sites.chrom == 23`.

### 1.3 Chromosome prefix normalization per record vs first record

- **`main` (`hopla.R` line 300)**: Checks only the first row of the VCF (`if (substr(vcf.A$CHROM[1], 1, 3) != 'chr') vcf.A$CHROM <- paste0('chr', vcf.A$CHROM)`).
- **`3.0.0` (`src/hopla/vcf.py` lines 95–99)**: Normalizes every record individually via `_canonical_chrom(variant.CHROM)`.

---

## 2. Stage-by-stage pipeline comparison

### 2.1 VCF loading, genotypes, and allele fraction

| Aspect | `main` (`hopla.R`) | `3.0.0` (`src/hopla/vcf.py`, `models.py`) |
| --- | --- | --- |
| Reader library | `vcfR::read.vcfR` (in-memory R data frames per sample) | `cyvcf2.VCF` (streaming into shared `SiteTable` + `GenotypeMatrix`; multi-process per contig when tabix/CSI indexed) |
| Biallelic SNV check | `nchar(REF) == 1 & nchar(ALT) == 1` (multi-allelic comma-joined `ALT` strings have `nchar > 1`) | `len(variant.REF) == 1 and len(variant.ALT) == 1 and len(variant.ALT[0]) == 1` |
| `FILTER` column check | Requires `FILTER == "PASS"` | None (all `FILTER` values accepted) |
| Contigs retained in memory | `chr1`–`chr22`, `chrX` (`chrY` dropped after `predict.genders`) | `chr1`–`chr22`, `chrX`, `chrY` (`chrY` retained in `SiteTable`) |
| Genotype encoding | Strings `'0/0'`, `'0/1'`, `'1/1'`, `'./.'`; phased `'1|0'` normalized via `gsub('|', '/')` (`'1/0'` is not matched by `GT == '0/1'` in R) | `int8` allele dosage `0`, `1`, `2`, or `-1` (missing); phased `1|0` and unphased `0/1` both sum to `1` |
| Haploid `chrX` calls | `'0'` $\rightarrow$ `'0/0'`, `'1'` $\rightarrow$ `'1/1'` | Ploidy-1 calls on `chrX` doubled (`0` $\rightarrow$ `0`, `1` $\rightarrow$ `2`) |
| Male `chrX` heterozygotes | Set to `'./.'` for male samples (`DP` and `AF` untouched) | `mask_male_x_heterozygotes` sets `gt = -1` (`dp` and `ad` untouched) |
| Depth (`DP`) and `AD` | `DP` parsed as numeric (`NA` $\rightarrow$ `0`); `AD` overwritten with `sum(AD)` | `dp`, `ad_ref`, `ad_alt` clamped to `uint16` (`0..65535`); negative/missing values set to `0` |
| Allele fraction (`AF`) | `round(AD[2] / sum(AD), 3)` (`float64`) | `np.round(ad_alt / (ad_ref + ad_alt), 3)` (`float32`) |

> [!NOTE]
> Phased heterozygotes written as `1|0` in the VCF become `'1/0'` in `main` (`gsub('|', '/', vcf.B$GT)`), which fails `GT == '0/1'` checks in `hopla.R` and gets treated as `'N/N'` / uncalled. In `3.0.0`, `_decode_genotypes` sums the two allele indices (`1 + 0 = 1`), properly retaining `1|0` as heterozygous.

### 2.2 Pedigree defaults and sex prediction

| Aspect | `main` (`hopla.R`) | `3.0.0` (`src/hopla/settings.py`, `pedigree.py`) |
| --- | --- | --- |
| Default `dp_hard_limit_ids` and `af_hard_limit_ids` | Non-terminal real samples in appearance order (`unique(c(mother.ids, father.ids))`) | Sorted non-terminal real sample IDs (`sorted(parents)`) |
| Default `dp_soft_limit_ids` | Terminal real samples in declaration order | Terminal real samples in declaration order |
| Sex prediction model | Compares `X.copies` (`< 1.5` $\rightarrow$ `M`) and `Y.copies` on `chrY:11,700,002–21,799,999` (`< 0.6` $\rightarrow$ `F`); defaults to `Y.model` when both exist | Identical coverage ratios and thresholds; uses `y_sex if y_sex is not None else x_sex` |
| Ghost parent insertion | Appends `U{n}` for members with exactly one known parent | Identical (`add_ghosts` in `src/hopla/pedigree.py`) |

### 2.3 Filter 1 and Filter 2

| Aspect | `main` (`hopla.R`) | `3.0.0` (`src/hopla/filters.py`) |
| --- | --- | --- |
| Filter 1 hard AF | Keeps site if any sample in `af.hard.limit.ids` has `AF >= af.hard.limit` (`na.rm = TRUE`) | `np.any(af[indices] >= settings.af_hard_limit, axis=0)` |
| Filter 1 hard DP | Keeps site if all samples in `dp.hard.limit.ids` have `DP >= dp.hard.limit` | `np.all(matrix.dp[indices] >= settings.dp_hard_limit, axis=0)` |
| Filter 1 soft DP | For samples in `dp.soft.limit.ids` with `DP < dp.soft.limit`, sets `GT = './.'`, `AF = NA`, `DP = NA` | Sets `gt = -1`, `dp = np.nan`, `af = np.nan` |
| Filter 2 informative | For 2 samples in `keep.informative.ids`, keeps sites where one is `0/1` and the other is `0/0` or `1/1` (bypassed on `chrX` if both are male) | Identical (`apply_filter2` in `src/hopla/filters.py`) |
| Filter 2 hetero | Keeps sites where any sample in `keep.hetero.ids` is `0/1` (always true on `chrX`); then masks autosomal `0/0` and `1/1` calls in those samples to missing (`GT = './.'`, `AF = NA`, `DP = NA`) | Identical (`apply_filter2` masks `gt[index, (gt[index] != 1) & autosomal] = -1`, plus `dp` and `af` to `NaN`) |

### 2.4 Downstream analyses

1. **Variant statistics and regional flank boundaries (`src/hopla/analysis.py` vs `hopla.R`)**:
   - Both count called genotypes (`0/0`, `0/1`, `1/1`) genome-wide and per region (`[start, end]`, left flank `[start - flank, start]`, right flank `[end, end + flank]`).
   - Region BAF plots (`get.region.baf` in `hopla.R` line 1646 and `BUILD.rbaf` in `src/hopla/report.js` line 241) use strict inequalities (`pos > from && pos < to`).
2. **Variant density windows (`variant_density_table` vs `get.var.dis.fig`)**:
   - `main` bins site positions from `vcf.list[[1]]$POS` using `hist(..., breaks = seq(1, max_pos + window.size, window.size))`. Because `vcf.list[[1]]$POS` is identical across all samples (soft-masked sites keep their row in `vcf.list`, only changing `GT` to `'./.'`), `main` counts **all sites passing the site mask** in each window rather than per-sample called genotypes.
   - `3.0.0` groups by `((pos - 1) // window_size) * window_size + 1` and sums `called = calls[sample_index] >= 0` per sample (`report.js` plots `M.samples[0]`). If `M.samples[0]` has missing calls or soft-DP masked genotypes, `3.0.0` counts only called genotypes in `M.samples[0]`, and omits windows that contain zero sites.
3. **Variant depth histograms (`variant_depth_table` vs `get.var.depth.hist`)**:
   - `main` passes raw non-zero depths (`DP != 0 & !is.na(DP)`) to Plotly's client-side `type = "histogram"` auto-binner.
   - `3.0.0` pre-bins non-zero depths in Python using shared bin edges across samples capped at the 99.5th percentile (`_depth_bin_edges`).
4. **Copy number estimation and segmentation (`copy_number_table` vs `get.cn.fig`)**:
   - `main` clusters adjacent SNVs within 200 bp (`cluster.max.len.between.CpG = 200`), computes mean summed `AD` (`vcf$AD[var.mask]`) per cluster among called genotypes (`GT != './.'`), averages cluster depths per genomic window, fits a linear regression `lm(sd.depth ~ mean.depth)` to mask out windows in the bottom 5% of cluster count or outer 5%/95% of regression residuals, and runs `DNAcopy::segment` (weighted permutation-based CBS).
   - `3.0.0` computes window mean `matrix.dp` directly across all sites in each window (without 200 bp sub-clustering, `GT != './.'` filtering, or residual quantile masking), normalizes by the sample's median window depth, and segments chromosomes using a deterministic recursive CBS t-statistic (`_cbs_boundaries`, threshold `3.0`, minimum 6 windows).
5. **Mendelian errors (`mendelian_table` vs `get.men.err.fig`)**:
   - Identical trio and duo error rules on Filter 1 genotypes.
   - `main` builds a complete grid of sliding windows up to `max(POS)` per chromosome (including zero-error windows and children with zero errors); `3.0.0` emits rows only for children that have at least one Mendelian error and windows that contain variants.
6. **Parent mapping (`parent_mapping_table` vs `get.pm`)**:
   - For a two-parent child, both classify paternal (`father == 0/1 & mother in {0/0, 1/1}`) and maternal (`mother == 0/1 & father in {0/0, 1/1}`) informative sites by child zygosity (`0/1` vs `0/0|1/1`).
   - For a single-parent child (before ghost addition or if one parent is not in the VCF), `main` plots all four tracks (`father 0/1` on tracks 5/4 and `father 0/0|1/1` on tracks 2/1, or `mother 0/0|1/1` on tracks 5/4 and `mother 0/1` on tracks 2/1). In `3.0.0`, `parent_mapping_table` only emits `"father"` (`father_gt == 1`) when only the father is in `matrix.sample_index`, or only `"mother"` (`mother_gt == 1`) when only the mother is in `matrix.sample_index`.
   - When `limit_baf_to_p` or `limit_pm_to_p` is enabled, `main` subsamples randomly (`sample()`), whereas `3.0.0` subsamples deterministically in `src/hopla/report.js` (`thin()`).
7. **Merlin haplotyping and flow tables (`src/hopla/merlin.py` vs `hopla.R`)**:
   - Both run `merlin` (autosomes) and `minx` (`chrX`) with `--error`, remove markers listed in `.err`, rerun with `--best` or `--sample`, drop markers where all samples are `NA`, mask uncalled genotypes (`N/N`) back to `NA`, and apply short-segment correction (`min_seg_var` / `min_seg_var_x`) followed by distance-weighted voting (`window_size_voting` / `window_size_voting_x`).
   - In `main`, `update.geno` overwrites Merlin's imputed genotypes back to `NA|NA` (or `NA|X`) whenever the sample's Filter 2 input genotype was `'N/N'` *before* running `correct.profiles`. In `3.0.0`, `_parse_blocks` parses Merlin's `.chr` output (where Merlin only prints `?` when it cannot impute an allele), and `run_merlin` does not mask sites that were `-1` in `filtered2.gt` back to `"NA"`. Because `correct_short_segments` counts `genotypes != "NA"` and the report plots markers where `genotype != "NA"`, `3.0.0` retains Merlin-imputed alleles at missing input sites whereas `main` masks them back to `NA`.
   - `main` writes both `{sample}-geno.txt` and `{sample}-flow.txt` in `{fam.id}-merlin/`; `3.0.0` writes `{sample}-flow.txt`.
8. **Report rendering and CLI (`src/hopla/report.py`, `cli.py` vs `hopla.R`)**:
   - `main` uses R `htmltools::save_html` + `plotly` widgets and optionally shells out to Pandoc (`--self.contained T`).
   - `3.0.0` produces a single self-contained HTML report with no Pandoc dependency, inlining `report.css`, `report.js`, and `plotly-basic.min.js` alongside a single gzip+base64 JSON payload rendered lazily via `IntersectionObserver`.
   - `3.0.0` replaces the CLI and Vue 2 settings UI with `hopla run`, `hopla convert`, `hopla concordance`, `hopla transform`, and `hopla serve`, plus optional `--export-parquet` and `--export-bigwig` sidecar exporters.
