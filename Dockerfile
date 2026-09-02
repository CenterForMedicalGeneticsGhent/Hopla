FROM ghcr.io/prefix-dev/pixi:0.78.0 AS build

WORKDIR /app
COPY pixi.lock pyproject.toml LICENSE README.md .
COPY src ./src
RUN pixi install --locked \
    && pixi shell-hook -e default -s bash > /app/activate.sh \
    && /app/.pixi/envs/default/bin/python -m pip uninstall -y hopla \
    && /app/.pixi/envs/default/bin/python -m pip install --no-deps .

FROM ubuntu:26.04 AS production

WORKDIR /app
COPY --from=build /app/.pixi/envs/default /app/.pixi/envs/default
COPY --from=build /app/activate.sh /app/activate.sh

# The environment stays off the image PATH. Galaxy runs its own scripts with the
# `python` it finds on PATH, and Hopla's interpreter cannot import Galaxy. The
# launcher activates the environment for hopla alone, which needs merlin and minx.
RUN printf '#!/bin/bash\n. /app/activate.sh\nexec /app/.pixi/envs/default/bin/hopla "$@"\n' \
    > /usr/local/bin/hopla \
    && chmod 0755 /usr/local/bin/hopla

EXPOSE 8080
CMD ["bash"]
