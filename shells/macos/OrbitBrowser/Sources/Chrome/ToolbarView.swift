import AppKit
import QuartzCore

/// The unified browser chrome strip: traffic-light spacer + floating pill
/// tab strip + glass address bar + glass action buttons (nav, shield, AI,
/// identity avatar). Owns the chrome's look; the window controller owns
/// behavior.
@MainActor
final class ToolbarView: NSView {

    // Sub-views
    let tabStrip = TabStripView()
    let addressBar = AddressBarView()
    let backButton = NSButton()
    let forwardButton = NSButton()
    let reloadButton = NSButton()
    let shieldButton = NSButton()
    let aiButton = NSButton()
    let avatarView = NSView()

    // Behavior hooks (wired by the window controller)
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?
    var onReload: (() -> Void)?

    private let trafficSpacer = NSView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("ToolbarView: NSCoding not supported")
    }

    private func setup() {
        wantsLayer = true
        // Opaque background: translucent ancestor layer backgrounds were
        // breaking descendant compositing in this window's layer tree.
        layer?.backgroundColor = NSColor(calibratedWhite: 0.02, alpha: 1.0).cgColor

        let hairline = NSView()
        hairline.wantsLayer = true
        hairline.layer?.backgroundColor = NSColor(calibratedWhite: 1, alpha: 0.16).cgColor
        hairline.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hairline)

        // Left group: traffic-light spacer + floating pill tabs.
        let leftStack = NSStackView()
        leftStack.orientation = .horizontal
        leftStack.spacing = 8
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftStack)

        trafficSpacer.translatesAutoresizingMaskIntoConstraints = false
        trafficSpacer.widthAnchor.constraint(equalToConstant: Theme.trafficLightInset).isActive = true
        leftStack.addArrangedSubview(trafficSpacer)

        // Tabs stretch up to a cap so they never crush the address bar.
        tabStrip.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tabStrip.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        leftStack.addArrangedSubview(tabStrip)

        // Right group: address bar + nav + actions. Everything that must
        // composite lives inside a stack in this window.
        let rightStack = NSStackView()
        rightStack.orientation = .horizontal
        rightStack.spacing = 8
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightStack)

        addressBar.translatesAutoresizingMaskIntoConstraints = false
        addressBar.widthAnchor.constraint(equalToConstant: 420).isActive = true
        addressBar.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        configureNavButton(backButton, symbol: "chevron.backward", tooltip: "Back")
        configureNavButton(forwardButton, symbol: "chevron.forward", tooltip: "Forward")
        configureNavButton(reloadButton, symbol: "arrow.clockwise", tooltip: "Reload")
        let navStack = NSStackView(views: [backButton, forwardButton, reloadButton])
        navStack.orientation = .horizontal
        navStack.spacing = 2

        // Conventional order: nav chevrons left of the address bar.
        rightStack.addArrangedSubview(navStack)
        rightStack.addArrangedSubview(addressBar)

        configureNavButton(shieldButton, symbol: "shield.fill", tooltip: "Rules: pending (Q-ORBIT-07)")
        shieldButton.contentTintColor = Theme.bananaGold.withAlphaComponent(0.85)
        rightStack.addArrangedSubview(shieldButton)

        configureNavButton(aiButton, symbol: "sparkles", tooltip: "Orbit AI: pending (Q-ORBIT-06)")
        aiButton.contentTintColor = Theme.violet
        rightStack.addArrangedSubview(aiButton)

        makeAvatar()
        rightStack.addArrangedSubview(avatarView)

        NSLayoutConstraint.activate([
            leftStack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            leftStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            leftStack.leadingAnchor.constraint(equalTo: leadingAnchor),

            rightStack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            rightStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            rightStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            leftStack.trailingAnchor.constraint(lessThanOrEqualTo: rightStack.leadingAnchor, constant: -8),
            tabStrip.widthAnchor.constraint(lessThanOrEqualToConstant: 520),

            hairline.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    private func configureNavButton(_ button: NSButton, symbol: String, tooltip: String) {
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: tooltip)
        button.imagePosition = .imageOnly
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 8
        button.layer?.backgroundColor = Theme.surfaceGlass.cgColor
        button.contentTintColor = Theme.textPrimary
        button.toolTip = tooltip
        button.target = self
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        switch symbol {
        case "chevron.backward": button.action = #selector(backPressed(_:))
        case "chevron.forward": button.action = #selector(forwardPressed(_:))
        case "arrow.clockwise": button.action = #selector(reloadPressed(_:))
        default: break
        }
    }

    private let avatarGradient = CAGradientLayer()

    override func layout() {
        super.layout()
        // CAGradientLayer has zero bounds by default and does not track its
        // superlayer's size; keep it in sync with the avatar on every layout.
        avatarGradient.frame = avatarView.bounds
    }

    private func makeAvatar() {
        avatarView.wantsLayer = true
        avatarView.layer?.cornerRadius = 15
        avatarGradient.colors = [Theme.bananaGold.cgColor, Theme.indigo.cgColor]
        avatarGradient.startPoint = CGPoint(x: 0, y: 0)
        avatarGradient.endPoint = CGPoint(x: 1, y: 1)
        avatarGradient.cornerRadius = 15
        avatarView.layer?.addSublayer(avatarGradient)

        let initial = NSTextField(labelWithString: "K")
        initial.font = .systemFont(ofSize: 13, weight: .bold)
        initial.textColor = Theme.textOnGold
        initial.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(initial)

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        avatarView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        avatarView.toolTip = "Identity: pending (Q-ORBIT-07)"
        initial.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor).isActive = true
        initial.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor).isActive = true
    }

    // MARK: - State

    func setNavigation(canGoBack: Bool, canGoForward: Bool) {
        backButton.isEnabled = canGoBack
        forwardButton.isEnabled = canGoForward
        backButton.alphaValue = canGoBack ? 1 : 0.4
        forwardButton.alphaValue = canGoForward ? 1 : 0.4
    }

    func updateTabs(titles: [String], selectedIndex: Int) {
        tabStrip.update(titles: titles, selectedIndex: selectedIndex)
    }

    // MARK: - Actions

    @objc private func backPressed(_ sender: Any?) { onBack?() }
    @objc private func forwardPressed(_ sender: Any?) { onForward?() }
    @objc private func reloadPressed(_ sender: Any?) { onReload?() }
}
