# Portable analysis exports

`hopla run` writes `{family.id}-export/` by default. Use
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

## IGV tracks

By default, the same export directory also contains:

- one `{sample}-baf.bw` track per sample;
- normalized copy-number and Mendelian-error BigWigs when data exists;
- `copy-number.seg` for segmented copy number;
- BED files for categorical parent mapping and Merlin haplotypes; and
- `igv-session.xml`, which references those sibling files relatively.

Open the session with IGV desktop against hg38. BigWig coordinates are
converted to zero-based half-open intervals internally, while the Parquet
tables retain their documented one-based inclusive coordinates. Disable track
generation with `--no-export-bigwig`.
