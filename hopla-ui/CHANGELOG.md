# Changelog

All notable changes to the Hopla web UI are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-08-27

### Added

- Support for uploading settings files that have no generated `# HEADER`
  block: the pedigree is reconstructed from the `sample.ids`, `father.ids`,
  and `mother.ids` arguments.
- Automated configuration import/export regression tests.
- Pull-request CI for linting, unit tests, and production builds.
- Content Security Policy and browser security headers for the nginx image.
- Validation and user-facing errors for imported configuration files.

### Changed

- Moved the application into `hopla-ui/` in the Hopla monorepo, with root pixi
  tasks and an independent CI workflow.
- Published UI containers now use `quay.io/cmgg/hopla` with `ui-`-prefixed
  tags.
- Documented that the UI is an optional local helper for writing the settings
  file; Hopla can run from a hand-edited YAML or JSON config.
- Configuration previews and downloads now use the schema-compatible YAML
  format accepted by `hopla run` instead of the legacy `key=value` format.

### Fixed

- Uploading a hand-written settings file no longer fails as incompatible.
- Arguments omitted from a settings file now keep their form default instead
  of aborting the import.
- Relatives outside the analysis keep their placeholder identifier and gender
  instead of being imported as undefined.
- `self.contained` and `limit.baf.to.P` are read from the settings file rather
  than reset on every import.
- Upload errors now report why the file was rejected.

### Changed

- Upgraded from Vue 2, Vue CLI 4, Webpack 4, and Vuetify 2 to Vue 3, Vite,
  and Vuetify 3.
- Upgraded the build runtime to Node.js 22 and the production server to a
  pinned, unprivileged nginx image.
- Replaced external font and icon stylesheets with locally bundled assets.
- Made container dependency installation reproducible with the Yarn lockfile.
- Sanitized downloaded configuration filenames.
- Updated the release workflow and UI development documentation.

### Removed

- Unused Vuex, class-component, and property-decorator dependencies.
- The unused scaffold About route and test.
- End-of-life Vue CLI, Webpack, Babel, and Jest configuration.

[0.2.0]: https://github.com/CenterForMedicalGeneticsGhent/Hopla/compare/v0.1.0...v0.2.0
