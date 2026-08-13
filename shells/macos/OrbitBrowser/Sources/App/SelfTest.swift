import AppKit
import WebKit

/// Q-ORBIT-03: headless functional regression suite.
/// Run: OrbitBrowser --selftest  → prints JSON, exits 0 (pass) / 1 (fail).
/// Powers the E2E regression gate in CI (per brick's ratified receipt
/// standard: merged PR + green build + SELFTEST PASS + screenshot artifact).
@MainActor
enum SelfTest {

    static func run() -> Int32 {
        var checks: [[String: Any]] = []
        func check(_ name: String, _ ok: Bool) {
            checks.append(["name": name, "ok": ok])
            NSLog("[orbit-selftest] %@ %@", ok ? "PASS" : "FAIL", name)
        }

        // --- URL parsing (the address bar contract) ---
        check("makeURL: scheme-less gets https",
              BrowserWindowController.makeURL(from: "example.com")?.absoluteString == "https://example.com")
        check("makeURL: scheme preserved",
              BrowserWindowController.makeURL(from: "https://a.com")?.absoluteString == "https://a.com")
        check("makeURL: blank is nil",
              BrowserWindowController.makeURL(from: "   ") == nil)

        // --- Tab model (no GUI needed — drives the controller directly) ---
        let controller = BrowserWindowController()
        check("initial tab exists", controller.tabCount == 1)
        check("initial tab shows start page", controller.currentTabShowsStartPage)

        controller.newTab(nil)
        check("newTab adds a tab", controller.tabCount == 2)

        controller.closeTab(nil)
        check("closeTab leaves >=1 tab", controller.tabCount >= 1)

        controller.navigate("example.com")
        check("navigate leaves start page", !controller.currentTabShowsStartPage)

        // --- Bridge contract ---
        let configuration = WKWebViewConfiguration()
        Bridge().install(into: configuration)
        check("bridge installs preload script",
              configuration.userContentController.userScripts.count > 0)

        // --- Start page rendering helpers ---
        let wordmark = StartPageView.gradientText("Orbit", colors: [.white, .black], fontSize: 20)
        check("gradient wordmark renders",
              wordmark.size.width > 10 && wordmark.size.height > 5)

        let allPass = checks.allSatisfy { ($0["ok"] as? Bool) == true }
        let payload: [String: Any] = ["selftest": allPass ? "pass" : "fail", "checks": checks]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
           let text = String(data: data, encoding: .utf8) {
            print(text)
        }
        return allPass ? 0 : 1
    }
}
