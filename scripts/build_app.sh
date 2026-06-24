#!/usr/bin/env bash
# build_app.sh — build FretApp and assemble a proper Fret.app bundle (menu-bar
# agent, no dock icon). Signs with Developer ID + hardened runtime when a cert is
# present (falls back to ad-hoc), and optionally notarizes + staples so the app
# opens cleanly on other Macs.
#
#   scripts/build_app.sh                  # build (Developer ID if available, else ad-hoc)
#   scripts/build_app.sh --install        # build + copy to /Applications + launch
#   scripts/build_app.sh --notarize       # build + Developer ID + notarize + staple
#   scripts/build_app.sh --notarize --install
#   ADHOC=1 scripts/build_app.sh          # force ad-hoc signing
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
APP="$REPO/dist/Fret.app"
BUNDLE_ID="com.fret.app"
NOTARY_PROFILE="${NOTARY_PROFILE:-fret-notary}"
DEVID="${DEVID:-$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Developer ID Application/{print $2; exit}')}"
WANT_NOTARIZE=0; WANT_INSTALL=0
for a in "$@"; do case "$a" in --notarize) WANT_NOTARIZE=1;; --install) WANT_INSTALL=1;; esac; done

echo "fret: building FretApp…"
( cd "$REPO" && swift build -c release --product FretApp )
BIN="$REPO/.build/release/FretApp"

echo "fret: assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp -f "$BIN" "$APP/Contents/MacOS/Fret"
chmod +x "$APP/Contents/MacOS/Fret"
cp -f "$REPO/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Fret</string>
  <key>CFBundleDisplayName</key><string>Fret</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleExecutable</key><string>Fret</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIconName</key><string>AppIcon</string>
  <key>NSHumanReadableCopyright</key><string>Fret</string>
</dict>
</plist>
PLIST

# Sign. Developer ID + hardened runtime + secure timestamp when a cert exists
# (required for notarization); otherwise ad-hoc (local-only).
if [ -n "$DEVID" ] && [ "${ADHOC:-0}" != "1" ]; then
  codesign --force --options runtime --timestamp --sign "$DEVID" "$APP"
  echo "fret: signed with $DEVID"
else
  codesign --force --deep --sign - "$APP" >/dev/null 2>&1 && echo "fret: ad-hoc signed (local only)"
fi

if [ "$WANT_NOTARIZE" = "1" ]; then
  [ -n "$DEVID" ] || { echo "fret: --notarize needs a Developer ID cert; aborting."; exit 1; }
  ZIP="$REPO/dist/Fret.zip"; rm -f "$ZIP"
  ditto -c -k --keepParent "$APP" "$ZIP"
  echo "fret: submitting to Apple notary service (this takes a few minutes)…"
  xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP"
  rm -f "$ZIP"
  echo "fret: notarized + stapled."
  spctl -a -vvv -t install "$APP" 2>&1 | head -3
fi

echo "fret: built $APP"
if [ "$WANT_INSTALL" = "1" ]; then
  rm -rf "/Applications/Fret.app"
  cp -R "$APP" "/Applications/Fret.app"
  open "/Applications/Fret.app"
  echo "fret: installed to /Applications and launched — look for the mood glyph in your menu bar."
fi
