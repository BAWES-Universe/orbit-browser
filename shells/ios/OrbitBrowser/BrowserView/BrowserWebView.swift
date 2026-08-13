import SwiftUI
import WebKit

/// WKWebView wrapper (UIViewRepresentable) hosting the Orbit web-app.
/// Owns the single shared `Bridge` instance for the session.
struct BrowserWebView: UIViewRepresentable {

    static let startPage = URL(string: "https://example.com")!

    let bridge: Bridge
    var onCreated: (WKWebView) -> Void = { _ in }
    var onNavigation: (WKWebView) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(onNavigation: onNavigation)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        bridge.install(into: configuration)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: Self.startPage))

        context.coordinator.webView = webView
        onCreated(webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onNavigation = onNavigation
    }

    /// Accepts a bare host (scheme-less) and prefixes https://. Mirrors the
    /// macOS shell's address-bar behavior.
    static func makeURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(string: "https://" + trimmed)
    }

    // MARK: - Coordinator (navigation delegate)

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var onNavigation: (WKWebView) -> Void

        init(onNavigation: @escaping (WKWebView) -> Void) {
            self.onNavigation = onNavigation
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            onNavigation(webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onNavigation(webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onNavigation(webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onNavigation(webView)
        }
    }
}
