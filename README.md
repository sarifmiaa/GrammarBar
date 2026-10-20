<div align="center">

# GrammarBar

**Fix, polish and translate text from your Mac's menu bar — powered by [Claude Code](https://claude.com/claude-code).**

[**Website**](https://sarifmiaa.github.io/GrammarBar/) · [Download](https://github.com/sarifmiaa/GrammarBar/releases/latest) · [Homebrew](#homebrew-recommended)

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-000000?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0A84FF)
[![Build](https://github.com/sarifmiaa/GrammarBar/actions/workflows/build.yml/badge.svg)](https://github.com/sarifmiaa/GrammarBar/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/sarifmiaa/GrammarBar)](https://github.com/sarifmiaa/GrammarBar/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

GrammarBar is a tiny native menu bar app. Click the icon, paste a message, press <kbd>⌘</kbd><kbd>↩</kbd> —
the corrected text appears in the card and is already on your clipboard. No Dock icon, no main window,
no API keys to manage: it reuses the Claude Code CLI you are already logged in to.

<!-- Add a screenshot: save it as docs/screenshot.png and uncomment the line below. -->
<!-- <p align="center"><img src="docs/screenshot.png" width="420" alt="GrammarBar card open below the menu bar icon"></p> -->

## Features

- **Four modes** — *Fix grammar*, *Polish / make natural*, *Translate to English*, *Translate to German*. The last mode is remembered.
- **Clipboard-first** — every result is copied automatically; *Use as input* lets you chain modes (e.g. translate, then polish).
- **Stays out of the way** — lives only in the menu bar; the card stays open while you copy text from other apps and closes with <kbd>Esc</kbd>.
- **History** — the last 100 results, searchable, one click to restore, copy or delete.
- **Faithful output** — prompts tell Claude to change as little as necessary and to keep line breaks, names, links, emojis and tone (including *du/Sie* in German).
- **Never blocks the UI** — Claude runs in a background subprocess with a timeout.
- **Accessible** — full VoiceOver labels and announcements, keyboard-reachable controls, and support for *Increase contrast* and *Reduce motion*.

## Requirements

- macOS 13 Ventura or later (Apple Silicon or Intel)
- [Claude Code](https://docs.claude.com/en/docs/claude-code/overview) installed and logged in — run `claude` once in Terminal
- Xcode Command Line Tools to build (`xcode-select --install`)

## Installation

### Homebrew (recommended)

```bash
brew install --cask sarifmiaa/tap/grammarbar
```

Upgrade with `brew upgrade --cask grammarbar`, remove with `brew uninstall --cask grammarbar`
(add `--zap` to also delete history and settings).

### Build from source

```bash
git clone https://github.com/sarifmiaa/GrammarBar.git
cd GrammarBar
./build.sh
mv GrammarBar.app /Applications/ && open /Applications/GrammarBar.app
```

`build.sh` compiles a universal binary, writes the `Info.plist` and ad-hoc signs the bundle. No Xcode project is involved.
For a faster single-architecture build use `ARCHS=arm64 ./build.sh`.

> [!NOTE]
> The app is ad-hoc signed, not notarized. The Homebrew cask clears the download quarantine for you. If you download the zip from
> [Releases](https://github.com/sarifmiaa/GrammarBar/releases) manually, run `xattr -dr com.apple.quarantine GrammarBar.app`
> or allow it under **System Settings → Privacy & Security** on first launch.

### Start at login

**System Settings → General → Login Items & Extensions → Open at Login → `+`** and pick `GrammarBar` from `/Applications`.

## Usage

1. Click the GrammarBar icon (a text block with a checkmark) in the menu bar.
2. Choose a mode, type or paste text, press <kbd>⌘</kbd><kbd>↩</kbd>.
3. The result appears below the input and is copied to the clipboard.

### Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| <kbd>⌘</kbd><kbd>↩</kbd> | Submit |
| <kbd>⌘</kbd><kbd>1</kbd> … <kbd>⌘</kbd><kbd>4</kbd> | Switch mode |
| <kbd>Esc</kbd> | Leave history, then close the card |

## Configuration

Settings are constants in [`Sources/GrammarBar/Config.swift`](Sources/GrammarBar/Config.swift); rebuild after changing them.

| Constant | Default | Description |
| --- | --- | --- |
| `claudeModel` | `"haiku"` | Model passed to `claude --model`. Use `"sonnet"` for higher quality at slower speed. |
| `requestTimeout` | `120` | Seconds before a request is cancelled. |

The per-mode instructions live in [`Sources/GrammarBar/Models/Mode.swift`](Sources/GrammarBar/Models/Mode.swift) — adding a mode
(say, *Translate to Spanish*) is a new `case` there.

## How it works

For each request GrammarBar runs:

```bash
claude -p "<mode instruction>" --model haiku --output-format text   # your text is piped via stdin
```

- Text goes through **stdin**, never through a shell argument, so quotes and newlines can't break the command.
- The working directory is a temporary folder, so no project `CLAUDE.md` is loaded.
- GUI apps don't inherit your shell `PATH`, so the binary is looked up in
  `~/.local/bin`, `~/.claude/local`, `/opt/homebrew/bin` and `/usr/local/bin`. If it isn't there, GrammarBar
  falls back to a login shell (`/bin/zsh -lic`), which covers `nvm`/`asdf` setups.

## Privacy

- Your text is sent to Anthropic through your own Claude Code session — the same as typing it into `claude` yourself.
- GrammarBar has no servers, analytics or telemetry of its own.
- History (input, result, mode, timestamp) is stored **locally** in the app's preferences (`local.grammarbar`).
  Clear it from the History screen, or remove everything with `defaults delete local.grammarbar`.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| *"claude CLI not found"* | Install Claude Code and run `claude` once in Terminal to log in. If it lives somewhere unusual, make sure `zsh -lic 'command -v claude'` finds it. |
| Requests fail with an auth error | Run `claude` in Terminal and log in again. |
| Result includes extra commentary | Switch `claudeModel` to `"sonnet"`, or tighten the instruction in `Mode.swift`. |
| Card does not appear | Check that `GrammarBar` is running (Activity Monitor). Menu bar managers such as Bartender may hide the icon. |

## Project structure

```
Sources/GrammarBar/
├── App/
│   ├── GrammarBarApp.swift      # @main entry point
│   └── AppDelegate.swift        # status item, popover, Esc handling
├── Config.swift                 # model + timeout
├── Models/
│   ├── Mode.swift               # modes and their Claude instructions
│   ├── HistoryEntry.swift
│   └── GrammarModel.swift       # view model: submit, clipboard, history
├── Services/
│   └── ClaudeRunner.swift       # finds and runs the claude CLI
├── Support/
│   └── Accessibility.swift      # VoiceOver announcements
└── Views/
    ├── CardView.swift           # main card
    ├── HistoryView.swift
    ├── HistoryRow.swift
    └── Components/              # ModeChip, IconButton
```

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © Sarif Mia

GrammarBar is an independent project and is not affiliated with or endorsed by Anthropic.
