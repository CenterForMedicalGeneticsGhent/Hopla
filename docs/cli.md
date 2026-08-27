# Command line

The `hopla` command is small. Global options are `-h`, `-V` (not `-v`), and
`-L LEVEL` / `--log-level LEVEL`. Use `--` to end option parsing. Options must
precede operands.

```
hopla [-hV] [-L LEVEL] [--] run [-o OUT_DIR] SETTINGS.{yaml,yml,json} VCF
hopla [-hV] [-L LEVEL] [--] convert LEGACY [OUTPUT]
hopla [-hV] [-L LEVEL] [--] concordance [-r] FLOW1 FLOW2
hopla [-hV] [-L LEVEL] [--] transform FLOW1 FLOW2 MODE [OUTPUT]
```

`-L` may also appear among `run` options, before the settings and VCF operands.

- `LEVEL` is `error`, `warn`, `info`, or `debug` (default `info`). `warning` aliases `warn`; `quiet` aliases `error`. The `HOPLA_LOG_LEVEL` environment variable sets the same default. Error and warning records go to standard error; information and debug records go to standard output, each prefixed with a timestamp and the level name. Major analysis steps log at `info`; per-sample, per-chromosome, and per-plot progress logs at `debug`. Expected R coercion warnings while parsing missing AD values are muffled and logged at `debug`.

- `run` validates one settings file against [`inst/schema/hopla.schema.json`](../inst/schema/hopla.schema.json) before loading the VCF or analysis packages, then writes the HTML report.
- `VCF` and `OUT_DIR` are filesystem paths, not settings keys. Both must already exist. The engine does not create a missing output directory. `-o OUT_DIR` defaults to the current working directory (`$PWD`).
- `convert` maps a legacy `key=value` settings file to schema-validated YAML. `OUTPUT` defaults to the input path with a `.yaml` extension.
- `concordance` compares two haplotype flow tables. `-r` compares each flow relative to its first retained marker.
- `transform` rewrites a flow table relative to another. `MODE` is `1` for matching strands or `2` for crossed strands. `OUTPUT` defaults to `<flow1>-relative.txt`.

Grouped short options such as `-hV` are accepted. `concordance` accepts `-r` only before its operands.

Exit status:

- `0` — help, version, or a successful command
- `2` — invalid usage (missing subcommand or operands, unknown options)
- `1` — runtime failure (including a VCF or output directory that does not exist)

Command-line flags do not override individual analysis settings. Configure those in the YAML or JSON file.

## Running an analysis

With pixi:

```bash
pixi run hopla run path/to/settings.yaml path/to/family.vcf.gz
pixi run hopla run -o path/to/output path/to/settings.yaml path/to/family.vcf.gz
```

With an installed Bioconda environment:

```bash
hopla run path/to/settings.json path/to/family.vcf.gz
```

Settings format, types, defaults, and constraints: [settings.md](settings.md). Complete example: [`example/settings.yaml`](../example/settings.yaml).

## Convert, concordance, and transform

```bash
pixi run hopla convert path/to/legacy-settings.txt
pixi run hopla convert path/to/legacy-settings.txt path/to/settings.yaml
pixi run hopla concordance family-a-flow.txt family-b-flow.txt
pixi run hopla concordance -r family-a-flow.txt family-b-flow.txt
pixi run hopla transform family-a-flow.txt family-b-flow.txt 1
```

Legacy conversion rules and the dotted-key mapping are in [settings.md](settings.md). An example legacy file is [`example/legacy-settings.txt`](../example/legacy-settings.txt).

The former standalone helper scripts are exported package functions (`hopla_run`, `hopla_convert_settings`, `hopla_concordance`, `hopla_transform`) with matching Rd documentation.

## Example clone

```bash
git clone https://github.com/CenterForMedicalGeneticsGhent/Hopla
cd hopla
pixi run hopla run example/settings.yaml path/to/family.vcf.gz
```
