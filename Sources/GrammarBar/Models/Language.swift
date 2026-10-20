import Foundation

/// Target languages for the "Translate to …" mode. English has its own mode, so it isn't listed.
enum Language {
    static let defaultName = "German"

    static let all = [
        "Arabic", "Bengali", "Chinese (Simplified)", "Chinese (Traditional)", "Czech", "Danish", "Dutch",
        "Finnish", "French", "German", "Greek", "Hebrew", "Hindi", "Hungarian", "Indonesian", "Italian",
        "Japanese", "Korean", "Malay", "Norwegian", "Persian", "Polish", "Portuguese (Brazil)",
        "Portuguese (Portugal)", "Romanian", "Russian", "Spanish", "Swedish", "Tagalog", "Thai", "Turkish",
        "Ukrainian", "Urdu", "Vietnamese",
    ]
}
