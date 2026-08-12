import AppKit
import WebKit

/// The browser chrome surface: tab strip + navigation toolbar + web view
/// host. Owns the tab model and routes toolbar actions to the selected tab.
@MainActor
final class BrowserWindowController: NSWindowController {

    /// Default start page (Q1). A bundled start page via WKURLSchemeHandler
    /// is a later iteration.
    static let startPage = URL(string: "https://example.com")!

    private let bridge = Bridge()
    private var tabs: [BrowserTab] = []
    private var selectedIndex = 0

    // Chrome views
    private let tabBarView = TabBarView()
    private let addressField = NSTextField(string: "")
    private let backButton = NSButton()
    private let forwardButton = NSButton()
    private let reloadButton = NSButton()
    private let webViewHost = NSView()

    private var selectedTab: BrowserTab? {
        tabs.indices.contains(selectedIndex) ? tabs[selectedIndex] : nil
    }

    // MARK: - Lifecycle

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Orbit Browser"
        window.setFrameAutosaveName("OrbitBrowserMainWindow")
        window.center()

        super.init(window: window)

        buildChrome()
        addTab(loading: Self.startPage)
        updateChrome()
        window.makeFirstResponder(addressField)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("OrbitBrowser: NSCoding not supported")
    }

    // MARK: - Chrome construction

    private func buildChrome() {
        guard let contentView = window?.contentView else { return }

        tabBarView.onSelectTab = { [weak self] index in self?.selectTab(at: index) }
        tabBarView.onNewTab = { [weak self] in self?.newTab(nil) }

        let toolbar = NSStackView()
        toolbar.orientation = .horizontal
        toolbar.spacing = 6
        toolbar.edgeInsets = NSEdgeInsets(top: 7, left: 8, bottom: 7, right: 8)
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        configure(backButton, symbol: "chevron.backward", action: #selector(goBack(_:)), toolTip: "Back")
        configure(forwardButton, symbol: "chevron.forward", action: #selector(goForward(_:)), toolTip: "Forward")
        configure(reloadButton, symbol: "arrow.clockwise", action: #selector(reload(_:)), toolTip: "Reload")

        addressField.placeholderString = "Enter address"
        addressField.font = .systemFont(ofSize: 13)
        addressField.target = self
        addressField.action = #selector(navigate(_:))
        addressField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addressField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        toolbar.addArrangedSubview(backButton)
        toolbar.addArrangedSubview(forwardButton)
        toolbar.addArrangedSubview(reloadButton)
        toolbar.addArrangedSubview(addressField)

        contentView.addSubview(tabBarView)
        contentView.addSubview(toolbar)
        contentView.addSubview(webViewHost)

        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        webViewHost.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tabBarView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tabBarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tabBarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tabBarView.heightAnchor.constraint(equalToConstant: 34),

            toolbar.topAnchor.constraint(equalTo: tabBarView.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 38),

            webViewHost.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            webViewHost.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            webViewHost.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            webViewHost.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    private func configure(_ button: NSButton, symbol: String, action: Selector, toolTip: String) {
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: toolTip)
        button.bezelStyle = .rounded
        button.target = self
        button.action = action
        button.toolTip = toolTip
    }

    // MARK: - Tab management

    @objc func newTab(_ sender: Any?) {
        addTab(loading: Self.startPage)
    }

    @discardableResult
    private func addTab(loading url: URL) -> BrowserTab {
        let tab = BrowserTab(bridge: bridge)
        tab.onNavigationUpdate = { [weak self] in self?.updateChrome() }
        tabs.append(tab)
        selectedIndex = tabs.count - 1
        attachWebView(tab.webView)
        tab.load(url)
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
        for subview in webViewHost.subviews {
            subview.removeFromSuperview()
        }
        webView.translatesAutoresizingMaskIntoConstraints = false
        webViewHost.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: webViewHost.topAnchor),
            webView.leadingAnchor.constraint(equalTo: webViewHost.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webViewHost.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: webViewHost.bottomAnchor),
        ])
    }

    private func updateChrome() {
        guard let tab = selectedTab else { return }
        addressField.stringValue = tab.webView.url?.absoluteString ?? ""
        backButton.isEnabled = tab.webView.canGoBack
        forwardButton.isEnabled = tab.webView.canGoForward
        tabBarView.update(tabs: tabs, selectedIndex: selectedIndex)
    }

    // MARK: - Toolbar actions

    @objc private func goBack(_ sender: Any?) {
        selectedTab?.webView.goBack()
    }

    @objc private func goForward(_ sender: Any?) {
        selectedTab?.webView.goForward()
    }

    @objc private func reload(_ sender: Any?) {
        selectedTab?.webView.reload()
    }

    @objc private func navigate(_ sender: NSTextField) {
        guard let url = Self.makeURL(from: sender.stringValue) else { return }
        selectedTab?.load(url)
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
