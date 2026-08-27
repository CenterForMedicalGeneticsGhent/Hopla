# Python engine architecture

The Python engine is explicit and columnar:

1. `settings.py` validates YAML/JSON against the shared Hopla schema and derives
   pedigree defaults before VCF loading.
2. `vcf.py` streams selected biallelic SNVs with cyvcf2 into one `SiteTable`
   and compact sample-by-site NumPy matrices.
3. `filters.py`, `analysis.py`, and `merlin.py` operate on masks and matrices;
   they do not duplicate site columns per sample.
4. `report.py` serializes each result table by column, gzip-compresses the
   payload, and renders large numeric series on canvas.

All functions are typed and documented. Polars owns tabular joins and
aggregation; NumPy owns dense genotype operations. Merlin 1.1.2 remains an
external executable so its inference remains compatible with Hopla R.

## Compatibility

The Typer CLI preserves the existing `run`, `convert`, `concordance`, and
`transform` commands and status conventions. The report preserves analysis
sections and values, but not the old Plotly layout. Copy-number segmentation
uses a deterministic recursive circular-binary-segmentation change statistic
and is therefore not bit-identical to DNAcopy's permutation implementation.
