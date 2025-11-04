//
//  LockViewModel.swift
//  InputLocker
//
//  Created by OpenAI Codex on 05.11.25.
//

import Foundation
import Combine

/// Bridges the AppKit-based `InputBlocker` to the SwiftUI interface.
@MainActor
final class LockViewModel: ObservableObject {
    @Published private(set) var isLocked: Bool
    @Published private(set) var hasAccessibilityPermission: Bool

    private let blocker: InputBlocker

    /// Invoked whenever the lock state changes. Used by status bar UI.
    var onStateChange: ((Bool) -> Void)?

    init(blocker: InputBlocker) {
        self.blocker = blocker
        self.isLocked = blocker.isLocked
        self.hasAccessibilityPermission = AccessibilityHelper.isTrusted()

        blocker.onLockStateChanged = { [weak self] locked in
            guard let self else { return }
            Task { @MainActor in
                self.isLocked = locked
                self.onStateChange?(locked)
            }
        }
    }

    func toggleLock() {
        isLocked ? unlock() : lock()
    }

    func lock() {
        refreshPermissionStatus()
        guard hasAccessibilityPermission else {
            requestPermission()
            return
        }
        blocker.lock()
        isLocked = blocker.isLocked
        onStateChange?(isLocked)
    }

    func unlock() {
        blocker.unlock()
        isLocked = blocker.isLocked
        onStateChange?(isLocked)
    }

    func requestPermission() {
        AccessibilityHelper.ensurePermission()
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        hasAccessibilityPermission = AccessibilityHelper.isTrusted()
    }

    var safetyTimeoutDescription: String {
        let seconds = Int(blocker.safetyTimeout)
        guard seconds > 0 else { return "Auto-unlock disabled" }
        return "Auto-unlocks after \(seconds)-second safety timer."
    }

    var toggleButtonTitle: String {
        isLocked ? "Unlock Now" : "Lock Input"
    }

    var toggleShortcut: String {
        isLocked ? "⌘U" : "⌘L"
    }
}
