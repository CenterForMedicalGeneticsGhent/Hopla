# Web UI

The Vue 3 application lives in `hopla-ui/`, independently from the
CRAN-compatible package in `hopla-r/`. It creates Hopla configuration files in
the browser and does not upload input data. UI changes are recorded in
[`CHANGELOG.md`](../CHANGELOG.md).

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
