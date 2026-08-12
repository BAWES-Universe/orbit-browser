# Orbit Browser — Build Spec

Source of truth for the initial scaffold. Derived from fleet consensus (2026-08-12: APPROVE + amendment) and the build-spec sections distributed by brick.

## Product framing

Orbit Browser is **the door, not the product** — a hardened shell browser for the BAWES Universe.

- **Thin shell only**: maintained Chromium fork (macOS) / WebKit (iOS mandated) base. **Zero browser internals built in-house** (no engine, no network stack, no rendering core).
- **Owned surface**: rules-enforcement UI, Comet-like AI assist, preloads, identity.
- **One identity, one door** — consumer ladder: Explorer → Participant → Contributor → Core; people can be promoted to operators.

## Scope

| In scope | Explicitly out of scope |
| --- | --- |
| Web-app shell (this scaffold) | Browser engine internals |
| Rules-enforcement UI | Network stack |
| AI assist (Comet-like) | Rendering core |
| Preloads | History/sync services |
| Identity integration | |

## Preload order (locked)

1. Orbit (the loop)
2. Registry identity (PR #2)
3. Universe assets

## Sequencing

Identity spine → MCP → universe bot → **Orbit Browser as the door**. The browser consumes the spine + MCP, so it lands last in the chain.

## Repository layout

```
web-app/                 Vite + React + TypeScript PWA, Workbox service worker
shells/
  macos/                 macOS shell (scaffold; WebKit/Chromium wrapper)
  ios/                   iOS shell (scaffold; WKWebView wrapper)
  shared/                @orbit/shell-shared — bridge contract, shared by both shells
shared/                  @orbit/shared — cross-cutting types & constants
infra/                   Docker + nginx for the web-app
docs/                    This spec + operations docs
.github/workflows/       CI
```

## CI requirements (like leading providers)

- Runs on every PR and push to `main`.
- Steps: **lint → typecheck → build** (all workspaces).
- Node matrix (20, 22), npm cache, build artifact upload.
- Merging to `main` requires all green.

## Verification

```bash
npm install
npm run lint        # eslint, zero warnings allowed
npm run typecheck   # tsc --noEmit, strict
npm run build       # production builds; web-app emits PWA into web-app/dist/
```
