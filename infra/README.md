# Infra

Deployment and hosting configuration for Orbit Browser.

## Contents

- `Dockerfile` — multi-stage build: Node 22 builds the web-app PWA, nginx serves `dist/` with SPA fallback + PWA-safe caching.
- `nginx.conf` — nginx site config (service worker no-cache, app-shell fallback, immutable asset caching).

## Local run

```bash
docker build -f infra/Dockerfile -t orbit-browser .
docker run -p 8080:80 orbit-browser
# → http://localhost:8080
```

## Deployment targets (to be decided)

- Web: static hosting (any CDN / nginx container) serving `web-app/dist/`.
- macOS / iOS shells: distribute via the native wrappers in `shells/`.

## CI/CD posture

CI (`.github/workflows/ci.yml`) runs lint + typecheck + build on every PR and push to `main`. The built `web-app/dist` artifact is uploaded per run for downstream deploy automation.
