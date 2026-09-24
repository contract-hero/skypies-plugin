#!/usr/bin/env bash
#
# skypies-mcp-launch.sh — find the skypies app and exec the MCP server it ships.
#
# The plugin is a companion to the skypies Mac app. The app bundles the
# server at skypies.app/Contents/MacOS/skypies-mcp, signed with the app, so the
# server and the app always come from the same build. Nothing is downloaded.
#
# Resolution order:
#
#   1. $SKYPIES_MCP_BIN              — explicit override (a dev build).
#   2. /Applications, ~/Applications — the usual install places.
#   3. Spotlight, by bundle id       — the app installed somewhere else.
#
# Anything on stdout would corrupt the MCP stdio stream, so every message goes
# to stderr, which Claude Code captures as MCP server logs.
set -euo pipefail

BUNDLE_ID="ai.skypies.skypies"
DOWNLOAD_URL="https://github.com/contract-hero/skypies-releases/releases/latest/download/skypies-universal.dmg"
SERVER="Contents/MacOS/skypies-mcp"

log() { echo "skypies: $*" >&2; }

die() { log "$*"; exit 1; }

# --- 1. explicit override ---------------------------------------------------
if [ -n "${SKYPIES_MCP_BIN:-}" ]; then
  [ -x "${SKYPIES_MCP_BIN}" ] \
    || die "SKYPIES_MCP_BIN is set to '${SKYPIES_MCP_BIN}' but that file is not executable."
  exec "${SKYPIES_MCP_BIN}" "$@"
fi

[ "$(uname -s)" = "Darwin" ] || die "skypies runs on macOS only."

# --- 2. usual install places ------------------------------------------------
for app in "/Applications/skypies.app" "${HOME}/Applications/skypies.app"; do
  [ -x "${app}/${SERVER}" ] && exec "${app}/${SERVER}" "$@"
done

# --- 3. Spotlight -----------------------------------------------------------
# Skip build trees: a bundle under `target/` is a dev build, not an install.
while IFS= read -r app; do
  case "${app}" in */target/*) continue ;; esac
  [ -x "${app}/${SERVER}" ] && exec "${app}/${SERVER}" "$@"
done < <(mdfind "kMDItemCFBundleIdentifier == '${BUNDLE_ID}'" 2>/dev/null || true)

die "the skypies app is not installed, or it predates the bundled MCP server.
This plugin runs the server that ships inside the app.
Download it from ${DOWNLOAD_URL}, drag skypies to Applications, and open it once.
Then restart Claude Code."
