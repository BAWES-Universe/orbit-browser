import AppKit
import WebKit

/// One tab = one WKWebView plus its navigation state.
/// Q1 keeps tabs deliberately dumb: each tab owns its web view; chrome
/// (toolbar / tab bar) lives in the window controller.
@MainActor
final class BrowserTab: NSObject, WKNavigationDelegate, WKUIDelegate {

    let webView: WKWebView

    /// Q-ORBIT-02: a tab starts on the native start page until the user
    /// navigates somewhere (then the web view takes over).
    var showsStartPage = true

    /// Called whenever committed navigation state changes so the chrome
    /// (address bar, back/forward enabled state, tab titles) can refresh.
    var onNavigationUpdate: (() -> Void)?

    /// Display title for the tab strip.
    var title: String {
        if let pageTitle = webView.title, !pageTitle.isEmpty {
            return pageTitle
        }
        return showsStartPage ? "New Tab" : "Untitled"
    }

    init(bridge: Bridge, frame: NSRect = .zero) {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        bridge.install(into: configuration)

        webView = WKWebView(frame: frame, configuration: configuration)
        super.init()

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true
        webView.appearance = NSAppearance(named: .darkAqua)
    }

    func load(_ url: URL) {
        showsStartPage = false
        webView.load(URLRequest(url: url))
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        onNavigationUpdate?()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onNavigationUpdate?()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("[orbit] navigation failed: %@", error.localizedDescription)
        onNavigationUpdate?()
    }

    // MARK: - WKUIDelegate

    /// Q1: no separate windows; `target=_blank` links simply do nothing.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }
}
