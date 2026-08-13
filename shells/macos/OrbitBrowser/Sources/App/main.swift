import AppKit

// Entry point: build the app object graph by hand (no storyboards / XIBs —
// this package builds with the Command Line Tools toolchain only).
let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.regular)
application.mainMenu = MainMenuBuilder.makeMainMenu()
application.run()
