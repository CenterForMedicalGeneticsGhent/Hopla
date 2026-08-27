# Install and dependencies

Hopla requires R 4.4 or newer.

## Pixi (Linux)

The monorepo root includes a locked [pixi](https://pixi.sh) environment for
`linux-64`, `linux-aarch64`, and `osx-arm64`. Merlin 1.1.2 is included on each
of those platforms.

```bash
pixi install
pixi run hopla --help
```

Use `pixi install --locked` so the committed `pixi.lock` is respected.

The default and `hopla-r` environments hold analysis dependencies. The `dev`
and `hopla-r-dev` environments add testthat and lintr.

Pixi tasks:

- `hopla` — `Rscript hopla-r/exec/hopla`
- `convert`, `concordance`, and `transform` — R subtools
- `hopla-r-dev` environment `check` — `R CMD build` and `R CMD check --no-manual`
- `hopla-r-dev` environment `lint` — `Rscript hopla-r/tools/lint.R`

## Conda / Bioconda

Install the published package through [conda](https://docs.conda.io/en/latest/):

```bash
conda install -c conda-forge -c bioconda hopla
```

Bioconda recipe: <http://bioconda.github.io/recipes/hopla/README.html>.

## Docker (R pipeline)

`hopla-r/Dockerfile` builds a minimal Linux image from the root `pixi.lock`.
It does not copy `hopla-ui/`. The runtime stage does not ship the pixi binary
or the unused Pandoc executable.

```bash
docker build -f hopla-r/Dockerfile -t hopla .
docker run --rm hopla hopla -V
```

CI publishes the R image as `quay.io/cmgg/hopla` with unprefixed tags such as
`latest`, `stable`, and the R package version.

## Dependencies

These are installed automatically with pixi or conda:

- R (v4.4 or newer)
- R packages
    - vcfR (v1.16.0 or newer)
    - data.table (v1.17.0 or newer)
    - RColorBrewer (v1.1-3 or newer)
    - kinship2 (v1.9.0 or newer)
    - plotly (v4.12.0 or newer)
    - htmltools (v0.5.0)
    - base64enc (v0.1-3 or newer)
    - jsonlite, jsonvalidate, and yaml
    - scales (v1.4.0 or newer)
    - GenomicRanges and DNAcopy from the Bioconductor release matching the installed R version
- Standalone tools
    - [Merlin](http://csg.sph.umich.edu/abecasis/merlin/index.html) (v1.1.2)

Merlin’s version should be exactly as given. The Merlin executables folder (`path/to/merlin-1.1.2/executables`) must be on `$PATH`, which is automatic with pixi or conda install.

Plotly’s version is ideally no lower than given. For the remaining packages, other versions are very likely to work.

Hopla must not invoke Pandoc. Self-contained HTML is produced by the internal asset inliner. Conda may still resolve Pandoc transitively through plotly’s htmlwidgets/rmarkdown dependency chain; the runtime Docker image removes the unused executable.

Do not install CRAN packages outside pixi when developing from this repository.
Add R dependencies to both the root `pixi.toml` and `hopla-r/DESCRIPTION`, then
regenerate the root `pixi.lock` with pixi.

See [CHANGELOG-R.md](../CHANGELOG-R.md) for changes to the R pipeline.
