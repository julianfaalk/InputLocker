import Cocoa
import SwiftUI

final class ShowcaseWindow: NSWindowController {
    init(viewModel: LockViewModel) {
        let hostingController = NSHostingController(rootView: ContentView(viewModel: viewModel))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 720),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "InputLocker"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentViewController = hostingController

        super.init(window: window)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@MainActor
func startApp() {
    let app = NSApplication.shared
    app.applicationIconImage = NSImage(named: "MainIcon")
    let blocker = InputBlocker()
    let viewModel = LockViewModel(blocker: blocker)
    let delegate = AppDelegate(blocker: blocker, viewModel: viewModel)
    app.delegate = delegate
    let showcase = ShowcaseWindow(viewModel: viewModel)
    delegate.register(window: showcase)

    // Create a menu bar with lock/unlock commands
    let mainMenu = NSMenu()
    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)

    let appMenu = NSMenu()

    let lockItem = NSMenuItem(title: "Lock Input", action: #selector(AppDelegate.lockAction(_:)), keyEquivalent: "l")
    lockItem.keyEquivalentModifierMask = [NSEvent.ModifierFlags.command]
    lockItem.target = delegate
    appMenu.addItem(lockItem)

    let unlockItem = NSMenuItem(title: "Unlock Input", action: #selector(AppDelegate.unlockAction(_:)), keyEquivalent: "u")
    unlockItem.keyEquivalentModifierMask = [NSEvent.ModifierFlags.command]
    unlockItem.target = delegate
    appMenu.addItem(unlockItem)

    appMenuItem.submenu = appMenu
    NSApp.mainMenu = mainMenu

    showcase.showWindow(nil)
    app.run()
}

Task { @MainActor in
    startApp()
}
RunLoop.main.run()
