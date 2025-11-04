#!/usr/bin/env bash
set -euo pipefail

SIGNED_APP="/Users/julianfalk/Documents/coding/projects/2025/InputLocker 2025-11-04 10-45-46/InputLocker.app"
PROJECT_DIR="/Users/julianfalk/Documents/coding/projects/2025/InputLocker"
BACKGROUND="$PROJECT_DIR/AssetsSource/Install/dmg-background.png"
VOL_ICON="$SIGNED_APP/Contents/Resources/AppIcon.icns"
OUTPUT="$PROJECT_DIR/InputLocker-drag.dmg"

# Match the Finder window to the background size so the artwork fits exactly.
read -r BG_WIDTH BG_HEIGHT < <(sips -g pixelWidth -g pixelHeight "$BACKGROUND" 2>/dev/null | awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {print w, h}')
BG_WIDTH=${BG_WIDTH:-680}
BG_HEIGHT=${BG_HEIGHT:-420}

APP_ICON_X=$(printf "%.0f" "$(echo "$BG_WIDTH * 0.25" | bc -l)")
DROP_ICON_X=$(printf "%.0f" "$(echo "$BG_WIDTH * 0.72" | bc -l)")
APP_ICON_Y=$(printf "%.0f" "$(echo "$BG_HEIGHT * 0.18" | bc -l)")
DROP_ICON_Y="$APP_ICON_Y"

# Detach any previously mounted temp images; ignore errors.
hdiutil detach /Volumes/dmg.MkU3G8 2>/dev/null || true
hdiutil detach /Volumes/InputLocker 2>/dev/null || true

cd "$PROJECT_DIR"

rm -rf release-staging "$OUTPUT"
mkdir release-staging
cp -R "$SIGNED_APP" release-staging/

create-dmg \
  --volname "InputLocker" \
  --volicon "$VOL_ICON" \
  --background "$BACKGROUND" \
  --window-pos 200 120 \
  --window-size "$BG_WIDTH" "$BG_HEIGHT" \
  --icon-size 96 \
  --icon "InputLocker.app" "$APP_ICON_X" "$APP_ICON_Y" \
  --app-drop-link "$DROP_ICON_X" "$DROP_ICON_Y" \
  --hide-extension "InputLocker.app" \
  "$OUTPUT" \
  release-staging
