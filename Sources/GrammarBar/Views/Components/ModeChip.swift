import SwiftUI

struct ModeChip: View {
    let mode: Mode
    let language: String
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                Text(mode.shortLabel(language: language))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .accentColor : .primary.opacity(0.85))
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.15)
                                     : Color.primary.opacity(hovering ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help("\(mode.title(language: language)) (⌘\(String(mode.shortcut.character)))")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mode.title(language: language))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Shortcut Command \(String(mode.shortcut.character))")
    }
}
