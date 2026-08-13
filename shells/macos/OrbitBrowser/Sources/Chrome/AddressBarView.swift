import AppKit
import QuartzCore

/// Focus-aware text field so the address bar can show a gold focus ring.
@MainActor
final class FocusField: NSTextField {
    var onFocusChange: ((Bool) -> Void)?

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        needsDisplay = true
    }

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if ok { onFocusChange?(true) }
        return ok
    }

    override func resignFirstResponder() -> Bool {
        let ok = super.resignFirstResponder()
        if ok { onFocusChange?(false) }
        return ok
    }
}

/// Glass address bar: rounded translucent field with a lock/identity dot,
/// used in the unified toolbar. Click anywhere on the pill to focus.
@MainActor
final class AddressBarView: NSView {

    var onNavigate: ((String) -> Void)?

    private let field = FocusField()
    private let lockDot = NSView()
    private var focused = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("AddressBarView: NSCoding not supported")
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Draw the pill behind the field (plain NSTextField text composites;
        // layer backgrounds on container views did not in this window).
        guard bounds.height > 4 else { return }
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
                                xRadius: bounds.height / 2, yRadius: bounds.height / 2)
        (focused
            ? NSColor(calibratedWhite: 1, alpha: 0.30)
            : NSColor(calibratedWhite: 1, alpha: 0.22)).setFill()
        path.fill()
        (focused
            ? Theme.bananaGold.withAlphaComponent(0.75)
            : NSColor(calibratedWhite: 1, alpha: 0.35)).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    private func setup() {
        // Plain transparent container — the pill is drawn as a sublayer of the
        // toolbar (see ToolbarView.layout), which composites reliably, and the
        // field is a plain NSTextField (text composites reliably — same as the
        // start page search field).

        lockDot.wantsLayer = true
        lockDot.layer?.cornerRadius = 4
        lockDot.layer?.backgroundColor = Theme.bananaGold.cgColor
        lockDot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lockDot)

        field.isBordered = false
        field.drawsBackground = false
        field.font = .systemFont(ofSize: 13)
        field.textColor = Theme.textPrimary
        field.placeholderAttributedString = NSAttributedString(
            string: "Search or enter address",
            attributes: [.foregroundColor: NSColor(calibratedWhite: 0.75, alpha: 1)]
        )
        field.focusRingType = .none
        field.target = self
        field.action = #selector(submit(_:))
        field.translatesAutoresizingMaskIntoConstraints = false
        addSubview(field)

        // Click anywhere on the pill focuses the field.
        let click = NSClickGestureRecognizer(target: self, action: #selector(clicked(_:)))
        addGestureRecognizer(click)

        // Gold ring + brighter glass while focused.
        field.onFocusChange = { [weak self] focused in
            self?.focused = focused
            self?.needsDisplay = true
        }

        NSLayoutConstraint.activate([
            lockDot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            lockDot.centerYAnchor.constraint(equalTo: centerYAnchor),
            lockDot.widthAnchor.constraint(equalToConstant: 8),
            lockDot.heightAnchor.constraint(equalToConstant: 8),

            field.leadingAnchor.constraint(equalTo: lockDot.trailingAnchor, constant: 10),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            field.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        heightAnchor.constraint(equalToConstant: 32).isActive = true
    }

    func setURL(_ string: String) {
        if field.currentEditor() == nil {
            field.stringValue = string
        }
    }

    func focusField() {
        window?.makeFirstResponder(field)
        field.currentEditor()?.selectAll(nil)
    }

    @objc private func clicked(_ sender: NSClickGestureRecognizer) {
        focusField()
    }

    @objc private func submit(_ sender: NSTextField) {
        let value = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        onNavigate?(value)
    }
}
