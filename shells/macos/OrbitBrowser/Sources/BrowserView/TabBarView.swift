import AppKit

/// Horizontal tab strip. Q1: one button per tab (click to select) plus a
/// "+" button to open a new tab. Rebuilt on every chrome update — cheap at
/// this scale, and keeps selection state trivially correct.
@MainActor
final class TabBarView: NSView {

    var onSelectTab: ((Int) -> Void)?
    var onNewTab: (() -> Void)?

    private let stack = NSStackView()
    private let newTabButton = NSButton()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        stack.orientation = .horizontal
        stack.spacing = 4
        stack.edgeInsets = NSEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        newTabButton.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "New Tab")
        newTabButton.bezelStyle = .rounded
        newTabButton.target = self
        newTabButton.action = #selector(newTabPressed(_:))
        newTabButton.toolTip = "New Tab"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("OrbitBrowser: NSCoding not supported")
    }

    func update(tabs: [BrowserTab], selectedIndex: Int) {
        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for (index, tab) in tabs.enumerated() {
            let button = NSButton(title: Self.title(for: tab), target: self, action: #selector(tabPressed(_:)))
            button.tag = index
            button.bezelStyle = .rounded
            button.setButtonType(.pushOnPushOff)
            button.state = (index == selectedIndex) ? .on : .off
            stack.addArrangedSubview(button)
        }

        stack.addArrangedSubview(newTabButton)
    }

    private static func title(for tab: BrowserTab) -> String {
        let pageTitle = tab.webView.title ?? ""
        let host = tab.webView.url?.host
        let base = pageTitle.isEmpty ? (host ?? "New Tab") : pageTitle
        return base.count > 24 ? String(base.prefix(24)) + "…" : base
    }

    @objc private func tabPressed(_ sender: NSButton) {
        onSelectTab?(sender.tag)
    }

    @objc private func newTabPressed(_ sender: NSButton) {
        onNewTab?()
    }
}
