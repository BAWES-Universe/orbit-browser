import AppKit
import QuartzCore

/// Floating pill tab strip: draggable tabs with a favicon dot + title and a
/// close button, active tab elevated with a gold underline, plus a "+" pill.
@MainActor
final class TabStripView: NSView {

    var onSelect: ((Int) -> Void)?
    var onNewTab: (() -> Void)?
    var onClose: ((Int) -> Void)?
    var onReorder: ((Int, Int) -> Void)?  // from, to

    private let stack = NSStackView()
    private var tabCells: [TabCellView] = []

    private var draggingCell: TabCellView?
    private var dragFromIndex = -1

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
        for cell in tabCells {
            cell.removeFromSuperview()
        }
        tabCells.removeAll()
        draggingCell = nil

        for (index, title) in titles.enumerated() {
            let cell = TabCellView(title: title, selected: index == selectedIndex)
            cell.onSelect = { [weak self, weak cell] in
                guard let self, let cell else { return }
                self.onSelect?(self.tabCells.firstIndex(of: cell) ?? index)
            }
            cell.onClose = { [weak self, weak cell] in
                guard let self, let cell else { return }
                self.onClose?(self.tabCells.firstIndex(of: cell) ?? index)
            }
            cell.onDrag = { [weak self, weak cell] dx, dy in
                guard let self, let cell else { return }
                self.handleDrag(cell, dx: dx)
            }
            cell.onDrop = { [weak self, weak cell] in
                guard let self, let cell else { return }
                self.commitDrag(cell)
            }
            stack.insertArrangedSubview(cell, at: max(0, stack.arrangedSubviews.count - 1))
            tabCells.append(cell)
        }
    }

    // MARK: - Drag reorder

    private func handleDrag(_ cell: TabCellView, dx: CGFloat) {
        guard let from = tabCells.firstIndex(of: cell) else { return }
        if draggingCell == nil {
            draggingCell = cell
            dragFromIndex = from
            cell.alphaValue = 0.55
        }
        let midX = cell.frame.midX + dx
        // Drop slot = count of other cells whose midpoint is left of us.
        var slot = 0
        for other in tabCells where other !== cell {
            if other.frame.midX < midX { slot += 1 }
        }
        if slot != from {
            stack.removeArrangedSubview(cell)
            stack.insertArrangedSubview(cell, at: min(slot, tabCells.count - 1))
            tabCells.remove(at: from)
            tabCells.insert(cell, at: min(slot, tabCells.count - 1))
        }
    }

    private func commitDrag(_ cell: TabCellView) {
        cell.alphaValue = 1
        guard let to = tabCells.firstIndex(of: cell), draggingCell != nil, dragFromIndex != to else {
            draggingCell = nil
            return
        }
        onReorder?(dragFromIndex, to)
        draggingCell = nil
    }

    // MARK: - Buttons

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

    @objc private func newTabPressed(_ sender: NSButton) {
        onNewTab?()
    }
}

/// A single tab pill: custom-drawn dot + title, always-visible close button.
/// Click selects; drag reorders.
@MainActor
final class TabCellView: NSView {

    var onSelect: (() -> Void)?
    var onClose: (() -> Void)?
    var onDrag: ((CGFloat, CGFloat) -> Void)?
    var onDrop: (() -> Void)?

    private let title: String
    private let selected: Bool
    private let closeButton = NSButton()
    private var dragStart: NSPoint?

    init(title: String, selected: Bool) {
        self.title = title
        self.selected = selected
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.backgroundColor = (selected ? Theme.surfaceGlassElevated : Theme.surfaceGlass).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = (selected ? Theme.bananaGold.withAlphaComponent(0.55) : Theme.hairline).cgColor

        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close Tab")
        closeButton.contentTintColor = Theme.textSecondary
        closeButton.isBordered = false
        closeButton.bezelStyle = .regularSquare
        closeButton.wantsLayer = true
        closeButton.layer?.cornerRadius = 8
        closeButton.target = self
        closeButton.action = #selector(closePressed(_:))
        closeButton.toolTip = "Close Tab (⌘W)"
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 16),
            closeButton.heightAnchor.constraint(equalToConstant: 16),
        ])

        let textWidth = NSAttributedString(
            string: "  ●  \(title)",
            attributes: [.font: NSFont.systemFont(ofSize: 12.5)]
        ).size().width
        widthAnchor.constraint(equalToConstant: ceil(textWidth) + 34).isActive = true
        heightAnchor.constraint(equalToConstant: 28).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("TabCellView: NSCoding not supported")
    }

    override func draw(_ dirtyRect: NSRect) {
        if selected {
            let bar = NSBezierPath(roundedRect: NSRect(x: bounds.midX - 12, y: 3, width: 24, height: 2.5),
                                   xRadius: 1.25, yRadius: 1.25)
            Theme.bananaGold.withAlphaComponent(0.9).setFill()
            bar.fill()
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12.5, weight: selected ? .semibold : .regular),
            .foregroundColor: selected ? Theme.textPrimary : Theme.textSecondary,
        ]
        let text = "  ●  \(title)" as NSString
        let size = text.size(withAttributes: attributes)
        text.draw(at: NSPoint(x: 12, y: (bounds.height - size.height) / 2), withAttributes: attributes)
    }

    // MARK: - Mouse

    override func mouseDown(with event: NSEvent) {
        dragStart = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart else { return }
        let p = convert(event.locationInWindow, from: nil)
        onDrag?(p.x - start.x, p.y - start.y)
    }

    override func mouseUp(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if let start = dragStart, abs(p.x - start.x) > 3 {
            onDrop?()
        } else {
            onSelect?()
        }
        dragStart = nil
    }

    @objc private func closePressed(_ sender: NSButton) {
        onClose?()
    }
}
