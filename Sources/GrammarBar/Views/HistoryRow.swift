import SwiftUI

struct HistoryRow: View {
    let entry: HistoryEntry
    let onSelect: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void
    @State private var hovering = false
    @State private var copied = false
    @Environment(\.colorSchemeContrast) private var contrast

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    private var relativeDate: String {
        Self.relativeFormatter.localizedString(for: entry.date, relativeTo: Date())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            // Restore: a real button so keyboard (Full Keyboard Access) and VoiceOver can activate it.
            Button(action: onSelect) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: entry.modeValue.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Color.accentColor.opacity(0.12)))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.output)
                            .font(.system(size: 12.5))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        Text(entry.input)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Text("\(entry.shortLabel) · \(relativeDate)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Click to restore")
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(entry.title), \(relativeDate): \(entry.output)")
            .accessibilityHint("Restores this result into the editor")
            .accessibilityAction(named: "Copy result") { copy() }
            .accessibilityAction(named: "Delete") { onDelete() }

            // Always present (not hover-only) so keyboard users can reach them; dimmed until hover.
            HStack(spacing: 0) {
                IconButton(systemName: copied ? "checkmark" : "doc.on.doc",
                           help: copied ? "Copied" : "Copy result") { copy() }
                IconButton(systemName: "trash", help: "Delete from history", action: onDelete)
            }
            .opacity(hovering || copied ? 1 : 0.45)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(hovering ? Color.accentColor.opacity(0.6)
                                       : Color.primary.opacity(contrast == .increased ? 0.5 : 0.1))
        )
        .onHover { hovering = $0 }
        .contextMenu {
            Button("Restore", action: onSelect)
            Button("Copy result") { copy() }
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    private func copy() {
        onCopy()
        copied = true
        announce("Copied")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
    }
}
