# Command line

The `hopla` command is small. Global options are `-h` / `--help`, `-V` /
`--version` (not `-v`), and `-L LEVEL` / `--log-level LEVEL`. Options must
precede operands for each command.

```
hopla [-hV] [-L LEVEL] run [-o OUT_DIR] [-c CYTOBAND]
      [--export-parquet|--no-export-parquet]
      [--export-bigwig|--no-export-bigwig]
      SETTINGS.{yaml,yml,json} VCF
hopla [-hV] [-L LEVEL] convert LEGACY [OUTPUT]
hopla [-hV] [-L LEVEL] concordance [-r] FLOW1 FLOW2
hopla [-hV] [-L LEVEL] transform FLOW1 FLOW2 MODE [OUTPUT]
hopla [-hV] [-L LEVEL] serve [--host HOST] [--port PORT]
      [--open|--no-open] [--analysis|--no-analysis]
```

`-L` may also appear among `run` options, before the settings and VCF operands.

- `LEVEL` is `error`, `warn`, `info`, or `debug` (default `info`). `warning`
  aliases `warn`; `quiet` aliases `error`. The `HOPLA_LOG_LEVEL` environment
  variable sets the same default. Records go to standard error, each prefixed
  with a timestamp and the level name. Major analysis steps log at `info`.
- `run` validates one settings file against the packaged
  `hopla/schema/hopla.schema.json` before loading the VCF, then writes the HTML
  report and optional exports.
- `VCF`, `OUT_DIR`, and `CYTOBAND` are filesystem paths, not settings keys.
  Supplied paths must already exist. The engine does not create a missing
  output directory. `-o OUT_DIR` defaults to the current working directory
  (`$PWD`).
- `-c CYTOBAND` takes a
  [UCSC cytoband table](https://hgdownload.soe.ucsc.edu/downloads.html#human),
  which draws chromosome bands on the chromosome-wise figures. When omitted,
  Hopla downloads and decompresses
  [hg38 `cytoBand.txt.gz`](https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/cytoBand.txt.gz)
  into a temporary directory for that run.
- `--export-parquet` / `--no-export-parquet` controls writing portable Parquet
  tables under `{fam_id}-export/` (default: on).
- `--export-bigwig` / `--no-export-bigwig` controls writing BigWig, BED, SEG,
  and `igv-session.xml` under the same export directory (default: on). Details:
  [exports.md](exports.md).
- `convert` maps a legacy `key=value` settings file to schema-validated YAML.
  `OUTPUT` defaults to the input path with a `.yaml` extension.
- `concordance` compares two haplotype flow tables. `-r` compares each flow
  relative to its first retained marker.
- `transform` rewrites a flow table relative to another. `MODE` is `1` for
  matching strands or `2` for crossed strands. `OUTPUT` defaults to
  `<flow1>-relative.txt`.
- `serve` starts the local browser settings editor. It binds
  `127.0.0.1:8080` by default and opens a browser when run interactively.
  `--no-analysis` serves settings only: the Analysis tab is not rendered and
  the analysis endpoints are not registered.

`concordance` accepts `-r` only before its operands.

Exit status:

- `0` — help, version, or a successful command
- `2` — invalid usage (missing subcommand or operands, unknown options)
- `1` — runtime failure (including a VCF or output directory that does not
  exist)

Command-line flags do not override individual analysis settings. Configure
those in the YAML or JSON file. The export toggles only control portable and
IGV sidecar output.

## Running an analysis

With pixi:

```bash
pixi run hopla run path/to/settings.yaml path/to/family.vcf.gz
pixi run hopla run -o path/to/output path/to/settings.yaml path/to/family.vcf.gz
pixi run hopla run -c path/to/cytoband.hg38.txt path/to/settings.yaml path/to/family.vcf.gz
pixi run hopla run --no-export-parquet --no-export-bigwig path/to/settings.yaml path/to/family.vcf.gz
```

With an editable install on `PATH`:

```bash
hopla run path/to/settings.json path/to/family.vcf.gz
```

Successful `run` prints the HTML report path to standard output.

Settings format, types, defaults, and constraints: [settings.md](settings.md).
Complete example: [`example/settings.yaml`](../example/settings.yaml).

## Settings editor

```bash
hopla serve
hopla serve --no-open
hopla serve --host 0.0.0.0 --port 8080
hopla serve --no-analysis
```

The web interface imports legacy `.txt` and current YAML/JSON settings,
reconstructs the pedigree, validates changes against the packaged schema, and
downloads YAML for `hopla run`. It can also stream a locally selected VCF,
run an analysis with the current configuration, and return the self-contained
HTML report. Web analyses use temporary storage and do not write Parquet or IGV
exports. See [serve.md](serve.md) for usage and network-safety details.

## Convert, concordance, and transform

```bash
pixi run hopla convert path/to/legacy-settings.txt
pixi run hopla convert path/to/legacy-settings.txt path/to/settings.yaml
pixi run hopla concordance family-a-flow.txt family-b-flow.txt
pixi run hopla concordance -r family-a-flow.txt family-b-flow.txt
pixi run hopla transform family-a-flow.txt family-b-flow.txt 1
```

Legacy conversion rules and the dotted-key mapping are in
[settings.md](settings.md). An example legacy file is
[`example/legacy-settings.txt`](../example/legacy-settings.txt).

## Example clone

```bash
git clone https://github.com/CenterForMedicalGeneticsGhent/Hopla
cd Hopla
pixi install --locked
pixi run hopla run example/settings.yaml path/to/family.vcf.gz
```
