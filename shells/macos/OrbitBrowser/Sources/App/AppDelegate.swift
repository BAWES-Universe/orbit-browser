import AppKit

/// Application lifecycle owner. Owns the single browser window for Q1.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowController: BrowserWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = BrowserWindowController()
        controller.showWindow(nil)
        windowController = controller

        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
