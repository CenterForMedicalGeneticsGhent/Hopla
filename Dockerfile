FROM ghcr.io/prefix-dev/pixi:0.78.0 AS build

WORKDIR /app
COPY pixi.lock pyproject.toml LICENSE README.md .
COPY src ./src
RUN pixi install --locked \
    && echo "#!/bin/bash\n$(pixi shell-hook -e default -s bash)\nexec \"\$@\"" > /app/entrypoint.sh \
    && chmod 0755 /app/entrypoint.sh \
    && /app/.pixi/envs/default/bin/python -m pip uninstall -y hopla \
    && /app/.pixi/envs/default/bin/python -m pip install --no-deps .

FROM ubuntu:24.04 AS production

WORKDIR /app
COPY --from=build /app/.pixi/envs/default /app/.pixi/envs/default
COPY --from=build /app/entrypoint.sh /app/entrypoint.sh
# Runtimes that ignore ENTRYPOINT (Apptainer/Singularity exec, Galaxy job
# scripts) never run the pixi shell hook, so the environment must also be on
# PATH through the image configuration.
ENV PATH="/app/.pixi/envs/default/bin:${PATH}"
RUN printf '#!/bin/sh\nexec /app/.pixi/envs/default/bin/hopla "$@"\n' \
    > /usr/local/bin/hopla \
    && chmod 0755 /usr/local/bin/hopla

EXPOSE 8080
ENTRYPOINT ["/app/entrypoint.sh"]