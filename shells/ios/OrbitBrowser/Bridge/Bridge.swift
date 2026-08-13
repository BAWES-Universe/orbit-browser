import Foundation
import WebKit

/// Q1 shell <-> web bridge (stub). iOS twin of `shells/macos` Bridge.swift —
/// same handler name, same preload source, same contract.
///
/// Installs a `window.orbitBridge.post(payload)` preload into every web view
/// and logs anything the page posts. This is the seam where rules-enforcement
/// UI, AI assist, preloads and identity will hook in — deliberately log-only
/// for now, per build-spec: "thin shell only".
@MainActor
final class Bridge: NSObject, WKScriptMessageHandler {

    static let handlerName = "orbitBridge"

    private static let preloadSource = """
    (function () {
      if (window.orbitBridge) { return; }
      window.orbitBridge = {
        post: function (payload) {
          window.webkit.messageHandlers.orbitBridge.postMessage(payload);
        }
      };
    })();
    """

    /// Attaches this bridge + preload script to a web view configuration.
    func install(into configuration: WKWebViewConfiguration) {
        let controller = configuration.userContentController
        controller.add(self, name: Self.handlerName)

        let script = WKUserScript(
            source: Self.preloadSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        controller.addUserScript(script)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == Self.handlerName else { return }
        NSLog("[orbitBridge] message from page: %@", String(describing: message.body))
    }
}
