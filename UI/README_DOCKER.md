# Docker setup

```bash
docker build -t cmgg/hopla-ui .
docker run --read-only --cap-drop=ALL --tmpfs /tmp \
  --security-opt=no-new-privileges --publish 8080:8080 cmgg/hopla-ui
```

Open <http://localhost:8080>.

The final image runs nginx as an unprivileged user on port 8080. TLS is expected
to terminate at a reverse proxy. Configure HSTS at that proxy only if HTTP is
always redirected to HTTPS.
