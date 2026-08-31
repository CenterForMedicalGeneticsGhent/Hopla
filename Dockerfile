FROM ghcr.io/prefix-dev/pixi:0.77.1 AS build

WORKDIR /app
COPY abecasis-lab-merlin ./abecasis-lab-merlin
COPY hopla ./hopla
WORKDIR /app/hopla
RUN pixi install --locked \
    && pixi shell-hook -s bash > /app/entrypoint.sh \
    && printf '\nexec "$@"\n' >> /app/entrypoint.sh \
    && chmod 0755 /app/entrypoint.sh \
    && /app/hopla/.pixi/envs/default/bin/python -m pip uninstall -y hopla merlinpy \
    && /app/hopla/.pixi/envs/default/bin/python -m pip install \
        --no-deps ../abecasis-lab-merlin \
    && /app/hopla/.pixi/envs/default/bin/python -m pip install --no-deps .

FROM ubuntu:24.04 AS production

WORKDIR /app
COPY --from=build /app/hopla/.pixi/envs/default /app/hopla/.pixi/envs/default
COPY --from=build /app/entrypoint.sh /app/entrypoint.sh
RUN printf '#!/bin/sh\nexec /app/hopla/.pixi/envs/default/bin/hopla "$@"\n' \
    > /usr/local/bin/hopla \
    && chmod 0755 /usr/local/bin/hopla

EXPOSE 8080
ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
CMD ["hopla", "-h"]
