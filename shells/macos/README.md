# macOS Shell

Thin WebKit wrapper hosting the Orbit web-app for macOS. **Q-ORBIT-01: native
shell landed** — builds and assembles with the Command Line Tools toolchain
only (no Xcode, no xcodebuild).

**Status:** Q2 chrome redesign landed. Compiles clean, bundles into a signed
`OrbitBrowser.app`. GUI launch verified live (khalid).

## Layout

```
macos/
  OrbitBrowser/            SwiftPM executable package
    Package.swift          swift-tools 6.0; links WebKit + AppKit
    Info.plist             app bundle plist (com.bawes.orbitbrowser)
    Sources/
      App/                 NSApplication entry point + programmatic main menu
      BrowserView/         WKWebView wrapper, window controller
      Chrome/              Theme.swift tokens + TabStrip, AddressBar, Toolbar,
                           StartPage (glass chrome + native start page)
      Bridge/              shell↔web bridge stub (window.orbitBridge.post)
  scripts/
    build-app.sh           build → assemble → lint → ad-hoc sign → verify
  build/                   assembled OrbitBrowser.app (gitignored)
```

## What the shell does

- Custom glass window (hidden titlebar, dark-first): floating pill tab strip,
  unified toolbar with glass address bar, back/forward/reload, and pending
  placeholders (shield = rules, sparkles = AI, avatar = identity).
- Native start page on new tab: dark gradient, drifting indigo/violet/gold
  orbs, gradient "Orbit" wordmark, glass search field + quick-link tiles.
- Tabs: ⌘T new, ⌘W close, ⌘1–9 switch, ⇧⌘]/[ next/prev; ⌘L focuses the
  address bar. Scheme-less input gets `https://`.
- Each tab owns its own `WKWebView`. Bridge stub: `window.orbitBridge.post`
  preload logs to the native side — the seam where rules-enforcement UI /
  AI assist / preloads / identity hook in (Q-ORBIT-06/07).
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
