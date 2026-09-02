# Galaxy

The Galaxy wrapper at [`galaxy/hopla.xml`](../galaxy/hopla.xml) (tool id
`hopla3`) exposes two operations behind an **Operation** selector:

- **Run family analysis** accepts YAML or JSON settings, an uncompressed or
  bgzip-compressed VCF, and the path of a cytoband table. It produces the
  interactive HTML report and, when requested, a compressed archive of the
  Parquet or IGV exports.
- **Convert legacy settings** accepts the historical `key=value` text format
  and produces schema-validated YAML.

The selector is a single `conditional`; each operation's parameters live in its
own `when` block, so the form has no nested conditionals. The interactive
`serve` command and the `concordance` and `transform` CLI helpers are not
exposed as Galaxy operations.

## Install from a ToolShed

[`galaxy/.shed.yml`](../galaxy/.shed.yml) describes a ToolShed repository named
`hopla3` owned by `ict`. After the wrapper is published, a Galaxy administrator
can install it from **Admin → Tool Management → Install and Uninstall**, or
with Ephemeris / Ansible using:

```yaml
tools:
  - name: hopla3
    owner: ict
    tool_panel_section_label: Variant Analysis
```

The ToolShed owner in `.shed.yml` must match the account used to publish. The
wrapper uses the published `quay.io/cmgg/hopla:3.0.0` container, so the Galaxy
job destination must have a container resolver configured.

Publish or update the repository with Planemo from a ToolShed account:

```bash
planemo shed_lint galaxy/
planemo shed_create --shed_target testtoolshed galaxy/
planemo shed_update --shed_target testtoolshed galaxy/
```

Replace `testtoolshed` with `toolshed` for the main Galaxy ToolShed once the
test revision is verified.

## Install from this repository

To skip a ToolShed, copy the wrapper and its `test-data` directory into a
Galaxy tool directory and register `hopla.xml` in the instance's tool panel
configuration.

## Report sanitization

The report includes JavaScript and a compressed columnar payload. Add the
`hopla3` tool ID to the file configured by Galaxy's
`sanitize_allowlist_file` setting; otherwise Galaxy sanitizes the HTML and the
interactive report cannot render.

## Indexed VCF input

Galaxy keeps a tabix index as dataset metadata for every `vcf_bgzip` dataset.
The wrapper stages that index next to the staged VCF, so bgzip-compressed input
is loaded contig-parallel across the job's allocated slots without asking the
user for an index dataset. An uncompressed `vcf` dataset has no index and falls
back to a single sequential scan.

## Cytoband table

**UCSC hg38 cytoband table** is a path, not a history dataset. It defaults to
`/references/Hsapiens/hg38/hopla/cytoBand_hg38.txt`, the location used by the
CMGG instance. The path is resolved inside the job container, so the directory
holding it must be part of the destination's `docker_volumes` (or the
equivalent Singularity bind paths). Clearing the field makes Hopla download the
hg38 table from UCSC, which needs the job to have network access.

## Job destination checklist

Per-tool Galaxy configuration is keyed on the tool id, which is `hopla3` and
not the `hopla` id of the R-based 1.x wrapper. When the new tool behaves
differently from the old one, check that the following name `hopla3`:

- the tool-to-destination mapping in `job_conf`, including the destination that
  enables containers and mounts the reference directory,
- the `sanitize_allowlist_file` entry that keeps the report's JavaScript.

Galaxy computes dataset metadata after the tool command by running its own
`metadata/set.py` with the `python` it finds on `PATH`. That script imports
Galaxy and its dependencies, so it only works with Galaxy's own interpreter.
The Hopla image therefore keeps its environment off the image `PATH` and
exposes only a `hopla` launcher; a container that puts a foreign `python`
first makes Galaxy's metadata step fail with `ModuleNotFoundError: No module
named 'sqlalchemy'`. If a destination computes metadata inside the container
(`metadata_strategy: extended`), Galaxy's virtualenv must be readable there as
well.

## Linting and testing

Lint or run the embedded wrapper tests from a Planemo environment. The pixi
`dev` environment provides Planemo:

```bash
pixi run -e dev lint-galaxy
planemo test galaxy/hopla.xml
```

The wrapper tests leave the cytoband path empty, so the analysis tests download
the hg38 cytoband table from UCSC.
