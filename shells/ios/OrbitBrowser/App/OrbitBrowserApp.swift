import SwiftUI

/// Orbit Browser — iOS shell entry point.
///
/// Thin WKWebView wrapper hosting the Orbit web-app. Zero browser internals
/// (iOS mandates WebKit per fleet consensus 2026-08-12). The bridge contract
/// lives in `shells/shared` (`@orbit/shell-shared`) — one protocol, both
/// platforms.
@main
struct OrbitBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
