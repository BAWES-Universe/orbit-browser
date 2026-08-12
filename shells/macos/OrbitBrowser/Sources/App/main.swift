import AppKit

// Entry point: build the app object graph by hand (no storyboards / XIBs —
// this package builds with the Command Line Tools toolchain only).
//
// Top-level code isolation differs by language mode: Swift 6 mode (SwiftPM)
// makes top-level code @MainActor; Swift 5 mode (Xcode SWIFT_VERSION=5.0)
// treats it as nonisolated. MainActor.assumeIsolated satisfies both — it is a
// no-op when already on the main actor and a hop when not.
MainActor.assumeIsolated {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate
    application.setActivationPolicy(.regular)
    application.mainMenu = MainMenuBuilder.makeMainMenu()
    application.run()
}
