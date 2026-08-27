# Hopla web UI

The UI is a Vue 3 and Vuetify 3 single-page application that helps create
Hopla configuration files in the browser. It is optional: Hopla itself only
needs a YAML or JSON settings file, which can be written and edited by hand.
The app is meant to run locally as a short-lived helper, not as a standing
service. It does not upload genomic or configuration data to a server.
The Config tab downloads schema-compatible YAML for `hopla run`; legacy
`.txt` configuration files remain supported as imports.

See the [UI documentation](docs/README.md) for architecture, development, and
container details.

## Pixi (recommended)

From the repository root:

```
pixi run -e hopla-ui serve
pixi run -e hopla-ui lint
pixi run -e hopla-ui test
pixi run -e hopla-ui build
```

## Direct requirements

- Node.js 22.12 or newer
- Yarn 1.22.22

## Install

```
yarn install --frozen-lockfile
```

## Development

```
yarn serve
```

## Production build

```
yarn build
```

## Unit tests

```
yarn test:unit
```

## Lint

```
yarn lint
```

## Deployment security

The provided container serves the static application as an unprivileged user
with a restrictive Content Security Policy and other browser security headers.
Terminate TLS at the reverse proxy and enable HSTS there only when the site is
exclusively available over HTTPS.

The published image uses the shared `quay.io/cmgg/hopla` repository with
UI-prefixed tags such as `ui-latest`, `ui-stable`, and `ui-0.2.0`.
