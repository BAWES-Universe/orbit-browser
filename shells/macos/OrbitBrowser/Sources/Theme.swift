import AppKit
import QuartzCore

/// Orbit Browser design tokens (Q-ORBIT-02).
/// Dark-first, banana-gold accent (the Nation's currency), indigo→violet
/// gradient for Orbit moments. Single source of truth — swappable.
@MainActor
enum Theme {
    // MARK: Surfaces
    static let background = NSColor(calibratedRed: 0.043, green: 0.043, blue: 0.059, alpha: 1)        // #0B0B0F
    static let backgroundRaised = NSColor(calibratedRed: 0.075, green: 0.075, blue: 0.102, alpha: 1) // #13131A
    static let surfaceGlass = NSColor(calibratedWhite: 1, alpha: 0.06)
    static let surfaceGlassElevated = NSColor(calibratedWhite: 1, alpha: 0.11)
    static let hairline = NSColor(calibratedWhite: 1, alpha: 0.08)

    // MARK: Accents
    static let bananaGold = NSColor(calibratedRed: 0.961, green: 0.773, blue: 0.094, alpha: 1)       // #F5C518
    static let indigo = NSColor(calibratedRed: 0.388, green: 0.400, blue: 0.945, alpha: 1)           // #6366F1
    static let violet = NSColor(calibratedRed: 0.545, green: 0.361, blue: 0.965, alpha: 1)           // #8B5CF6

    /// The Orbit gradient (indigo → violet), used for logo, active glow, orbs.
    static var orbitGradient: [NSColor] { [indigo, violet] }

    // MARK: Text
    static let textPrimary = NSColor(calibratedWhite: 0.95, alpha: 1)
    static let textSecondary = NSColor(calibratedWhite: 0.62, alpha: 1)
    static let textOnGold = NSColor(calibratedWhite: 0.08, alpha: 1)

    // MARK: Metrics
    static let cornerRadius: CGFloat = 12
    static let pillRadius: CGFloat = 999
    static let stripHeight: CGFloat = 44
    /// Left inset for the traffic lights (hidden titlebar overlay).
    static let trafficLightInset: CGFloat = 76

    static let easing = CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1)
    static let quickEase = CAMediaTimingFunction(name: .easeOut)
}
