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
feat(modes): add a summarize mode
fix(runner): handle claude binaries installed via asdf
docs: document the timeout setting
```

Common types: `feat`, `fix`, `refactor`, `perf`, `docs`, `build`, `ci`, `chore`.

## Releasing

Tag the release and push the tag:

```bash
git tag -a v1.1.0 -m "GrammarBar 1.1.0" && git push origin v1.1.0
```

The [Release workflow](.github/workflows/release.yml) then:

1. builds the app, signs it with the project's self-signed certificate and publishes `GrammarBar.zip`
   plus its checksum to GitHub Releases (used by both Homebrew and `install.sh`);
2. updates `version` and `sha256` in [sarifmiaa/homebrew-tap](https://github.com/sarifmiaa/homebrew-tap),
   so `brew upgrade --cask grammarbar` picks up the new version.

Signing needs the `MACOS_SIGN_P12_BASE64` and `MACOS_SIGN_P12_PASSWORD` secrets; the workflow refuses to release
without them, because a different certificate would change the app's code identity and reset macOS permissions.

Step 2 needs a `HOMEBREW_TAP_TOKEN` repository secret: a fine-grained personal access token limited to the
`homebrew-tap` repository with **Contents: Read and write**. Without it (and for pre-release tags such as `v1.1.0-beta.1`)
the step is skipped and the cask can be bumped manually with `brew bump-cask-pr --version 1.1.0 sarifmiaa/tap/grammarbar`.

## Reporting bugs

Please open an issue with your macOS version, how Claude Code is installed (`which claude`, `claude --version`),
the mode you used, and the error shown in the card.
