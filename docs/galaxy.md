# Galaxy

The Galaxy wrapper at [`galaxy/hopla.xml`](../galaxy/hopla.xml) exposes two
batch operations:

- **Run family analysis** accepts YAML or JSON settings and either an
  uncompressed VCF or a bgzip-compressed VCF. A compressed VCF may be paired
  with a tabix (`.tbi`) or CSI (`.csi`) index. It produces the interactive HTML
  report and, when requested, a compressed archive of the Parquet or IGV
  exports.
- **Convert legacy settings** accepts the historical `key=value` text format
  and produces schema-validated YAML.

The interactive `serve` command and the `concordance` and `transform` CLI
helpers are not exposed as Galaxy operations.

## Install from a ToolShed

[`galaxy/.shed.yml`](../galaxy/.shed.yml) describes a ToolShed repository named
`hopla` owned by `cmgg`. After the wrapper is published, a Galaxy administrator
can install it from **Admin → Tool Management → Install and Uninstall**, or
with Ephemeris / Ansible using:

```yaml
tools:
  - name: hopla
    owner: cmgg
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

## Container runtimes and job metadata

Apptainer / Singularity `exec` and Galaxy job scripts run the container
without its `ENTRYPOINT`, so the pixi shell hook that activates the
environment never runs. The image therefore also places
`/app/.pixi/envs/default/bin` on `PATH` through its own configuration, which
keeps `hopla`, `python`, `merlin`, and `minx` resolvable under every runtime.
Without that, a destination using `exec` finds only the `/usr/local/bin/hopla`
shim: unqualified `python` fails, and the missing `merlin` and `minx` silently
disable haplotyping.

A job that still fails with `python: command not found` is failing in Galaxy's
own metadata step rather than in the tool command, which never invokes
`python`. Check the reported line of the generated `galaxy_<id>.sh`. Galaxy
embeds that step in the job by default, so on a container destination it runs
inside the tool image with Galaxy's library paths. Set
`embed_metadata_in_job: false` on the destination to run metadata with
Galaxy's own virtual environment instead.

## Report sanitization and indexed VCFs

The report includes JavaScript and a compressed columnar payload. Add the
`hopla3` tool ID to the file configured by Galaxy's
`sanitize_allowlist_file` setting; otherwise Galaxy sanitizes the HTML and the
interactive report cannot render.

When a VCF index is supplied, the wrapper stages it beside the compressed VCF
under the filename expected by cyvcf2. Indexed input can use the Galaxy job's
allocated slots for contig-parallel loading. Without an index, Hopla remains
valid but falls back to a sequential scan. Galaxy 23.0 does not register CSI
files as a standalone history datatype, so upload a `.csi` index as generic
`data` and select **CSI index** in the tool form.

Lint or run the embedded wrapper tests from a Planemo environment. The pixi
`dev` environment provides Planemo:

```bash
pixi run -e dev lint-galaxy
planemo test galaxy/hopla.xml
```
