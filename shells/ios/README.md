# iOS Shell

Thin WKWebView wrapper hosting the Orbit web-app for iOS. **Native code landed
(Q-ORBIT-02)** — SwiftUI entry point, WKWebView wrapper, and the same
shell↔web bridge contract as macOS. **Q1 chrome:** address bar, back/forward,
reload, WKWebView host.

## Layout

```
ios/
  OrbitBrowser.xcodeproj        hand-authored Xcode project (objectVersion 46)
    xcshareddata/xcschemes/     shared scheme for headless xcodebuild
  OrbitBrowser/
    App/                        SwiftUI app entry point (@main)
    BrowserView/                WKWebView wrapper (UIViewRepresentable) + chrome
    Bridge/                     shell↔web bridge (same contract as macOS shell)
    Assets.xcassets             AppIcon + accent color
    Info.plist                  com.bawes.orbitbrowser
```

## Principles (fleet consensus, 2026-08-12)

- iOS **mandates WebKit** — the thin-shell decision is not optional here; we
  host the web-app and own zero engine code.
- Same bridge contract as macOS (`@orbit/shell-shared`) — one protocol, both
  platforms: `window.orbitBridge.post(payload)` preload, log-only for Q1.
- PWA support via WKWebView + the Workbox service worker from `web-app/`.

## Build

Requires Xcode (macOS runners in CI; local Mac is CLT-only, so CI builds
here). Signing disabled for CI verification builds:

```bash
# macOS runner
xcodebuild -project OrbitBrowser.xcodeproj -scheme OrbitBrowser \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```
