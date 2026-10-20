# Contributing to GrammarBar

Thanks for taking the time to contribute!

## Development setup

```bash
git clone https://github.com/sarifmiaa/GrammarBar.git
cd GrammarBar
ARCHS=arm64 ./build.sh     # fast local build (use x86_64 on Intel Macs)
open GrammarBar.app
```

There is no Xcode project: `build.sh` compiles every file under `Sources/` with `swiftc`. You can still edit in Xcode or
VS Code (with the Swift extension) — just build from the terminal.

To restart after a rebuild:

```bash
pkill -x GrammarBar; ./build.sh && open GrammarBar.app
```

## Guidelines

- **Keep it small.** No third-party dependencies; Swift, SwiftUI and AppKit only.
- **Keep the UI responsive.** Anything that touches the `claude` process runs off the main thread.
- **Keep it accessible.** New controls need an accessibility label; status changes should be announced with `announce(_:)`.
  Test with VoiceOver (<kbd>⌘</kbd><kbd>F5</kbd>) and with *Increase contrast* / *Reduce motion* enabled.
- **Match the surrounding code** — one type per file, grouped by `App`, `Models`, `Services`, `Support`, `Views`.
- Make sure `./build.sh` finishes without errors or warnings before opening a pull request.

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(ui): add Spanish translation mode
fix(runner): handle claude binaries installed via asdf
docs: document the timeout setting
```

Common types: `feat`, `fix`, `refactor`, `perf`, `docs`, `build`, `ci`, `chore`.

## Releasing

1. Tag the release — the [Release workflow](.github/workflows/release.yml) builds the app and publishes
   `GrammarBar.zip` plus its checksum to GitHub Releases:
   ```bash
   git tag -a v1.1.0 -m "GrammarBar 1.1.0" && git push origin v1.1.0
   ```
2. Update the cask in [sarifmiaa/homebrew-tap](https://github.com/sarifmiaa/homebrew-tap):
   ```bash
   brew bump-cask-pr --version 1.1.0 sarifmiaa/tap/grammarbar
   ```
   or edit `version` and `sha256` in `Casks/grammarbar.rb` using `GrammarBar.zip.sha256` from the release.

## Reporting bugs

Please open an issue with your macOS version, how Claude Code is installed (`which claude`, `claude --version`),
the mode you used, and the error shown in the card.
