FROM ghcr.io/prefix-dev/pixi:0.77.1 AS build

WORKDIR /app
COPY pixi.toml pixi.lock ./
COPY hopla-py/pyproject.toml hopla-py/LICENSE hopla-py/README.md ./hopla-py/
COPY hopla-py/src ./hopla-py/src
RUN pixi install --locked \
    && pixi run python -m pip install --no-deps ./hopla-py \
    && pixi shell-hook -s bash > /app/entrypoint.sh \
    && printf '\nexec "$@"\n' >> /app/entrypoint.sh \
    && chmod 0755 /app/entrypoint.sh

FROM ubuntu:24.04 AS production

WORKDIR /app
COPY --from=build /app/.pixi/envs/default /app/.pixi/envs/default
COPY --from=build /app/entrypoint.sh /app/entrypoint.sh
RUN printf '#!/bin/sh\nexec /app/.pixi/envs/default/bin/hopla "$@"\n' \
    > /usr/local/bin/hopla \
    && chmod 0755 /usr/local/bin/hopla

EXPOSE 8080
ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
CMD ["hopla", "-h"]
