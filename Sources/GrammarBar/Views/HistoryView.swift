import SwiftUI

struct HistoryView: View {
    @ObservedObject var model: GrammarModel
    let onBack: () -> Void
    let onSelect: (HistoryEntry) -> Void
    @State private var search = ""
    @State private var confirmingClear = false
    @Environment(\.colorSchemeContrast) private var contrast

    private var filtered: [HistoryEntry] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return model.history }
        return model.history.filter {
            $0.input.localizedCaseInsensitiveContains(query) || $0.output.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onBack) {
                Label("Back", systemImage: "chevron.left")
            }
            .controlSize(.regular)
            .help("Back to editor (Esc)")
            .accessibilityLabel("Back to editor")

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    .accessibilityHidden(true)
                TextField("Search history", text: $search)
                    .textFieldStyle(.plain)
                    .accessibilityLabel("Search history")
                if !search.isEmpty {
                    IconButton(systemName: "xmark.circle.fill", help: "Clear search") { search = "" }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(contrast == .increased ? 0.5 : 0.15)))

            if filtered.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: model.history.isEmpty ? "clock" : "magnifyingglass")
                        .font(.system(size: 22))
                    Text(model.history.isEmpty ? "No history yet" : "No matches")
                        .font(.callout)
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .accessibilityElement(children: .combine)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filtered) { entry in
                            HistoryRow(entry: entry,
                                       onSelect: { onSelect(entry) },
                                       onCopy: { model.copyToClipboard(entry.output) },
                                       onDelete: { model.deleteHistory(entry) })
                        }
                    }
                }
                .frame(maxHeight: 400)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("History, \(filtered.count) items")
            }

            HStack(spacing: 8) {
                Text("\(model.history.count) item\(model.history.count == 1 ? "" : "s") · click to restore")
                    .foregroundColor(.secondary)
                Spacer()
                if confirmingClear {
                    Text("Delete all history?").foregroundColor(.secondary)
                    Button("Cancel") { confirmingClear = false }
                    Button("Clear", role: .destructive) {
                        model.clearHistory()
                        confirmingClear = false
                        announce("History cleared")
                    }
                } else if !model.history.isEmpty {
                    Button("Clear all…") {
                        confirmingClear = true
                        announce("Delete all history? Choose Clear or Cancel.")
                    }
                }
            }
            .font(.caption)
            .controlSize(.small)
        }
    }
}
