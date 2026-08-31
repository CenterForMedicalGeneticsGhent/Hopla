# Python engine architecture

Hopla is an installable Python package at the repository root. Public
modules live under `src/hopla/`, tests under `tests/`, and the user/contributor
manual under `docs/`.

```text
pyproject.toml              package metadata, console script, tool config
src/hopla/__init__.py       package version
src/hopla/cli.py            Typer command-line dispatcher
src/hopla/pipeline.py       shared analysis orchestration
src/hopla/settings.py       schema validation and pedigree defaults
src/hopla/vcf.py            cyvcf2 streaming into SiteTable / matrices
src/hopla/filters.py        filter 1 and filter 2 masks
src/hopla/pedigree.py       sex prediction, ghosts, pedigree SVG
src/hopla/analysis.py       variant stats, BAF, CN, Mendelian, parent mapping
src/hopla/merlin.py         Merlin I/O, parsing, haplotype correction
src/hopla/flow.py           concordance / transform helpers
src/hopla/convert.py        legacy key=value → YAML conversion
src/hopla/cytobands.py      UCSC cytoband load / download
src/hopla/report.py         self-contained HTML report assembly
src/hopla/serve.py          Starlette settings and analysis application
src/hopla/ui/               form mapping, Jinja template, CSS, and JavaScript
src/hopla/export/           Parquet and IGV desktop exporters
src/hopla/models.py         shared typed tables and chromosome constants
tests/                      pytest coverage for CLI, engine, report, export
docs/                       user and contributor manual
```

The settings schema is packaged with the wheel as
`hopla/schema/hopla.schema.json` from `src/hopla/schema/hopla.schema.json`.
There is no runtime fallback to another package tree.

## Engine flow

The Python engine is explicit and columnar:

1. `settings.py` validates YAML/JSON against the Hopla schema and derives
   pedigree defaults before VCF loading.
2. `vcf.py` streams selected biallelic SNVs with cyvcf2 into one `SiteTable`
   and compact sample-by-site NumPy matrices.
3. `filters.py`, `analysis.py`, and `merlin.py` operate on masks and matrices;
   they do not duplicate site columns per sample.
4. `report.py` serializes each result table by column, gzip-compresses the
   payload, and inlines the offline `plotly.js` bundle once. Figures are built
   in the browser from that single payload and drawn only when they scroll into
   view, so the report keeps Plotly visuals without repeating the data per
   figure.
5. `export/parquet.py` and `export/igv.py` optionally write the same visualized
   tables as portable Parquet plus BigWig / BED / SEG / `igv-session.xml`
   sidecars. See [exports.md](exports.md) and
   [igvjs-evaluation.md](igvjs-evaluation.md).

All functions are typed and documented. Polars owns tabular joins and
aggregation; NumPy owns dense genotype operations. Merlin 1.1.2 remains an
external executable so its haplotyping inference stays compatible with prior
Hopla Merlin workflows.

`cli.py` owns command-line parsing and logging setup. `pipeline.py` owns the
shared analysis sequence, temporary cytoband download lifetime, and output
writes used by the CLI and web interface. Individual analysis modules define
the narrower helpers called by that sequence.

## Web interface flow

`hopla serve` starts the Starlette application in `serve.py` through Uvicorn.
The application serves package-local Jinja, CSS, and JavaScript assets from
`ui/`. Browser form state is stateless: preview, import, and download requests
carry the complete form model. `ui/form.py` converts that model to schema-valid
settings and reconstructs the youngest pedigree from imported legacy,
YAML, or JSON settings.

For an analysis, the application validates the current form, allocates a
randomly identified job directory under an application-lifetime temporary
directory, and streams the selected VCF into it. The blocking shared pipeline
runs in a worker thread while the browser polls coarse job status. Web jobs
disable portable and IGV exports; the completed HTML report remains available
for download until the server stops.

## Change placement

- Keep command parsing in `cli.py` and shared run orchestration in `pipeline.py`.
- Keep settings validation and derived defaults in `settings.py`.
- Put VCF loading and genotype matrices in `vcf.py`.
- Put filter masks in `filters.py`.
- Put analysis tables in `analysis.py`.
- Put Merlin execution and haplotype correction in `merlin.py`.
- Put report HTML assembly in `report.py`.
- Put settings and analysis HTTP routes in `serve.py` and form mapping/assets
  in `ui/`.
- Put portable / IGV exporters under `export/`.
- Add behavior coverage under `tests/`.

## Compatibility

The Typer CLI preserves the `run`, `convert`, `concordance`, and `transform`
commands and status conventions (`0` success, `2` usage, `1` runtime). The
report reproduces the established section order, figures, and Paired palette.
Two deliberate differences remain: the count and concordance grids are HTML
tables rather than Plotly tables, and `limit_baf_to_p` / `limit_pm_to_p`
subsample deterministically instead of randomly. Every panel is drawn as SVG
rather than WebGL, because browsers cap the number of simultaneous WebGL
contexts well below the panel count. Copy-number segmentation uses a
deterministic recursive circular-binary-segmentation change statistic and is
therefore not bit-identical to permutation-based circular-binary-segmentation
with resampling.

The report always inlines Plotly assets and uses the Paired palette.
