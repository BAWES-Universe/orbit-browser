import AppKit

/// Application lifecycle owner. Owns the single browser window for Q1.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowController: BrowserWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Q-ORBIT-03: headless regression mode — no window, JSON report, exit code.
        if CommandLine.arguments.contains("--selftest") {
            let code = SelfTest.run()
            exit(code)
        }

        let controller = BrowserWindowController()
        controller.showWindow(nil)
        windowController = controller

        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }

        // Q-ORBIT-03: `--screenshot <path>` renders the window content to a
        // PNG offscreen (layer tree render — no Screen Recording permission
        // needed), then exits. Powers visibility/E2E regression without a GUI.
        let args = CommandLine.arguments
        if let flagIndex = args.firstIndex(of: "--screenshot"), args.indices.contains(flagIndex + 1) {
            let path = args[flagIndex + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak controller] in
                guard let window = controller?.window else { NSApp.terminate(nil); return }
                Self.writeScreenshot(of: window, to: path)
                NSApp.terminate(nil)
            }
        }
    }

    /// Renders the window's view cache (preferred — matches on-screen pixels
    /// including occlusion) into a PNG; falls back to the layer tree.
    private static func writeScreenshot(of window: NSWindow, to path: String) {
        guard let contentView = window.contentView else { return }
        let size = contentView.bounds.size
        guard size.width > 0, size.height > 0 else { return }

        var pngData: Data?
        // Path 1: cacheDisplay — what the user actually sees (occlusion-aware).
        if let rep = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds) {
            contentView.cacheDisplay(in: contentView.bounds, to: rep)
            pngData = rep.representation(using: .png, properties: [:])
        }
        // Path 2: layer tree render (captures CALayer-only content).
        if pngData == nil {
            let image = NSImage(size: size)
            image.lockFocus()
            if let ctx = NSGraphicsContext.current?.cgContext, let layer = contentView.layer {
                layer.render(in: ctx)
            }
            image.unlockFocus()
            if let tiff = image.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff) {
                pngData = rep.representation(using: .png, properties: [:])
            }
        }
        if let data = pngData {
            try? data.write(to: URL(fileURLWithPath: path))
            NSLog("[orbit] screenshot written: %@", path)
        } else {
            NSLog("[orbit] screenshot FAILED: %@", path)
        }
    }

    /// Real browser behavior: closing the window hides the app instead of
    /// quitting; the dock icon stays and reopens the window.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let controller = windowController {
            controller.showWindow(nil)
        } else {
            let controller = BrowserWindowController()
            controller.showWindow(nil)
            windowController = controller
        }
        return false
    }
}
