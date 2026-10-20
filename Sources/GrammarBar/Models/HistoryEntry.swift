import Foundation

struct HistoryEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var date = Date()
    var mode: String
    /// Target language for "Translate to …"; nil for other modes and for entries saved before it was selectable.
    var language: String?
    var input: String
    var output: String

    var modeValue: Mode { Mode(stored: mode) }

    /// Entries from older versions only ever translated to German.
    var languageValue: String { language ?? Language.defaultName }

    var title: String { modeValue.title(language: languageValue) }
    var shortLabel: String { modeValue.shortLabel(language: languageValue) }
}
