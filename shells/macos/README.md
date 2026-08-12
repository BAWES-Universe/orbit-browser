# macOS Shell (scaffold)

Thin WebKit/Chromium wrapper hosting the Orbit web-app for macOS.

**Status: scaffold only — no native code yet.**

## Planned layout

```
macos/
  OrbitBrowser/            Swift package / Xcode project
    Sources/
      App/                 NSApplication entry point
      BrowserView/         WKWebView wrapper
      Bridge/              shell↔web bridge (see shells/shared)
    Resources/
```

## Principles (fleet consensus, 2026-08-12)

- **Thin shell.** Zero browser internals. Host the web-app; expose bridge.
- Bridge contract lives in `../shared` (`@orbit/shell-shared`) — no drift between shells.
- Preloads: Orbit loop → registry identity → Universe assets, in that order.

## Getting started (once native work begins)

```bash
# Requires Xcode + Swift toolchain on the host
xcodegen generate  # or open the .xcodeproj directly
```
