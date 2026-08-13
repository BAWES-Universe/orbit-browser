import AppKit
import QuartzCore

/// The new-tab start page — the first thing the user sees.
/// Deep dark gradient, three slow-drifting gradient orbs (indigo / violet /
/// gold), gradient "Orbit" wordmark, a glass search field, and glass
/// quick-link tiles. Native NSView (no webview): "one identity, one door."
@MainActor
final class StartPageView: NSView {

    /// Called with the raw text when the user presses Return in the field.
    var onNavigate: ((String) -> Void)?

    private let fieldContainer = NSView()
    private let field = NSTextField()
    private var orbs: [(layer: CALayer, basePosition: CGPoint, radius: CGFloat, duration: CFTimeInterval)] = []
    private var orbsAnimated = false

    /// The start page's search field (for first-responder routing).
    var searchField: NSTextField { field }

    // MARK: - Lifecycle

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("StartPageView: NSCoding not supported")
    }

    override func layout() {
        super.layout()
        guard let root = layer else { return }
        root.sublayers?.first?.frame = bounds

        // Place orbs; start their drift animation once (positions are stable
        // afterwards so a relayout does not restart them).
        for (i, orb) in orbs.enumerated() {
            orb.layer.frame = CGRect(
                x: bounds.width * orb.basePosition.x - orb.radius / 2,
                y: bounds.height * orb.basePosition.y - orb.radius / 2,
                width: orb.radius,
                height: orb.radius
            )
            if !orbsAnimated {
                animateOrb(orb.layer, index: i)
            }
        }
        orbsAnimated = true
    }

    // MARK: - Setup

    private func setup() {
        wantsLayer = true

        // Base vertical gradient.
        let base = CAGradientLayer()
        base.colors = [Theme.background.cgColor, Theme.backgroundRaised.cgColor]
        base.startPoint = CGPoint(x: 0.5, y: 0)
        base.endPoint = CGPoint(x: 0.5, y: 1)
        layer?.addSublayer(base)

        // Floating orbs (soft radial feel via big-radius layers at low alpha).
        addOrb(color: Theme.indigo, radius: 360, position: CGPoint(x: 0.16, y: 0.28), duration: 22)
        addOrb(color: Theme.violet, radius: 300, position: CGPoint(x: 0.84, y: 0.22), duration: 27)
        addOrb(color: Theme.bananaGold, radius: 220, position: CGPoint(x: 0.62, y: 0.78), duration: 31)

        // Wordmark with gradient fill.
        let wordmark = NSImageView()
        wordmark.image = Self.gradientText("Orbit", colors: [Theme.bananaGold, Theme.indigo], fontSize: 44)
        wordmark.translatesAutoresizingMaskIntoConstraints = false
        addSubview(wordmark)

        // Tagline.
        let tagline = NSTextField(labelWithString: "One identity, one door.")
        tagline.font = .systemFont(ofSize: 14, weight: .regular)
        tagline.textColor = Theme.textSecondary
        tagline.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tagline)

        // Glass search field.
        fieldContainer.wantsLayer = true
        fieldContainer.layer?.cornerRadius = Theme.pillRadius
        fieldContainer.layer?.backgroundColor = Theme.surfaceGlass.cgColor
        fieldContainer.layer?.borderWidth = 1
        fieldContainer.layer?.borderColor = Theme.hairline.cgColor
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fieldContainer)

        field.isBordered = false
        field.drawsBackground = false
        field.font = .systemFont(ofSize: 15)
        field.textColor = Theme.textPrimary
        field.placeholderString = "Search or enter address"
        field.focusRingType = .none
        field.target = self
        field.action = #selector(submit(_:))
        field.translatesAutoresizingMaskIntoConstraints = false
        fieldContainer.addSubview(field)

        // Quick-link tiles (placeholders for the Universe surfaces).
        let tiles = [
            ("globe", "Universe"),
            ("orbit", "Orbit"),
            ("gauge.with.dots.needle.50percent", "Velocity"),
            ("books.vertical", "Docs"),
        ]
        let tileRow = NSStackView()
        tileRow.orientation = .horizontal
        tileRow.spacing = 14
        tileRow.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tileRow)

        for (symbol, title) in tiles {
            tileRow.addArrangedSubview(makeTile(symbol: symbol, title: title))
        }

        NSLayoutConstraint.activate([
            wordmark.centerXAnchor.constraint(equalTo: centerXAnchor),
            wordmark.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -70),

            tagline.topAnchor.constraint(equalTo: wordmark.bottomAnchor, constant: 10),
            tagline.centerXAnchor.constraint(equalTo: centerXAnchor),

            fieldContainer.topAnchor.constraint(equalTo: tagline.bottomAnchor, constant: 26),
            fieldContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            fieldContainer.widthAnchor.constraint(equalToConstant: 460),
            fieldContainer.heightAnchor.constraint(equalToConstant: 44),

            field.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 20),
            field.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -20),
            field.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),

            tileRow.topAnchor.constraint(equalTo: fieldContainer.bottomAnchor, constant: 34),
            tileRow.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    private func addOrb(color: NSColor, radius: CGFloat, position: CGPoint, duration: CFTimeInterval) {
        let orb = CAGradientLayer()
        orb.colors = [color.withAlphaComponent(0.32).cgColor, color.withAlphaComponent(0.0).cgColor]
        orb.startPoint = CGPoint(x: 0.5, y: 0.5)
        orb.endPoint = CGPoint(x: 0.5, y: 1)
        orb.cornerRadius = radius / 2
        layer?.addSublayer(orb)
        orbs.append((orb, position, radius, duration))
    }

    private func animateOrb(_ orb: CALayer, index: Int) {
        let center = CGPoint(x: orb.frame.midX, y: orb.frame.midY)
        let drift = CGFloat(18 + index * 7)
        let anim = CABasicAnimation(keyPath: "position")
        anim.fromValue = [center.x, center.y]
        anim.toValue = [center.x + drift, center.y - drift * 0.6]
        anim.duration = orbs[index].duration
        anim.timingFunction = Theme.quickEase
        anim.autoreverses = true
        anim.repeatCount = .infinity
        orb.add(anim, forKey: "drift-\(index)")
    }

    private func makeTile(symbol: String, title: String) -> NSView {
        let tile = NSView()
        tile.wantsLayer = true
        tile.layer?.cornerRadius = Theme.cornerRadius
        tile.layer?.backgroundColor = Theme.surfaceGlass.cgColor
        tile.layer?.borderWidth = 1
        tile.layer?.borderColor = Theme.hairline.cgColor

        let icon = NSImageView(image: NSImage(systemSymbolName: symbol, accessibilityDescription: title) ?? NSImage())
        icon.contentTintColor = Theme.bananaGold
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = Theme.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false

        tile.addSubview(icon)
        tile.addSubview(label)

        NSLayoutConstraint.activate([
            tile.widthAnchor.constraint(equalToConstant: 108),
            tile.heightAnchor.constraint(equalToConstant: 84),
            icon.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            icon.topAnchor.constraint(equalTo: tile.topAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            label.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 8),
        ])
        return tile
    }

    /// Renders a string filled with a linear gradient (AppKit mask trick).
    static func gradientText(_ string: String, colors: [NSColor], fontSize: CGFloat) -> NSImage {
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        let size = (string as NSString).size(withAttributes: [.font: font])

        let mask = NSImage(size: size)
        mask.lockFocus()
        (string as NSString).draw(at: .zero, withAttributes: [.font: font, .foregroundColor: NSColor.black])
        mask.unlockFocus()

        let image = NSImage(size: size)
        image.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext,
           let maskCG = mask.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            ctx.saveGState()
            ctx.clip(to: CGRect(origin: .zero, size: size), mask: maskCG)
            NSGradient(colors: colors)?.draw(in: NSRect(origin: .zero, size: size), angle: 90)
            ctx.restoreGState()
        }
        image.unlockFocus()
        return image
    }

    // MARK: - Actions

    @objc private func submit(_ sender: NSTextField) {
        let value = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        onNavigate?(value)
    }

    /// Called by the window controller when the address is set programmatically.
    func setFieldValue(_ value: String) {
        field.stringValue = value
    }

    func focusField() {
        window?.makeFirstResponder(field)
    }

    /// Focuses the search field on first appearance only (avoids stealing
    /// focus on every chrome refresh).
    func focusFieldIfNeeded() {
        guard window?.firstResponder !== field, field.currentEditor() == nil else { return }
        window?.makeFirstResponder(field)
    }
}
