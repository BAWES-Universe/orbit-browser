# iOS Shell (scaffold)

Thin WKWebView wrapper hosting the Orbit web-app for iOS.

**Status: scaffold only — no native code yet.**

## Planned layout

```
ios/
  OrbitBrowser.xcodeproj
  OrbitBrowser/
    App/                  SwiftUI app entry point
    BrowserView/          WKWebView wrapper
    Bridge/               shell↔web bridge (see shells/shared)
```

## Principles (fleet consensus, 2026-08-12)

- iOS **mandates WebKit** — the thin-shell decision is not optional here; we host the web-app and own zero engine code.
- Same bridge contract as macOS (`@orbit/shell-shared`) — one protocol, both platforms.
- PWA support via WKWebView + the Workbox service worker from `web-app/`.

## Getting started (once native work begins)

```bash
# Requires Xcode + iOS toolchain on the host
open OrbitBrowser.xcodeproj
```
