import Foundation

enum ClaudeError: LocalizedError {
    case notFound
    case failed(String)
    case timedOut
    case empty

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "claude CLI not found. Install Claude Code and run `claude` once in Terminal to log in."
        case .failed(let msg):
            return msg
        case .timedOut:
            return "Claude took too long to respond (timed out after \(Int(requestTimeout))s)."
        case .empty:
            return "Claude returned an empty response."
        }
    }
}

enum ClaudeRunner {
    static let candidatePaths: [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "\(home)/.local/bin/claude",
            "\(home)/.claude/local/claude",
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
        ]
    }()

    static func findClaude() -> String? {
        candidatePaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func environment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let extra = "\(home)/.local/bin:/opt/homebrew/bin:/usr/local/bin"
        env["PATH"] = extra + ":" + (env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin")
        return env
    }

    static func workingDirectory() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("grammarbar", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Blocking call — run off the main thread.
    static func run(text: String, instruction: String) throws -> String {
        let process = Process()
        var env = environment()
        let claudeArgs = ["-p", instruction, "--model", claudeModel, "--output-format", "text"]
        let usingShell: Bool

        if let path = findClaude() {
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = claudeArgs
            usingShell = false
        } else {
            // Fall back to a login shell so nvm/asdf/etc. setups can resolve `claude`.
            env["GRAMMARBAR_PROMPT"] = instruction
            env["GRAMMARBAR_MODEL"] = claudeModel
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = [
                "-lic",
                "command -v claude >/dev/null 2>&1 || exit 127; " +
                "exec claude -p \"$GRAMMARBAR_PROMPT\" --model \"$GRAMMARBAR_MODEL\" --output-format text",
            ]
            usingShell = true
        }

        process.environment = env
        process.currentDirectoryURL = workingDirectory()

        let stdinPipe = Pipe(), stdoutPipe = Pipe(), stderrPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw usingShell ? ClaudeError.notFound : ClaudeError.failed("Could not launch claude: \(error.localizedDescription)")
        }

        // Read stdout/stderr concurrently so a full pipe buffer can never deadlock.
        var outData = Data(), errData = Data()
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async { outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile(); group.leave() }
        group.enter()
        DispatchQueue.global().async { errData = stderrPipe.fileHandleForReading.readDataToEndOfFile(); group.leave() }

        let stdinHandle = stdinPipe.fileHandleForWriting
        try? stdinHandle.write(contentsOf: Data(text.utf8))
        try? stdinHandle.close()

        if group.wait(timeout: .now() + requestTimeout) == .timedOut {
            process.terminate()
            group.wait()
            process.waitUntilExit()
            throw ClaudeError.timedOut
        }
        process.waitUntilExit()

        let out = String(decoding: outData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        let err = String(decoding: errData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)

        if process.terminationStatus != 0 {
            if usingShell && (process.terminationStatus == 127 || err.contains("command not found")) {
                throw ClaudeError.notFound
            }
            let detail = err.isEmpty ? out : err
            throw ClaudeError.failed(detail.isEmpty
                ? "claude exited with status \(process.terminationStatus)."
                : String(detail.suffix(500)))
        }
        if out.isEmpty { throw ClaudeError.empty }
        return out
    }
}
