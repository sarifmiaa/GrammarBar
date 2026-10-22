import AppKit
import SwiftUI

@MainActor
final class GrammarModel: ObservableObject {
    @Published var input = ""
    @Published var result = ""
    @Published var error: String?
    @Published var isRunning = false
    @Published var copied = false
    @Published private(set) var history: [HistoryEntry] = []
    @Published var showingHistory = false

    /// The app the input was captured from via ⌃⌥G, if any — a successful result pastes back into it.
    var sourceApp: NSRunningApplication?

    private static let historyKey = "history"
    private static let historyLimit = 100

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.historyKey),
           let saved = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            history = saved
        }
    }

    func submit(mode: Mode, language: String) {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isRunning else { return }
        isRunning = true
        error = nil
        copied = false
        announce("Asking Claude")
        let instruction = mode.instruction(language: language)
        let entryLanguage = mode == .toLanguage ? language : nil

        Task.detached(priority: .userInitiated) {
            let outcome = Result { try ClaudeRunner.run(text: text, instruction: instruction) }
            await MainActor.run {
                self.isRunning = false
                switch outcome {
                case .success(let output):
                    self.result = output
                    self.copy()
                    self.addToHistory(HistoryEntry(mode: mode.rawValue, language: entryLanguage, input: text, output: output))
                    if let app = self.sourceApp {
                        self.replaceInSource(app)
                    } else {
                        announce("Result ready and copied to clipboard: \(output)")
                    }
                case .failure(let err):
                    self.error = err.localizedDescription
                    announce("Error: \(err.localizedDescription)")
                }
            }
        }
    }

    /// Brings the source app back to front and pastes the result over its field.
    private func replaceInSource(_ app: NSRunningApplication) {
        guard !app.isTerminated else { return }
        let name = app.localizedName ?? "the original app"
        Task {
            app.activate(options: [.activateIgnoringOtherApps])
            for _ in 0..<20 {
                if app.isActive { break }
                try? await Task.sleep(nanoseconds: 15_000_000)
            }
            guard app.isActive else { return }
            await SelectionCapture.replaceSelection()
            announce("Replaced in \(name)")
        }
    }

    func copy() {
        guard !result.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
        copied = true
        let copiedResult = result
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.result == copiedResult { self?.copied = false }
        }
    }

    func pasteFromClipboard() {
        if let text = NSPasteboard.general.string(forType: .string) {
            input = text
            sourceApp = nil
        }
    }

    func useAsInput() {
        input = result
        result = ""
        copied = false
    }

    func clear() {
        input = ""
        result = ""
        error = nil
        copied = false
        sourceApp = nil
    }

    // MARK: History

    func restore(_ entry: HistoryEntry) {
        input = entry.input
        result = entry.output
        error = nil
        copied = false
        sourceApp = nil
    }

    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func deleteHistory(_ entry: HistoryEntry) {
        history.removeAll { $0.id == entry.id }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    private func addToHistory(_ entry: HistoryEntry) {
        history.insert(entry, at: 0)
        if history.count > Self.historyLimit {
            history.removeLast(history.count - Self.historyLimit)
        }
        saveHistory()
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: Self.historyKey)
        }
    }
}
