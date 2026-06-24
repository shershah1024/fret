#!/usr/bin/env bash
# install_agent.sh — install the headless `fret` CLI as a per-user LaunchAgent
# (starts at login, restarts if it dies, nags via banners). Use this if you want
# the daemon without the menu-bar app.
#
#   scripts/install_agent.sh                 # sass 2, 60s tick
#   SASS=3 INTERVAL=30 scripts/install_agent.sh
#   scripts/install_agent.sh uninstall
set -euo pipefail

LABEL="com.fret.agent"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
APPDIR="$HOME/Library/Application Support/Fret"
BIN="$APPDIR/fret"
LOG="$HOME/Library/Logs/fret.log"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SASS="${SASS:-2}"; INTERVAL="${INTERVAL:-60}"

uninstall() {
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  rm -f "$PLIST"; echo "fret: agent uninstalled"
}
[ "${1:-}" = "uninstall" ] && { uninstall; exit 0; }

( cd "$REPO" && swift build -c release --product fret )
mkdir -p "$APPDIR" "$(dirname "$LOG")" "$(dirname "$PLIST")"
cp -f "$REPO/.build/release/fret" "$BIN"; chmod +x "$BIN"

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BIN</string><string>--notify</string>
    <string>--sass</string><string>$SASS</string>
    <string>--interval</string><string>$INTERVAL</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ProcessType</key><string>Background</string>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
PLIST

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "fret: agent installed (sass $SASS, ${INTERVAL}s). log: $LOG"
