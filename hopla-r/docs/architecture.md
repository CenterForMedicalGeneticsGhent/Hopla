# Package and engine structure

`hopla-r/` is a standard R source package within the Hopla monorepo. Public
functions live in `R/`, generated help lives in `man/`, installed data and
schemas live in `inst/`, package tests live in `tests/`, and executable scripts
live in `exec/`.

```text
DESCRIPTION                 package metadata and dependencies
NAMESPACE                   public exports and imports
R/                          public R API and logging helpers
man/                        Rd documentation for the public API
inst/schema/                installed settings schema
tests/testthat/              package and executable integration tests
exec/hopla                  command dispatcher
exec/hopla-run.R            analysis entry point and orchestration
inst/engine/                private analysis-engine modules
```

The files under `inst/engine/` are implementation modules for the executable,
not public package-namespace APIs. CRAN package rules install only files
directly under `exec/`, not its subdirectories, while `inst/` is copied
recursively. `R CMD INSTALL` therefore installs these modules as `engine/` next
to the installed `exec/` directory. The entry point resolves the source or
installed location from its own path.

## Engine modules

`exec/hopla-run.R` sources the modules in this order:

1. `00-input.R` — settings parsing and post-processing, cytobands, VCF loading,
   gender prediction, pedigree ghosts, and variant filters.
2. `10-merlin.R` — Merlin input generation and execution, output parsing,
   genotype updates, and haplotype correction.
3. `20-plot-helpers.R` — region, cytoband, chromosome-line, matrix, and
   data-URI helpers shared by plot builders.
4. `30-haplotype-plots.R` — haplotype profiles and concordance tables.
5. `40-analysis-plots.R` — genotype tables, pedigree image, variant
   distribution and depth, copy number, Mendelian errors, BAF, and parent
   mapping.
6. `50-report.R` — report assembly, subplot layout, local-asset inlining, and
   compressed htmlwidget data.

The numeric prefixes make dependencies and load order explicit. Modules define
functions only; the entry point owns command-line parsing, package loading,
shared run state, pipeline orchestration, and output writes. Existing engine
functions use that shared run state (`args`, VCF lists, chromosome metadata,
and colours), so reordering modules or sourcing one in isolation is not a
supported API.

## Change placement

- Add or change exported user-facing functions in `R/`, with matching Roxygen
  comments, `NAMESPACE`, and `man/` documentation.
- Keep command parsing in `exec/hopla`.
- Keep analysis orchestration in `exec/hopla-run.R`.
- Put private engine functions in the narrowest relevant `inst/engine/` module.
- Keep the settings schema in `inst/schema/hopla.schema.json`.
- Add behavior and installed-layout coverage in `tests/testthat/`.

Do not source engine modules from `R/` or export them. This keeps the package
namespace CRAN-compatible while retaining an executable analysis pipeline.
