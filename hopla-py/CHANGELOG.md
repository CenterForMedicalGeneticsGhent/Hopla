# Changelog

This changelog covers the Hopla Python package and command-line subtools under
`hopla-py/`. Changes to the Vue application under `hopla-ui/` are tracked
separately. Historical notes from the predecessor analysis pipeline live in
[docs/archive/legacy-pipeline-changelog.md](docs/archive/legacy-pipeline-changelog.md).

## [2.0.0] - 2026-08-28

### Added

- Added a typed Python analysis engine under `hopla-py/` with Typer CLI
  subtools `run`, `convert`, `concordance`, and `transform`.
- Added schema-validated YAML and JSON settings loading through jsonschema and
  pydantic, including rejection of unknown properties.
- Added conversion from the legacy `key=value` settings format to
  schema-validated YAML.
- Added columnar VCF loading with cyvcf2 into shared site tables and
  sample-by-site NumPy matrices.
- Added filter 1 / filter 2 masks, variant statistics, ADO/ADI, BAF, Mendelian
  errors, parent mapping, and Merlin haplotyping with neighbourhood voting and
  short-segment correction.
- Added a self-contained offline HTML report that inlines `plotly.js`,
  gzip-compresses columnar payloads, and draws SVG panels lazily on scroll.
- Added default `{fam_id}-export/` Parquet tables plus BigWig / BED / SEG /
  `igv-session.xml` IGV desktop sidecars, with `--no-export-parquet` and
  `--no-export-bigwig` toggles.
- Added pixi `hopla-py` / `hopla-py-dev` environments, pytest coverage, and
  ruff / mypy lint tasks.
- Added the Python user and contributor manual under `docs/`.

### Changed

- Genome-wide BAF and parent-mapping downsampling (`limit_baf_to_p`,
  `limit_pm_to_p`) uses a deterministic stride rather than random sampling.
- Genotype-count and haplotype-concordance grids are HTML tables rather than
  Plotly tables.
- Copy-number segmentation uses a deterministic recursive CBS change statistic.

### Notes

- Settings keys `color_palette`, `self_contained`, and `cairo` remain accepted
  for schema compatibility; the Python report always emits a single offline HTML
  file with the Paired palette and does not use a cairo device.
- Merlin 1.1.2 remains an external dependency. The engine disables Merlin when
  `merlin` / `minx` are absent from `$PATH` or only one real sample is analyzed.
