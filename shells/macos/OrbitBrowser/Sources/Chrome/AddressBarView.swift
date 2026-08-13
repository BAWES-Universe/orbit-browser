import AppKit
import QuartzCore

/// Glass address bar: rounded translucent field with a lock/identity dot,
/// used in the unified toolbar.
@MainActor
final class AddressBarView: NSView {

    var onNavigate: ((String) -> Void)?

    private let field = NSTextField()
    private let lockDot = NSView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("AddressBarView: NSCoding not supported")
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = Theme.pillRadius
        layer?.backgroundColor = Theme.surfaceGlass.cgColor
        layer?.borderWidth = 1
        layer?.borderColor = Theme.hairline.cgColor

        lockDot.wantsLayer = true
        lockDot.layer?.cornerRadius = 4
        lockDot.layer?.backgroundColor = Theme.bananaGold.cgColor
        lockDot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lockDot)

        field.isBordered = false
        field.drawsBackground = false
        field.font = .systemFont(ofSize: 13)
        field.textColor = Theme.textPrimary
        field.placeholderString = "Search or enter address"
        field.focusRingType = .none
        field.target = self
        field.action = #selector(submit(_:))
        field.translatesAutoresizingMaskIntoConstraints = false
        addSubview(field)

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
    }

    @objc private func submit(_ sender: NSTextField) {
        let value = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        onNavigate?(value)
    }
}
