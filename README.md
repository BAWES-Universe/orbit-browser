# Orbit Browser

**Hardened shell browser for the BAWES Universe.**

Orbit Browser is the *door*, not the product. Per fleet consensus (2026-08-12, APPROVE + amendment): a **thin hardened shell** on a maintained Chromium fork / WebView base — **zero browser internals built in-house**. We own only:

- **Rules-enforcement UI** — Universe rules enforced in the browsing UI
- **Comet-like AI assist** — inline agent assist
- **Preloads** — Orbit (the loop) → registry identity → Universe assets, in that order
- **Identity** — one identity, one door (Explorer → Participant → Contributor → Core)

## Repository layout (monorepo)

```
web-app/                 Vite + React + TypeScript PWA (Workbox-powered service worker)
shells/
  macos/                 macOS shell (WebKit/Chromium wrapper scaffold)
  ios/                   iOS shell (WKWebView wrapper scaffold)
  shared/                Shared shell-layer types & protocols
shared/                  Shared packages: types, config, utilities
infra/                   Docker, deploy, and hosting configuration
docs/                    Architecture, build spec, and operations docs
.github/workflows/       CI: lint + typecheck + build on PR and main
```

## Quick start

```bash
npm install          # install all workspaces
npm run dev          # run the web-app dev server
npm run lint         # eslint across workspaces
npm run typecheck    # tsc --noEmit across workspaces
npm run build        # production build (web-app PWA output in web-app/dist/)
```

## CI

`.github/workflows/ci.yml` runs on every PR (and push to `main`):

1. **Lint** — ESLint across all workspaces
2. **Typecheck** — strict `tsc --noEmit` across all workspaces
3. **Build** — production builds for every workspace (web-app → Workbox PWA in `dist/`)

CI runs on Node 20 and 22 (matrix). Merging to `main` requires all green.

## Status

- [x] Monorepo scaffold (this commit)
- [ ] web-app shell UI
- [ ] Rules-enforcement layer
- [ ] macOS shell
- [ ] iOS shell
- [ ] Identity / preloads

---

Open source — NO sensitive data. See `docs/` for the full build spec.
