# Portable analysis exports

`hopla run` writes `{fam_id}-export/` by default. Use
`--no-export-parquet` when only the HTML report is needed.

Each visualized dataset is stored in its own Apache Parquet file with zstd
compression. `manifest.json` records the genome, coordinate convention, row
counts, physical column types, and column descriptions. These files are
language-independent and can be opened with Arrow, DuckDB, R, Julia, Java,
Spark, Polars, or pandas.

Coordinates are hg38, one-based, and inclusive. BAF values are fractions from
zero through one; copy-number values are normalized log2 ratios. The export
contains the full series before display downsampling. It intentionally does
not duplicate the input VCF.
