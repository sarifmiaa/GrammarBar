#!/bin/bash
#
# GrammarBar installer — https://github.com/sarifmiaa/GrammarBar
#
#   curl -fsSL https://sarifmiaa.github.io/GrammarBar/install.sh | bash
#
# Options (pass after `bash -s --`):
#   --uninstall   remove GrammarBar
#   --purge       with --uninstall, also delete history and settings
#
# Environment:
#   GRAMMARBAR_VERSION=1.0.3   install a specific version instead of the latest
#
# The script downloads the release zip from GitHub, checks its SHA-256 checksum and code signature,
# and installs GrammarBar.app into /Applications (or ~/Applications if /Applications isn't writable).
# Files downloaded with curl are not quarantined, so macOS opens the app without a Gatekeeper prompt.

set -euo pipefail

REPO="sarifmiaa/GrammarBar"
APP="GrammarBar.app"
BUNDLE_ID="local.grammarbar"
# Every release is signed with the project's self-signed certificate; this is its fingerprint.
CERT_ROOT='certificate root = H"1bd487de5e740619d23adf616a675eff9b27a1c3"'
TMP_DIR=""
trap 'if [ -n "$TMP_DIR" ]; then rm -rf "$TMP_DIR"; fi' EXIT

if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; RESET=""
fi

say()  { printf '%s\n' "$*"; }
step() { printf '%s==>%s %s%s%s\n' "$GREEN" "$RESET" "$BOLD" "$*" "$RESET"; }
warn() { printf '%sWarning:%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()  { printf '%sError:%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

quit_app() {
  if pgrep -x GrammarBar >/dev/null 2>&1; then
    osascript -e "quit app id \"$BUNDLE_ID\"" >/dev/null 2>&1 || pkill -x GrammarBar || true
    sleep 1
  fi
}

installed_paths() {
  for dir in /Applications "$HOME/Applications"; do
    [ -d "$dir/$APP" ] && printf '%s\n' "$dir/$APP"
  done
  return 0
}

managed_by_homebrew() {
  command -v brew >/dev/null 2>&1 && brew list --cask grammarbar >/dev/null 2>&1
}

uninstall() {
  local purge="$1"
  if managed_by_homebrew; then
    die "GrammarBar was installed with Homebrew. Remove it with: brew uninstall --cask${purge:+ --zap} grammarbar"
  fi
  step "Uninstalling GrammarBar"
  quit_app
  local removed=0
  while IFS= read -r path; do
    rm -rf "$path" && say "Removed $path" && removed=1
  done < <(installed_paths)
  [ "$removed" = 1 ] || say "GrammarBar is not installed."
  if [ -n "$purge" ]; then
    defaults delete "$BUNDLE_ID" >/dev/null 2>&1 || true
    rm -f "$HOME/Library/Preferences/$BUNDLE_ID.plist"
    say "Deleted history and settings."
  fi
}

find_claude() {
  for path in "$HOME/.local/bin/claude" "$HOME/.claude/local/claude" /opt/homebrew/bin/claude /usr/local/bin/claude; do
    [ -x "$path" ] && return 0
  done
  /bin/zsh -lic 'command -v claude' >/dev/null 2>&1
}

install() {
  if managed_by_homebrew; then
    say "GrammarBar is managed by Homebrew. Update it with: ${BOLD}brew upgrade --cask grammarbar${RESET}"
    exit 0
  fi

  local tag
  if [ -n "${GRAMMARBAR_VERSION:-}" ]; then
    tag="v${GRAMMARBAR_VERSION#v}"
  else
    local latest
    latest="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest")" \
      || die "Could not reach GitHub."
    tag="${latest##*/}"
    [[ "$tag" == v* ]] || die "Could not determine the latest GrammarBar release."
  fi

  local base="https://github.com/$REPO/releases/download/$tag"
  TMP_DIR="$(mktemp -d -t grammarbar)"
  local tmp="$TMP_DIR"

  step "Downloading GrammarBar ${tag#v}"
  curl -fL --progress-bar -o "$tmp/GrammarBar.zip" "$base/GrammarBar.zip" || die "Download failed for $tag."
  curl -fsSL -o "$tmp/GrammarBar.zip.sha256" "$base/GrammarBar.zip.sha256" || die "Checksum file missing for $tag."

  step "Verifying"
  local expected actual
  expected="$(cut -d ' ' -f 1 "$tmp/GrammarBar.zip.sha256")"
  actual="$(shasum -a 256 "$tmp/GrammarBar.zip" | cut -d ' ' -f 1)"
  [ "$expected" = "$actual" ] || die "Checksum mismatch (expected $expected, got $actual)."
  say "${DIM}sha256 $actual${RESET}"

  ditto -x -k "$tmp/GrammarBar.zip" "$tmp/unpacked"
  [ -d "$tmp/unpacked/$APP" ] || die "The download does not contain $APP."
  codesign --verify --strict "$tmp/unpacked/$APP" 2>/dev/null || die "Code signature is invalid."
  codesign -d -r- "$tmp/unpacked/$APP" 2>&1 | grep -qF "$CERT_ROOT" \
    || die "$APP is not signed with the GrammarBar certificate. Versions before 1.0.3 can't be installed with this script."
  say "${DIM}signature ok${RESET}"

  local dest="/Applications"
  if [ ! -w "$dest" ]; then
    dest="$HOME/Applications"
    mkdir -p "$dest"
  fi

  step "Installing to $dest"
  quit_app
  rm -rf "${dest:?}/$APP"
  ditto "$tmp/unpacked/$APP" "$dest/$APP"
  xattr -dr com.apple.quarantine "$dest/$APP" 2>/dev/null || true

  open "$dest/$APP"

  say ""
  say "${GREEN}✓${RESET} ${BOLD}GrammarBar ${tag#v} is installed${RESET} — look for its icon in the menu bar."
  if ! find_claude; then
    say ""
    warn "Claude Code was not found. Install it and run \`claude\` once to log in:"
    say  "  https://docs.claude.com/en/docs/claude-code/overview"
  fi
  say ""
  say "${DIM}Start at login: System Settings → General → Login Items & Extensions → +${RESET}"
  say "${DIM}Update: run this installer again · Uninstall: curl -fsSL https://sarifmiaa.github.io/GrammarBar/install.sh | bash -s -- --uninstall${RESET}"
}

main() {
  [ "$(uname -s)" = "Darwin" ] || die "GrammarBar only runs on macOS."
  local major
  major="$(sw_vers -productVersion | cut -d . -f 1)"
  [ "$major" -ge 13 ] || die "GrammarBar requires macOS 13 Ventura or later."

  local mode="install" purge=""
  for arg in "$@"; do
    case "$arg" in
      --uninstall) mode="uninstall" ;;
      --purge)     purge="1" ;;
      -h|--help)   sed -n '2,17p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
      *)           die "Unknown option: $arg" ;;
    esac
  done

  if [ "$mode" = "uninstall" ]; then uninstall "$purge"; else install; fi
}

# Everything runs from main so a partially downloaded script never executes.
main "$@"
