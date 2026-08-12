# macOS Shell

Thin WebKit wrapper hosting the Orbit web-app for macOS. **Q-ORBIT-01: native
shell landed** — builds and assembles with the Command Line Tools toolchain
only (no Xcode, no xcodebuild).

**Status:** Q1 chrome foundation. Compiles clean, bundles into a signed
`OrbitBrowser.app`. GUI launch is pending manual testing (khalid).

## Layout

```
macos/
  OrbitBrowser/            SwiftPM executable package
    Package.swift          swift-tools 6.0; links WebKit + AppKit
    Info.plist             app bundle plist (com.bawes.orbitbrowser)
    Sources/
      App/                 NSApplication entry point + programmatic main menu
      BrowserView/         WKWebView wrapper, window controller, tab strip
      Bridge/              shell↔web bridge stub (window.orbitBridge.post)
  scripts/
    build-app.sh           build → assemble → lint → ad-hoc sign → verify
  build/                   assembled OrbitBrowser.app (gitignored)
```

## What the shell does (Q1)

- One browser window: tab strip (new tab / select), toolbar (back / forward /
  reload), address bar (Enter navigates; scheme-less input gets `https://`).
- Each tab owns its own `WKWebView`. Default start page: `https://example.com`.
- Bridge stub: every web view gets a `window.orbitBridge.post(payload)` preload
  (WKUserScript); messages are logged by the native side. Log-only for Q1 —
  the seam where rules-enforcement UI / AI assist / preloads / identity hook in.
- No engine, no network stack, no rendering core — thin shell per
  `docs/build-spec.md`.

## Build (CLI tools only)

```bash
./scripts/build-app.sh          # swift build → .app → plutil lint → codesign → verify
open build/OrbitBrowser.app     # manual smoke test
```

## Verify

```bash
plutil -lint build/OrbitBrowser.app/Contents/Info.plist
codesign --verify --strict build/OrbitBrowser.app
file build/OrbitBrowser.app/Contents/MacOS/OrbitBrowser   # expect: arm64
```

## Principles (fleet consensus, 2026-08-12)

- **Thin shell.** Zero browser internals. Host the web-app; expose bridge.
- Bridge contract lives in `../shared` (`@orbit/shell-shared`) — no drift
  between shells.
- Preloads: Orbit loop → registry identity → Universe assets, in that order.
