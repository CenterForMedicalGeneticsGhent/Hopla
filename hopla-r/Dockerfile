FROM ghcr.io/prefix-dev/pixi:0.77.1 AS build

WORKDIR /app
COPY pixi.toml pixi.lock ./
COPY hopla-r/DESCRIPTION hopla-r/NAMESPACE hopla-r/LICENSE ./hopla-r/
COPY hopla-r/R ./hopla-r/R
COPY hopla-r/exec ./hopla-r/exec
COPY hopla-r/inst ./hopla-r/inst
RUN pixi install --locked \
    && pixi run R CMD INSTALL hopla-r \
    && pixi shell-hook -s bash > /app/entrypoint.sh \
    && printf '\nexec "$@"\n' >> /app/entrypoint.sh \
    && rm -f /app/.pixi/envs/default/bin/pandoc \
    && chmod 0755 /app/entrypoint.sh

FROM ubuntu:24.04 AS production

WORKDIR /app
COPY --from=build /app/.pixi/envs/default /app/.pixi/envs/default
COPY --from=build /app/entrypoint.sh /app/entrypoint.sh
RUN printf '#!/bin/sh\nexec /app/.pixi/envs/default/lib/R/library/hopla/exec/hopla "$@"\n' \
    > /usr/local/bin/hopla \
    && chmod 0755 /usr/local/bin/hopla

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
CMD ["hopla", "-h"]
