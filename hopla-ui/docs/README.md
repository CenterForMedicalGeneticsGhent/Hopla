# Web UI

The Vue 3 application lives in `hopla-ui/`, independently from the Python
analysis package in `hopla-py/`. It is a local helper for writing the YAML or
JSON settings file that `hopla run` consumes. It is not required to run Hopla:
that file can be created and edited manually. The UI is meant to be started
locally, used briefly to produce a config, and then stopped. It does not upload
input data. UI changes are recorded in [`CHANGELOG.md`](../CHANGELOG.md).

The app uses Vuetify 3, Vite, TypeScript, ESLint, and Vitest.

## Pixi development

Run shared workspace tasks from the repository root:

```bash
pixi run -e hopla-ui serve
pixi run -e hopla-ui lint
pixi run -e hopla-ui test
pixi run -e hopla-ui build
```

The `install` dependency of these tasks runs Yarn 1.22.22 through Corepack with
the committed lockfile.

The Config tab previews and downloads a `.yaml` file using the current
snake_case settings schema. VCF, output-directory, and optional cytoband paths
remain command-line arguments and are intentionally not written to the file.
The upload control continues to accept historical `.txt` configurations so
existing files can be migrated through the UI.

## Direct Yarn development

From `hopla-ui/`:

```bash
yarn install --frozen-lockfile
yarn serve
yarn test:unit
yarn lint
yarn build
```

## Docker

Build from the repository root:

```bash
docker build -f hopla-ui/Dockerfile -t hopla:ui-local hopla-ui
docker run --read-only --cap-drop=ALL --tmpfs /tmp \
  --security-opt=no-new-privileges --publish 8080:8080 hopla:ui-local
```

CI publishes this image as `quay.io/cmgg/hopla` with `ui-`-prefixed tags:
`ui-<commit-sha>`, `ui-latest`, `ui-<version>`, and `ui-stable`.

The image serves the built SPA as an unprivileged nginx user on port 8080 with
security headers from `docker/nginx.conf`.
