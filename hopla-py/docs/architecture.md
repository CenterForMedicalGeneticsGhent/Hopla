# Python engine architecture

The Python engine is explicit and columnar:

1. `settings.py` validates YAML/JSON against the shared Hopla schema and derives
   pedigree defaults before VCF loading.
2. `vcf.py` streams selected biallelic SNVs with cyvcf2 into one `SiteTable`
   and compact sample-by-site NumPy matrices.
3. `filters.py`, `analysis.py`, and `merlin.py` operate on masks and matrices;
   they do not duplicate site columns per sample.
4. `report.py` serializes each result table by column, gzip-compresses the
   payload, and inlines the offline `plotly.js` bundle once. Figures are built
   in the browser from that single payload and drawn only when they scroll into
   view, so the report keeps the original Plotly visuals without repeating the
   data per figure.

All functions are typed and documented. Polars owns tabular joins and
aggregation; NumPy owns dense genotype operations. Merlin 1.1.2 remains an
external executable so its inference remains compatible with Hopla R.

## Compatibility

The Typer CLI preserves the existing `run`, `convert`, `concordance`, and
`transform` commands and status conventions. The report reproduces the R
section order, figures, and palette. Two deliberate differences remain: the
count and concordance grids are HTML tables rather than Plotly tables, and
`limit_baf_to_p`/`limit_pm_to_p` subsample deterministically instead of
randomly. Every panel is drawn as SVG rather than WebGL, because browsers cap
the number of simultaneous WebGL contexts well below the panel count.
Copy-number segmentation
uses a deterministic recursive circular-binary-segmentation change statistic
and is therefore not bit-identical to DNAcopy's permutation implementation.
