import AppKit

/// Minimal programmatic main menu (required for text-field copy/paste key
/// equivalents and Quit). Built without nibs so the CLI-tools build stays
/// self-contained.
@MainActor
enum MainMenuBuilder {

    static func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "About Orbit Browser",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "Hide Orbit Browser",
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h"
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "Quit Orbit Browser",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu

        // File menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(
            withTitle: "New Tab",
            action: #selector(BrowserWindowController.newTab(_:)),
            keyEquivalent: "t"
        )
        fileMenu.addItem(
            withTitle: "Close Tab",
            action: #selector(BrowserWindowController.closeTab(_:)),
            keyEquivalent: "w"
        )
        fileMenu.addItem(
            withTitle: "Focus Address Bar",
            action: #selector(BrowserWindowController.focusAddressBar(_:)),
            keyEquivalent: "l"
        )
        fileMenu.addItem(.separator())
        fileMenu.addItem(
            withTitle: "Next Tab",
            action: #selector(BrowserWindowController.nextTab(_:)),
            keyEquivalent: "\u{5D}"
        ).keyEquivalentModifierMask = [.command, .shift]
        fileMenu.addItem(
            withTitle: "Previous Tab",
            action: #selector(BrowserWindowController.previousTab(_:)),
            keyEquivalent: "\u{5B}"
        ).keyEquivalentModifierMask = [.command, .shift]
        fileMenu.addItem(.separator())
        for index in 1...9 {
            let item = fileMenu.addItem(
                withTitle: "Tab \(index)",
                action: #selector(BrowserWindowController.selectTabNumber(_:)),
                keyEquivalent: "\(index)"
            )
            item.tag = index - 1
            item.keyEquivalentModifierMask = [.command]
        }
        fileMenuItem.submenu = fileMenu

        // Edit menu — enables Cmd+C/V/X/A in the address bar.
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(
            withTitle: "Undo",
            action: Selector(("undo:")),
            keyEquivalent: "z"
        )
        editMenu.addItem(
            withTitle: "Redo",
            action: Selector(("redo:")),
            keyEquivalent: "Z"
        )
        editMenu.addItem(.separator())
        editMenu.addItem(
            withTitle: "Cut",
            action: #selector(NSText.cut(_:)),
            keyEquivalent: "x"
        )
        editMenu.addItem(
            withTitle: "Copy",
            action: #selector(NSText.copy(_:)),
            keyEquivalent: "c"
        )
        editMenu.addItem(
            withTitle: "Paste",
            action: #selector(NSText.paste(_:)),
            keyEquivalent: "v"
        )
        editMenu.addItem(
            withTitle: "Select All",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )
        editMenuItem.submenu = editMenu

        // Window menu
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(
            withTitle: "Minimize",
            action: #selector(NSWindow.performMiniaturize(_:)),
            keyEquivalent: "m"
        )
        windowMenu.addItem(
            withTitle: "Close Window",
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "W"
        )
        windowMenuItem.submenu = windowMenu
        NSApp.windowsMenu = windowMenu

        return mainMenu
    }
}
