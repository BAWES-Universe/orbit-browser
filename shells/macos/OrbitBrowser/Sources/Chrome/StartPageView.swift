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

    /// Called when a quick-link tile is clicked (URL to load).
    var onOpenURL: ((URL) -> Void)?

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

        // Floating orbs — low alpha and spread apart so overlapping seams
        // don't read as visible facets/grid lines in the render.
        addOrb(color: Theme.indigo, radius: 380, position: CGPoint(x: 0.10, y: 0.30), duration: 22)
        addOrb(color: Theme.violet, radius: 320, position: CGPoint(x: 0.90, y: 0.18), duration: 27)
        addOrb(color: Theme.bananaGold, radius: 260, position: CGPoint(x: 0.68, y: 0.80), duration: 31)

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

        // Quick-link tiles — real click targets (placeholders for Universe surfaces).
        let tiles: [(symbol: String, title: String, url: URL?)] = [
            ("globe", "Universe", URL(string: "https://github.com/BAWES-Universe")),
            ("atom", "Orbit", nil),  // nil = focus the start page's own search field
            ("gauge.with.dots.needle.50percent", "Velocity", URL(string: "https://github.com/BAWES-Universe/bawes-fleet")),
            ("books.vertical", "Docs", URL(string: "https://github.com/BAWES-Universe/bawes-knowledge")),
        ]
        let tileRow = NSStackView()
        tileRow.orientation = .horizontal
        tileRow.spacing = 14
        tileRow.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tileRow)

        for tile in tiles {
            tileRow.addArrangedSubview(makeTile(symbol: tile.symbol, title: tile.title, url: tile.url))
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
        orb.colors = [color.withAlphaComponent(0.16).cgColor, color.withAlphaComponent(0.0).cgColor]
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

    private final class TileButton: NSButton {
        var targetURL: URL?
    }

    private func makeTile(symbol: String, title: String, url: URL?) -> NSView {
        let tile = TileButton()
        tile.isBordered = false
        tile.wantsLayer = true
        tile.layer?.cornerRadius = Theme.cornerRadius
        tile.layer?.backgroundColor = Theme.surfaceGlass.cgColor
        tile.layer?.borderWidth = 1
        tile.layer?.borderColor = Theme.hairline.cgColor
        tile.bezelStyle = .regularSquare
        tile.imagePosition = .imageAbove
        tile.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        tile.image?.size = NSSize(width: 20, height: 20)
        tile.image?.isTemplate = false
        tile.contentTintColor = Theme.bananaGold
        tile.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: Theme.textSecondary,
            ]
        )
        tile.toolTip = title
        tile.target = self
        tile.action = #selector(tilePressed(_:))
        tile.targetURL = url
        tile.translatesAutoresizingMaskIntoConstraints = false
        tile.widthAnchor.constraint(equalToConstant: 108).isActive = true
        tile.heightAnchor.constraint(equalToConstant: 84).isActive = true
        return tile
    }

    @objc private func tilePressed(_ sender: NSButton) {
        if let tile = sender as? TileButton, let url = tile.targetURL {
            onOpenURL?(url)
        } else {
            focusField()
        }
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
