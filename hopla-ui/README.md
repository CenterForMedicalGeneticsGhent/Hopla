# Hopla web UI

The UI is a Vue 3 and Vuetify 3 single-page application that creates Hopla
configuration files entirely in the browser. It does not upload genomic or
configuration data to a server.

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
