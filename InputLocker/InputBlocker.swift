//
//  InputBlocker.swift
//  InputLocker
//
//  Created by Julian Falk on 03.11.25.
//

// =======================
// File: InputBlocker.swift
// =======================
import Cocoa
import ApplicationServices

class InputBlocker {
    fileprivate(set) var isLocked = false

    // Unlock combo: ⌘ + U
    private let unlockKeyCode: CGKeyCode = 32 // U key
    private let requireCommand = true
    private let requireOption = false
    private let requireShift = false
    private let requireControl = false

    private let safetySeconds: TimeInterval = 60

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var safetyTimer: Timer?
    private var cursorHidden = false
    private var cursorDetached = false

    /// Callback used to mirror state changes to UI components.
    var onLockStateChanged: ((Bool) -> Void)?

    var safetyTimeout: TimeInterval { safetySeconds }

    func lock() {
        guard !isLocked else { return }
        guard AccessibilityHelper.isTrusted() else {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "Accessibility Not Granted"
            alert.informativeText = "Grant Accessibility permissions first."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        guard startEventTap() else {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = "Unable to Lock Input"
                alert.informativeText = "InputLocker couldn’t gain control of the keyboard and trackpad. Try disabling and re‑enabling Accessibility permissions in System Settings, then relaunch the app."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            return
        }
        isLocked = true
        freezePointer()
        notifyLockStateChanged()
        scheduleSafetyTimer()
    }

    func unlock() {
        stopEventTap()
        invalidateSafetyTimer()
        restorePointer()
        isLocked = false
        notifyLockStateChanged()
    }

    private func notifyLockStateChanged() {
        onLockStateChanged?(isLocked)
    }

    @discardableResult
    private func startEventTap() -> Bool {
        let types: [CGEventType] = [
            .keyDown,
            .keyUp,
            .flagsChanged,
            .leftMouseDown,
            .leftMouseUp,
            .leftMouseDragged,
            .rightMouseDown,
            .rightMouseUp,
            .rightMouseDragged,
            .otherMouseDown,
            .otherMouseUp,
            .otherMouseDragged,
            .mouseMoved,
            .scrollWheel,
            .tabletPointer,
            .tabletProximity
        ]

        var mask = types.reduce(CGEventMask(0)) { partialResult, type in
            partialResult | CGEventMask(UInt64(1) << UInt64(type.rawValue))
        }
        let additionalTypes: [NSEvent.EventType] = [.systemDefined, .swipe, .magnify, .rotate, .gesture]
        for eventType in additionalTypes {
            mask |= CGEventMask(UInt64(1) << UInt64(eventType.rawValue))
        }

        let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
            guard let unmanaged = userInfo else { return Unmanaged.passUnretained(event) }
            let me = Unmanaged<InputBlocker>.fromOpaque(unmanaged).takeUnretainedValue()
            return me.handleEvent(type: type, event: event)
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: userInfo
        )

        guard let eventTap else {
            NSLog("InputLocker: Failed to create event tap.")
            return false
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        return true
    }

    private func stopEventTap() {
        if let runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes) }
        runLoopSource = nil
        if let eventTap { CFMachPortInvalidate(eventTap) }
        eventTap = nil
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard isLocked else { return Unmanaged.passUnretained(event) }

        if let nsEvent = NSEvent(cgEvent: event), nsEvent.type == .systemDefined {
            return nil
        }

        if type == .keyDown {
            if isUnlockCombo(event: event) {
                DispatchQueue.main.async { self.unlock() }
                return Unmanaged.passUnretained(event)
            }
        }

        return nil
    }

    private func freezePointer() {
        guard !cursorDetached else { return }
        if CGAssociateMouseAndMouseCursorPosition(0) == .success {
            cursorDetached = true
        }
        if CGDisplayHideCursor(CGMainDisplayID()) == .success {
            cursorHidden = true
        }
    }

    private func restorePointer() {
        if cursorDetached {
            _ = CGAssociateMouseAndMouseCursorPosition(1)
            cursorDetached = false
        }
        if cursorHidden {
            _ = CGDisplayShowCursor(CGMainDisplayID())
            cursorHidden = false
        }
    }

    private func isUnlockCombo(event: CGEvent) -> Bool {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        let hasCmd = flags.contains(.maskCommand)
        let hasOpt = flags.contains(.maskAlternate)
        let hasShift = flags.contains(.maskShift)
        let hasCtrl = flags.contains(.maskControl)

        guard keyCode == unlockKeyCode else { return false }
        if requireCommand && !hasCmd { return false }
        if requireOption && !hasOpt { return false }
        if requireShift && !hasShift { return false }
        if requireControl && !hasCtrl { return false }
        return true
    }

    private func scheduleSafetyTimer() {
        invalidateSafetyTimer()
        guard safetySeconds > 0 else { return }
        safetyTimer = Timer.scheduledTimer(withTimeInterval: safetySeconds, repeats: false) { [weak self] _ in
            self?.unlock()
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Auto‑Unlocked"
                alert.informativeText = "Input was automatically unlocked after the safety timeout."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
        RunLoop.main.add(safetyTimer!, forMode: .common)
    }

    private func invalidateSafetyTimer() {
        safetyTimer?.invalidate()
        safetyTimer = nil
    }
}
