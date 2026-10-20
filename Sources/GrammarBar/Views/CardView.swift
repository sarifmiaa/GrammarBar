import AppKit
import SwiftUI

struct CardView: View {
    @ObservedObject var model: GrammarModel
    var onClose: () -> Void = {}
    @AppStorage("selectedMode") private var modeRaw = Mode.fixGrammar.rawValue
    @FocusState private var inputFocused: Bool
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var borderOpacity: Double { contrast == .increased ? 0.5 : 0.15 }

    private var mode: Mode { Mode(rawValue: modeRaw) ?? .fixGrammar }

    private var canSubmit: Bool {
        !model.isRunning && !model.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if model.showingHistory {
                HistoryView(model: model, onBack: {
                    model.showingHistory = false
                    focusInput()
                }) { entry in
                    modeRaw = entry.mode
                    model.restore(entry)
                    model.showingHistory = false
                    focusInput()
                }
            } else {
                modePicker
                inputCard
                actionRow

                if let error = model.error {
                    errorBanner(error)
                }

                if !model.result.isEmpty {
                    resultCard
                }

                footer
            }
        }
        .padding(14)
        .frame(width: 400)
        .onAppear { focusInput() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            focusInput()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "text.badge.checkmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.75)],
                                             startPoint: .top, endPoint: .bottom))
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text("GrammarBar").font(.system(size: 13, weight: .semibold))
                Text(model.showingHistory ? "History" : mode.rawValue).font(.caption).foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer()
            IconButton(systemName: "clock.arrow.circlepath",
                       help: model.showingHistory ? "Back to editor" : "Show history",
                       isActive: model.showingHistory) {
                model.showingHistory.toggle()
                if !model.showingHistory { focusInput() }
            }
            IconButton(systemName: "power", help: "Quit GrammarBar") { NSApp.terminate(nil) }
            IconButton(systemName: "xmark", help: "Close (Esc)") { onClose() }
        }
    }

    // MARK: Mode picker

    private var modePicker: some View {
        HStack(spacing: 6) {
            ForEach(Mode.allCases) { m in
                ModeChip(mode: m, isSelected: m == mode) {
                    modeRaw = m.rawValue
                    announce("\(m.rawValue) selected")
                }
                .keyboardShortcut(m.shortcut, modifiers: .command)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mode")
    }

    // MARK: Input

    private var inputCard: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.input)
                    .font(.system(size: 13))
                    .focused($inputFocused)
                    .accessibilityLabel("Text to process")
                    .accessibilityHint("Press Command Return to submit")
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 6)
                    .padding(.top, 8)
                if model.input.isEmpty {
                    Text("Type or paste text…")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                        .padding(.horizontal, 11)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 120)

            HStack(spacing: 4) {
                Text("\(model.input.count) characters")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                Spacer()
                IconButton(systemName: "doc.on.clipboard", help: "Paste from clipboard") {
                    model.pasteFromClipboard()
                    focusInput()
                }
                IconButton(systemName: "xmark.circle", help: "Clear input and result") {
                    model.clear()
                    focusInput()
                }
                .disabled(model.isRunning || (model.input.isEmpty && model.result.isEmpty))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(inputFocused ? Color.accentColor : Color.primary.opacity(borderOpacity),
                              lineWidth: inputFocused ? 1.5 : 1)
        )
    }

    // MARK: Actions

    private var actionRow: some View {
        HStack(spacing: 8) {
            if model.isRunning {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Asking Claude…")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Asking Claude")
                .accessibilityAddTraits(.updatesFrequently)
            }
            Spacer()
            Button {
                model.submit(mode: mode)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: mode.icon)
                    Text(mode.actionLabel)
                    Text("⌘↩").font(.caption).opacity(0.85)
                }
                .padding(.horizontal, 6)
            }
            .accessibilityLabel(mode.actionLabel)
            .accessibilityHint("\(mode.rawValue). Shortcut Command Return")
            .keyboardShortcut(.return, modifiers: .command)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSubmit)
        }
    }

    // MARK: Error

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(.callout)
        .foregroundColor(Color(nsColor: .systemRed))
        .padding(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.red.opacity(0.1))
        )
    }

    // MARK: Result

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)
                Text("Result")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if model.copied {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark").foregroundColor(Color(nsColor: .systemGreen))
                        Text("Copied").foregroundColor(.secondary)
                    }
                    .font(.caption)
                    .transition(.opacity)
                    .accessibilityElement(children: .combine)
                }
                Button {
                    model.useAsInput()
                    focusInput()
                } label: {
                    Label("Use as input", systemImage: "arrow.up.doc")
                }
                .controlSize(.small)
                Button {
                    model.copy()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.accentColor.opacity(0.1))

            Divider().opacity(0.5)

            ScrollView {
                Text(model.result)
                    .font(.system(size: 13.5))
                    .lineSpacing(4)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .accessibilityLabel("Result: \(model.result)")
            }
            .frame(maxHeight: 240)
            .fixedSize(horizontal: false, vertical: true)
        }
        // Opaque so the desktop behind the translucent popover never bleeds through the text.
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(contrast == .increased ? 0.9 : 0.35))
        )
        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: model.copied)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 4) {
            Image(systemName: "cpu").accessibilityHidden(true)
            Text("Claude \(claudeModel.capitalized)")
            Text("·").accessibilityHidden(true)
            Text("⌘1–4 switch mode")
            Spacer()
            Text("Esc to close")
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Model Claude \(claudeModel.capitalized). Command 1 to 4 switches mode. Escape closes.")
    }

    private func focusInput() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { inputFocused = true }
    }
}
