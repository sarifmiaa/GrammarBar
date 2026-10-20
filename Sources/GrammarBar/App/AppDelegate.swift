import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let model = GrammarModel()
    private var escMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "text.badge.checkmark", accessibilityDescription: "GrammarBar")
            button.toolTip = "GrammarBar"
            button.setAccessibilityLabel("GrammarBar")
            button.setAccessibilityHelp("Open the grammar and translation card")
            button.target = self
            button.action = #selector(togglePopover)
        }

        let hosting = NSHostingController(rootView: CardView(model: model) { [weak self] in self?.closePopover() })
        hosting.sizingOptions = .preferredContentSize
        // Stays open until closed explicitly (icon, close button or Esc) — not on focus loss.
        popover.behavior = .applicationDefined
        popover.animates = true
        popover.contentViewController = hosting

        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.popover.isShown, event.keyCode == 53 else { return event }
            if self.model.showingHistory {
                self.model.showingHistory = false
            } else {
                self.closePopover()
            }
            return nil
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else if let button = statusItem.button {
            NSApp.activate(ignoringOtherApps: true)
            popover.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
    }
}
