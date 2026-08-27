# Docker setup

From the repository root:

```bash
docker build -f hopla-ui/Dockerfile -t hopla:ui-local hopla-ui
docker run --read-only --cap-drop=ALL --tmpfs /tmp \
  --security-opt=no-new-privileges --publish 8080:8080 hopla:ui-local
```

Published UI images use `quay.io/cmgg/hopla:ui-<tag>`.

Open <http://localhost:8080>.

The final image runs nginx as an unprivileged user on port 8080. TLS is expected
to terminate at a reverse proxy. Configure HSTS at that proxy only if HTTP is
always redirected to HTTPS.
