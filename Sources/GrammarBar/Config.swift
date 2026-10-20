import Foundation

/// Claude model used for all requests. Switch to "sonnet" for higher quality.
let claudeModel = "haiku"

/// Seconds before a request is cancelled.
let requestTimeout: TimeInterval = 120
