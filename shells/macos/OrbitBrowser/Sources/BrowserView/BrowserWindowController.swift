import AppKit
import WebKit

/// The browser chrome surface (Q-ORBIT-02): unified glass toolbar with
/// floating pill tabs + address bar + actions, native start page, and the
/// web view host. Owns the tab model and routes chrome actions to the
/// selected tab.
@MainActor
final class BrowserWindowController: NSWindowController {

    /// Fallback start URL for tabs that leave the start page (not used for
    /// new tabs — those get the native start page).
    static let startPage = URL(string: "https://example.com")!

    private let bridge = Bridge()
    private var tabs: [BrowserTab] = []
    private var selectedIndex = 0

    // Chrome
    private let toolbar = ToolbarView()
    private let webViewHost = NSView()
    private let startPageView = StartPageView()

    private var selectedTab: BrowserTab? {
        tabs.indices.contains(selectedIndex) ? tabs[selectedIndex] : nil
    }

    // MARK: - Selftest hooks (--selftest mode)

    var tabCount: Int { tabs.count }
    var currentTabShowsStartPage: Bool { selectedTab?.showsStartPage ?? false }

    // MARK: - Lifecycle

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Orbit Browser"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = Theme.background
        window.setFrameAutosaveName("OrbitBrowserMainWindow")
        window.center()

        super.init(window: window)

