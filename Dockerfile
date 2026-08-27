FROM ghcr.io/prefix-dev/pixi:0.77.1 AS build

WORKDIR /app
COPY pixi.toml pixi.lock ./
RUN pixi install --locked \
    && pixi shell-hook -s bash > /app/entrypoint.sh \
    && printf '\nexec "$@"\n' >> /app/entrypoint.sh \
    && rm -f /app/.pixi/envs/default/bin/pandoc \
    && chmod 0755 /app/entrypoint.sh

FROM ubuntu:24.04 AS production

WORKDIR /app
COPY --from=build /app/.pixi/envs/default /app/.pixi/envs/default
COPY --from=build /app/entrypoint.sh /app/entrypoint.sh
COPY hopla.R concordance.R transform.R ./

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
CMD ["Rscript", "/app/hopla.R", "--help"]
