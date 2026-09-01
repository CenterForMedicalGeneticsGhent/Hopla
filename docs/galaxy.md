# Galaxy

The `galaxy/` directory holds two independent tool wrappers:

- [`galaxy/hopla.xml`](../galaxy/hopla.xml) (tool id `hopla3`) runs the family
  analysis. It accepts YAML or JSON settings, an uncompressed or
  bgzip-compressed VCF, and an optional cytoband table, and produces the
  interactive HTML report plus, when requested, a compressed archive of the
  Parquet or IGV exports.
- [`galaxy/hopla_convert.xml`](../galaxy/hopla_convert.xml) (tool id
  `hopla3_convert`) converts the historical `key=value` settings format to
  schema-validated YAML.

Each wrapper maps onto one CLI subtool, so neither uses conditional inputs.
The interactive `serve` command and the `concordance` and `transform` CLI
helpers are not exposed as Galaxy tools.

## Install from a ToolShed

[`galaxy/.shed.yml`](../galaxy/.shed.yml) describes a ToolShed repository named
`hopla3` owned by `ict` that publishes both wrappers. After the repository is
published, a Galaxy administrator can install it from **Admin → Tool Management
→ Install and Uninstall**, or with Ephemeris / Ansible using:

```yaml
tools:
  - name: hopla3
    owner: ict
    tool_panel_section_label: Variant Analysis
```

The ToolShed owner in `.shed.yml` must match the account used to publish. The
wrappers use the published `quay.io/cmgg/hopla:3.0.0` container, so the Galaxy
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

To skip a ToolShed, copy both wrappers and the `test-data` directory into a
Galaxy tool directory and register the XML files in the instance's tool panel
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

## Linting and testing

Lint or run the embedded wrapper tests from a Planemo environment. The pixi
`dev` environment provides Planemo:

```bash
pixi run -e dev lint-galaxy
planemo test galaxy/hopla.xml galaxy/hopla_convert.xml
```