        buildChrome()
        newTab(nil)
        updateChrome()
        startPageView.focusField()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("OrbitBrowser: NSCoding not supported")
    }

    // MARK: - Chrome construction

    private func buildChrome() {
        guard let contentView = window?.contentView else { return }

        // Force the whole window into the layer-backed rendering path.
        // Mixing layer-backed and non-layer-backed views in a non-layer-backed
        // contentView selectively breaks compositing (the address bar never
        // appeared on screen while its siblings did).
        contentView.wantsLayer = true

        toolbar.tabStrip.onSelect = { [weak self] index in self?.selectTab(at: index) }
        toolbar.tabStrip.onNewTab = { [weak self] in self?.newTab(nil) }
        toolbar.tabStrip.onClose = { [weak self] index in self?.closeTab(at: index) }
        toolbar.tabStrip.onReorder = { [weak self] from, to in self?.moveTab(from: from, to: to) }
        toolbar.addressBar.onNavigate = { [weak self] raw in self?.navigate(raw) }
        toolbar.onBack = { [weak self] in self?.selectedTab?.webView.goBack() }
        toolbar.onForward = { [weak self] in self?.selectedTab?.webView.goForward() }
        toolbar.onReload = { [weak self] in self?.selectedTab?.webView.reload() }

        startPageView.onNavigate = { [weak self] raw in self?.navigate(raw) }
        startPageView.onOpenURL = { [weak self] url in self?.navigate(url.absoluteString) }

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        webViewHost.translatesAutoresizingMaskIntoConstraints = false
        startPageView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(toolbar)
        contentView.addSubview(webViewHost)
        webViewHost.addSubview(startPageView)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: contentView.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: Theme.stripHeight),

            webViewHost.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            webViewHost.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            webViewHost.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            webViewHost.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            startPageView.topAnchor.constraint(equalTo: webViewHost.topAnchor),
            startPageView.leadingAnchor.constraint(equalTo: webViewHost.leadingAnchor),
            startPageView.trailingAnchor.constraint(equalTo: webViewHost.trailingAnchor),
            startPageView.bottomAnchor.constraint(equalTo: webViewHost.bottomAnchor),
        ])
    }

    // MARK: - Tab management

    @objc func newTab(_ sender: Any?) {
        addTab(loading: nil)
    }

    @objc func closeTab(_ sender: Any?) {
        closeTab(at: selectedIndex)
    }

    /// Closes the tab at `index`, keeping selection sane and never leaving
    /// the window tab-less.
    func closeTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        let wasSelected = index == selectedIndex
        tabs.remove(at: index)
        if tabs.isEmpty {
            addTab(loading: nil)
        } else {
            if wasSelected {
                selectedIndex = min(index, tabs.count - 1)
                attachWebView(tabs[selectedIndex].webView)
            } else if index < selectedIndex {
                selectedIndex -= 1
            }
        }
        updateChrome()
    }

    /// Reorders tabs (drag in the tab strip); selection follows the moved tab.
    func moveTab(from: Int, to: Int) {
        guard tabs.indices.contains(from), tabs.indices.contains(to), from != to else { return }
        let tab = tabs.remove(at: from)
        tabs.insert(tab, at: to)
        if selectedIndex == from {
            selectedIndex = to
        } else if from < selectedIndex, to >= selectedIndex {
            selectedIndex -= 1
        } else if from > selectedIndex, to <= selectedIndex {
            selectedIndex += 1
        }
        updateChrome()
    }

    @objc func nextTab(_ sender: Any?) {
        guard !tabs.isEmpty else { return }
        selectTab(at: (selectedIndex + 1) % tabs.count)
    }

    @objc func previousTab(_ sender: Any?) {
        guard !tabs.isEmpty else { return }
        selectTab(at: (selectedIndex - 1 + tabs.count) % tabs.count)
    }

    @objc func selectTabNumber(_ sender: NSMenuItem) {
        let index = sender.tag
        guard index >= 0, index < tabs.count else { return }
        selectTab(at: index)
    }

    @discardableResult
    private func addTab(loading url: URL?) -> BrowserTab {
        let tab = BrowserTab(bridge: bridge)
        tab.onNavigationUpdate = { [weak self] in self?.updateChrome() }
        tabs.append(tab)
        selectedIndex = tabs.count - 1
        attachWebView(tab.webView)
        if let url {
            tab.load(url)
        }
        updateChrome()
        return tab
    }

    private func selectTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        selectedIndex = index
        attachWebView(tabs[index].webView)
        updateChrome()
    }

    private func attachWebView(_ webView: WKWebView) {
        for subview in webViewHost.subviews where subview !== startPageView {
            subview.removeFromSuperview()
        }
        webView.translatesAutoresizingMaskIntoConstraints = false
        webViewHost.addSubview(webView, positioned: .below, relativeTo: startPageView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: webViewHost.topAnchor),
            webView.leadingAnchor.constraint(equalTo: webViewHost.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webViewHost.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: webViewHost.bottomAnchor),
        ])
    }

    // MARK: - Chrome state

    /// Tracks the last tab whose chrome state we rendered, so autofocus fires
    /// only on a real transition into the start page (new/selected tab or a
    /// navigation back to it) — not when a background tab finishes loading.
    private var lastChromeTab: BrowserTab?
    private var lastChromeShowedStartPage = false

    private func updateChrome() {
        guard let tab = selectedTab else { return }

        startPageView.isHidden = !tab.showsStartPage

        let urlString = tab.showsStartPage ? "" : (tab.webView.url?.absoluteString ?? "")
        toolbar.addressBar.setURL(urlString)
        toolbar.setNavigation(canGoBack: tab.webView.canGoBack, canGoForward: tab.webView.canGoForward)
        toolbar.updateTabs(titles: tabs.map(\.title), selectedIndex: selectedIndex)

        if tab.showsStartPage {
            // Autofocus only when the *selected* tab just entered the start
            // page. A background tab's onNavigationUpdate re-runs this and
            // must not steal focus from the address bar or page content.
            let selectedTabChanged = tab !== lastChromeTab
            let enteredStartPage = selectedTabChanged || !lastChromeShowedStartPage
            if enteredStartPage {
                startPageView.focusFieldIfNeeded()
            }
        }
        lastChromeTab = tab
        lastChromeShowedStartPage = tab.showsStartPage
    }

    // MARK: - Toolbar actions

    @objc func focusAddressBar(_ sender: Any?) {
        toolbar.addressBar.focusField()
    }

    func navigate(_ raw: String) {
        guard let url = Self.makeURL(from: raw) else { return }
        selectedTab?.load(url)
        updateChrome()
    }

    /// Accepts a bare host (scheme-less) and prefixes https://.
    static func makeURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(string: "https://" + trimmed)
    }
}
