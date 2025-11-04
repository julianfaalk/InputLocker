//
//  AccessibilityHelper.swift
//  InputLocker
//
//  Created by Julian Falk on 03.11.25.
//
// =======================
// File: AccessibilityHelper.swift
// =======================
import Cocoa
import ApplicationServices

enum AccessibilityHelper {
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    static func ensurePermission() {
        if !isTrusted() {
            let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(opts)
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "To block input, InputLocker needs Accessibility permissions. Go to System Settings → Privacy & Security → Accessibility and enable InputLocker. Then click ‘Lock Input’."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
