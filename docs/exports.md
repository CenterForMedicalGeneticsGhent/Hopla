# Portable analysis exports

Pass `--export-parquet` so `hopla run` writes `{family.id}-export/`. The HTML
report is still written when the flag is omitted.

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

Pass `--export-bigwig` to write IGV desktop tracks in the same export
directory:

- one `{sample}-baf.bw` track per sample;
- normalized copy-number and Mendelian-error BigWigs when data exists;
- `copy-number.seg` for segmented copy number;
- BED files for categorical parent mapping and Merlin haplotypes; and
- `igv-session.xml`, which references those sibling files relatively.

Open the session with IGV desktop against hg38. BigWig coordinates are
converted to zero-based half-open intervals internally, while the Parquet
tables retain their documented one-based inclusive coordinates.
