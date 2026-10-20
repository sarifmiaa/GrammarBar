import Foundation

struct HistoryEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var date = Date()
    var mode: String
    var input: String
    var output: String

    var modeValue: Mode { Mode(rawValue: mode) ?? .fixGrammar }
}
