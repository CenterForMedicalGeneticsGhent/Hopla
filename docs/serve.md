# Local web interface

`hopla serve` starts a lightweight browser interface for creating settings
files and running analyses. It is part of the Python package and requires no
Node.js installation.

```bash
hopla serve
```

The default address is <http://127.0.0.1:8080/>. When invoked from an
interactive terminal, Hopla opens that address in the default browser. Use
`--no-open` to disable this behavior or `--port` to choose another port. Use
`--no-analysis` to serve the settings editor without the analysis runner.

The interface provides pedigree, analysis parameter, advanced, validated YAML,
and analysis views. It can import:

- legacy Hopla `.txt` settings;
- current `.yaml` and `.yml` settings;
- current `.json` settings.

Imports are limited to 1 MB. Unsupported keys are ignored after a warning.
YAML downloads are validated against the packaged settings schema and omit
unused compatibility keys. The editor maps pedigree `Sex` onto `sexes` and
stores family notes as a single multiline `info` string.

## Run an analysis

Create a configuration in the form or import an existing configuration, then:

1. Open the **Analysis** tab.
2. Select a `.vcf`, `.vcf.gz`, or `.vcf.bgz` file from the local system.
3. Select **Run analysis**.
4. Follow the running indicator and step log until the analysis reports
   completion, then download the HTML report.

While an analysis runs, the page lists each pipeline step with the seconds
elapsed since the job started, the same major steps `hopla run` logs at `info`:
receiving the VCF, loading it, applying filters, computing analyses, running
Merlin when the pedigree allows it, and rendering the report. A failing step is
appended to that log with its error.

The browser streams the VCF to temporary storage on the machine running
`hopla serve`. There is no configured upload-size limit, so available disk
space must accommodate the input. The configuration, VCF, and generated report
are removed when the server stops.

Start the server with `--no-analysis` to offer settings editing only. The
Analysis tab is then absent and the analysis endpoints are not registered, so an
instance that should not read local VCFs or start runs cannot be driven into
doing so.

Web analyses generate only the self-contained HTML report; they do not generate
the Parquet or IGV sidecars written by the default `hopla run` command. Use the
CLI when those exports, a persistent output directory, or a custom cytoband
file are required. When the web interface needs the default hg38 cytobands, the
server downloads them as it does for `hopla run` without `-c`.

## Network safety

The server binds to loopback by default and has no authentication. It accepts
large genomic files and can start resource-intensive analyses. It is intended
to be started locally, used briefly, and stopped. Do not expose it to an
untrusted network.

For a container or an explicitly managed reverse proxy, bind all interfaces:

```bash
docker run --rm -p 8080:8080 quay.io/cmgg/hopla:latest \
  hopla serve --host 0.0.0.0 --port 8080 --no-open
```

Terminate TLS and add authentication at the reverse proxy when access is not
restricted to the local machine.
