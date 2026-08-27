# Web UI

The Vue application lives under `UI/` and is documented separately from the R pipeline. Changes to that tree are out of scope for R-package work unless a task names `UI/` explicitly. UI changelog is tracked separately from [CHANGELOG-R.md](../CHANGELOG-R.md).

The root R Docker image must not copy `UI/`.

## Project setup

```bash
yarn install
```

### Compiles and hot-reloads for development

```bash
yarn serve
```

### Compiles and minifies for production

```bash
yarn build --prod
```

### Unit tests

```bash
yarn test:unit
```

### Lint

```bash
yarn lint
```

### Configuration

See the [Vue CLI configuration reference](https://cli.vuejs.org/config/).

## Docker (UI)

This image is separate from the root R pipeline image.

```bash
docker build -t cmgg/hopla-ui .
docker run -p 8080:80 cmgg/hopla-ui
```

Build from the `UI/` directory (or with that context) so the UI Dockerfile is used.
