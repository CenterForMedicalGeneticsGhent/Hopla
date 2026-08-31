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

## Install

Install the wrapper and its `test-data` directory in a Galaxy tool directory,
then register `hopla.xml` in the instance's tool panel configuration. The
wrapper uses the published `quay.io/cmgg/hopla:3.0.0` container, so the Galaxy
job destination must have a container resolver configured.

The report includes JavaScript and a compressed columnar payload. Add the
`hopla` tool ID to the file configured by Galaxy's
`sanitize_allowlist_file` setting; otherwise Galaxy sanitizes the HTML and the
interactive report cannot render.

When a VCF index is supplied, the wrapper stages it beside the compressed VCF
under the filename expected by cyvcf2. Indexed input can use the Galaxy job's
allocated slots for contig-parallel loading. Without an index, Hopla remains
valid but falls back to a sequential scan. Galaxy 23.0 does not register CSI
files as a standalone history datatype, so upload a `.csi` index as generic
`data` and select **CSI index** in the tool form.

Run the embedded wrapper tests from a Galaxy or Planemo environment:

```bash
planemo test galaxy/hopla.xml
```
