import AppKit

/// Checks once per install whether the `claude` CLI is reachable, and if not, offers to send
/// the user to the install instructions. Runs at most once — the result of a single launch is
/// trusted from then on, since the in-card error already covers "logged out" and "removed later".
enum ClaudeSetupCheck {
    private static let didCheckKey = "didCheckClaudeInstalled"

    static func runOnce() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: didCheckKey) else { return }
        defaults.set(true, forKey: didCheckKey)

        Task.detached(priority: .utility) {
            if !isClaudeInstalled() {
                await MainActor.run { promptToInstall() }
            }
        }
    }

    /// Blocking call — run off the main thread. Tries the known install locations first, then
    /// falls back to a login shell so nvm/asdf/etc. setups are recognized too.
    private static func isClaudeInstalled() -> Bool {
        if ClaudeRunner.findClaude() != nil { return true }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lic", "command -v claude >/dev/null 2>&1"]
        process.standardOutput = nil
        process.standardError = nil

        do {
            try process.run()
        } catch {
            return false
        }

        let deadline = DispatchTime.now() + 5
        while process.isRunning && DispatchTime.now() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        if process.isRunning {
            process.terminate()
            return false
        }
        return process.terminationStatus == 0
    }

    @MainActor
    private static func promptToInstall() {
        let alert = NSAlert()
        alert.messageText = "Claude Code not found"
        alert.informativeText = "GrammarBar fixes, polishes and translates text using the Claude Code CLI, "
            + "which isn't installed (or isn't logged in) yet. Install it, then run `claude` once in "
            + "Terminal to log in."
        alert.addButton(withTitle: "Open Install Guide")
        alert.addButton(withTitle: "Not Now")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "https://docs.claude.com/en/docs/claude-code/overview")!)
        }
    }
}
