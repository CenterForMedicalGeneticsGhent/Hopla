# Local settings editor

`hopla serve` starts a lightweight browser form for creating settings files.
It is part of the Python package and requires no Node.js installation.

```bash
hopla serve
```

The default address is <http://127.0.0.1:8080/>. When invoked from an
interactive terminal, Hopla opens that address in the default browser. Use
`--no-open` to disable this behavior or `--port` to choose another port.

The editor provides pedigree, analysis parameter, advanced, and validated YAML
views. It can import:

- legacy Hopla `.txt` settings;
- current `.yaml` and `.yml` settings;
- current `.json` settings.

Imports are limited to 1 MB. Unsupported keys are ignored after a warning.
YAML downloads are validated against the packaged settings schema and omit
unused compatibility keys. The VCF, output-directory, and cytoband paths remain
command line arguments and are never included in downloaded settings. The
editor maps pedigree `Sex` onto `sexes` and stores family notes as a single
multiline `info` string.

## Network safety

The server binds to loopback by default and has no authentication. It is
intended to be started locally, used briefly, and stopped. Do not expose it to
an untrusted network.

For a container or an explicitly managed reverse proxy, bind all interfaces:

```bash
docker run --rm -p 8080:8080 quay.io/cmgg/hopla:latest \
  hopla serve --host 0.0.0.0 --port 8080 --no-open
```

Terminate TLS and add authentication at the reverse proxy when access is not
restricted to the local machine.
