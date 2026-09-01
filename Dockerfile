FROM ghcr.io/prefix-dev/pixi:0.78.0 AS build

WORKDIR /app
COPY pixi.lock pyproject.toml LICENSE README.md .
COPY src ./src
# Installing the conda-only `prod` environment straight into the runtime prefix
# puts its binaries on the default PATH, so no activation or entrypoint is
# needed. The build stage's own pixi lives in that prefix and must not ship.
RUN pixi exec --spec pixi-install-to-prefix==0.1.8 pixi-install-to-prefix \
        --lockfile pixi.lock --environment prod /usr/local \
    && /usr/local/bin/python -m pip install --no-deps . \
    && rm -f /usr/local/bin/pixi

FROM ubuntu:24.04 AS production

WORKDIR /app
COPY --from=build /usr/local /usr/local

EXPOSE 8080
CMD ["hopla", "--help"]
