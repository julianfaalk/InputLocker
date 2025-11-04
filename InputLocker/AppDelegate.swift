//
//  AppDelegate.swift
//  InputLocker
//
//  Created by Julian Falk on 03.11.25.
//

// =======================
// File: AppDelegate.swift
// =======================
import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let blocker: InputBlocker
    private let viewModel: LockViewModel
    private var showcaseWindow: ShowcaseWindow?

    init(blocker: InputBlocker, viewModel: LockViewModel) {
        self.blocker = blocker
        self.viewModel = viewModel
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel.onStateChange = { [weak self] locked in
            self?.updateIcon(isLocked: locked)
        }
        setupStatusItem()
        updateIcon(isLocked: viewModel.isLocked)
        AccessibilityHelper.ensurePermission()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = statusIcon(isLocked: viewModel.isLocked)
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
        }
        let menu = NSMenu()
        menu.addItem(withTitle: "Show Window", action: #selector(showcaseAction), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Lock Input (⌘U)", action: #selector(lockAction), keyEquivalent: "")
        menu.addItem(withTitle: "Unlock Input", action: #selector(unlockAction), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Preferences…", action: #selector(prefsAction), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit InputLocker", action: #selector(quitAction), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc func lockAction(_ sender: Any?) {
        viewModel.lock()
        updateIcon(isLocked: viewModel.isLocked)
    }

    @objc func unlockAction(_ sender: Any?) {
        viewModel.unlock()
        updateIcon(isLocked: viewModel.isLocked)
    }

    @objc private func showcaseAction() {
        if let window = showcaseWindow {
            window.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
            window.window?.makeKeyAndOrderFront(nil)
            return
        }

        let window = ShowcaseWindow(viewModel: viewModel)
        showcaseWindow = window
    }

    @objc private func prefsAction() {
        let alert = NSAlert()
        alert.messageText = "InputLocker Preferences"
        alert.informativeText = "Unlock combo: ⌘U (customize in code).\nSafety auto‑unlock: 60s (customize in code).\nGrant Accessibility: System Settings → Privacy & Security → Accessibility."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitAction() {
        viewModel.unlock()
        NSApp.terminate(nil)
    }

    private func updateIcon(isLocked: Bool) {
        statusItem.button?.image = statusIcon(isLocked: isLocked)
    }

    func register(window: ShowcaseWindow) {
        showcaseWindow = window
    }

    private func statusIcon(isLocked: Bool) -> NSImage? {
        let assetName = isLocked ? "LockedIcon" : "UnlockedIcon"
        guard let base = NSImage(named: assetName)?.copy() as? NSImage else { return nil }
        let targetSize = NSSize(width: 18, height: 18)
        let badgeSize: CGFloat = 6
        let image = NSImage(size: targetSize)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        base.size = targetSize
        base.draw(in: NSRect(origin: .zero, size: targetSize))

        let badgeRect = NSRect(
            x: targetSize.width - badgeSize - 1,
            y: 1,
            width: badgeSize,
            height: badgeSize
        )
        (isLocked ? NSColor.systemGreen : NSColor.systemOrange).setFill()
        NSBezierPath(ovalIn: badgeRect).fill()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
