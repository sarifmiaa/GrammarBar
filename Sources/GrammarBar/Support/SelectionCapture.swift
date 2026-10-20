import AppKit
import Carbon.HIToolbox

/// Grabs whatever text is in the frontmost app's focused field (Teams, Slack, a browser,
/// anything) by simulating Cmd+A then Cmd+C and reading the clipboard — no app-specific
/// integration needed.
enum SelectionCapture {
    static func isAccessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    /// Shows the system "GrammarBar would like to control this computer" prompt once per
    /// code signature. Posting synthetic key events silently does nothing until granted.
    @discardableResult
    static func requestAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Simulates Cmd+A (select all) then Cmd+C and returns the clipboard contents once they
    /// change, or `nil` if the field was empty (the clipboard never updates) within the timeout.
    static func captureSelectedText() async -> String? {
        let pasteboard = NSPasteboard.general
        let previousChangeCount = pasteboard.changeCount

        guard let source = CGEventSource(stateID: .combinedSessionState) else { return nil }
        post(key: kVK_ANSI_A, source: source)
        try? await Task.sleep(nanoseconds: 30_000_000)
        post(key: kVK_ANSI_C, source: source)

        for _ in 0..<20 {
            try? await Task.sleep(nanoseconds: 15_000_000)
            if pasteboard.changeCount != previousChangeCount {
                return pasteboard.string(forType: .string)
            }
        }
        return nil
    }

    private static func post(key: Int, source: CGEventSource) {
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(key), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(key), keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
