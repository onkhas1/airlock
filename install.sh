#!/bin/sh
# Установка Airlock без Homebrew:
#   curl -fsSL https://raw.githubusercontent.com/onkhas1/airlock/main/install.sh | sh
# Скачивает последний релиз с GitHub, кладёт в /Applications (или ~/Applications) и запускает.
set -eu

REPO="onkhas1/airlock"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [ -n "${AIRLOCK_ZIP:-}" ]; then
  cp "$AIRLOCK_ZIP" "$TMP/Airlock.zip"
else
  echo "→ Ищу последнюю версию Airlock…"
  URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*\.zip"' | head -1 | sed -E 's/.*"(https[^"]+)"/\1/')
  if [ -z "$URL" ]; then
    echo "Не нашёл релиз на github.com/$REPO" >&2
    exit 1
  fi
  echo "→ Скачиваю $URL"
  curl -fsSL "$URL" -o "$TMP/Airlock.zip"
fi

ditto -x -k "$TMP/Airlock.zip" "$TMP"

DEST="${AIRLOCK_DEST:-/Applications}"
if [ ! -w "$DEST" ]; then DEST="$HOME/Applications"; fi
mkdir -p "$DEST"

# Закрываем старую версию: при выходе Airlock сам отпускает всё замороженное
pkill -TERM -f "Airlock.app/Contents/MacOS/Airlock" 2>/dev/null || true
sleep 1
rm -rf "$DEST/Airlock.app"
mv "$TMP/Airlock.app" "$DEST/"
# Бесплатная программа без платной подписи Apple: снимаем пометку «скачано из интернета»
xattr -dr com.apple.quarantine "$DEST/Airlock.app" 2>/dev/null || true

echo "✓ Airlock установлен в $DEST"
if [ -f "$HOME/Library/LaunchAgents/app.airlock.mac.plist" ]; then
  launchctl kickstart -k "gui/$(id -u)/app.airlock.mac" 2>/dev/null || open "$DEST/Airlock.app"
elif [ -z "${AIRLOCK_NO_OPEN:-}" ]; then
  open "$DEST/Airlock.app"
fi
