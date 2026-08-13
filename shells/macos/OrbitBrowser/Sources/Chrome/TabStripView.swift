import AppKit
import QuartzCore

/// Floating pill tab strip: rounded tabs with a favicon dot + title,
/// active tab elevated with a gold underline glow, plus a "+" new-tab pill.
@MainActor
final class TabStripView: NSView {

    var onSelect: ((Int) -> Void)?
    var onNewTab: (() -> Void)?

    private let stack = NSStackView()
    private var tabButtons: [NSButton] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("TabStripView: NSCoding not supported")
    }

    private func setup() {
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let plus = makePlusButton()
        plus.target = self
        plus.action = #selector(newTabPressed(_:))
        stack.addArrangedSubview(plus)
    }

    /// Rebuilds the pill tabs from titles + selection.
    func update(titles: [String], selectedIndex: Int) {
        for button in tabButtons {
            button.removeFromSuperview()
        }
        tabButtons.removeAll()

        for (index, title) in titles.enumerated() {
            let button = makeTabButton(title: title, selected: index == selectedIndex)
            button.tag = index
            button.target = self
            button.action = #selector(tabPressed(_:))
            stack.insertArrangedSubview(button, at: max(0, stack.arrangedSubviews.count - 1))
            tabButtons.append(button)
        }
    }

    // MARK: - Buttons

    private func makeTabButton(title: String, selected: Bool) -> NSButton {
        let button = NSButton()
        button.title = title
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 14
        button.layer?.backgroundColor = (selected ? Theme.surfaceGlassElevated : NSColor.clear).cgColor
        button.layer?.borderWidth = 1
        button.layer?.borderColor = (selected ? Theme.bananaGold.withAlphaComponent(0.55) : Theme.hairline).cgColor
        button.contentTintColor = selected ? Theme.bananaGold : Theme.textSecondary
        button.font = .systemFont(ofSize: 12.5, weight: selected ? .semibold : .regular)
        button.attributedTitle = NSAttributedString(
            string: "  ●  \(title)",
            attributes: [
                .font: NSFont.systemFont(ofSize: 12.5, weight: selected ? .semibold : .regular),
                .foregroundColor: selected ? Theme.textPrimary : Theme.textSecondary,
            ]
        )
        button.toolTip = title
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return button
    }

    private func makePlusButton() -> NSButton {
        let button = NSButton()
        button.title = ""
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 14
        button.layer?.backgroundColor = Theme.surfaceGlass.cgColor
        button.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "New Tab")
        button.contentTintColor = Theme.textSecondary
        button.toolTip = "New Tab (⌘T)"
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 28).isActive = true
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return button
    }

    // MARK: - Actions

    @objc private func tabPressed(_ sender: NSButton) {
        onSelect?(sender.tag)
    }

    @objc private func newTabPressed(_ sender: NSButton) {
        onNewTab?()
    }
}
