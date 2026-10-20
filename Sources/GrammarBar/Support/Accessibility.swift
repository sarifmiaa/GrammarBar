import AppKit

/// Speaks a message through VoiceOver (no-op when VoiceOver is off).
@MainActor
func announce(_ message: String) {
    let element: Any = NSApp.keyWindow ?? NSApp as Any
    NSAccessibility.post(element: element, notification: .announcementRequested, userInfo: [
        .announcement: message,
        .priority: NSAccessibilityPriorityLevel.high.rawValue,
    ])
}
