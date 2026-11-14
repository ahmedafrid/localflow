#!/bin/bash
# LocalFlow one-line installer for macOS and Linux:
#   curl -fsSL https://raw.githubusercontent.com/ahmedafrid/localflow/main/install.sh | bash
# Downloads only the app files (about 100 KB), installs uv if needed, and starts LocalFlow.
set -euo pipefail
BASE="https://raw.githubusercontent.com/ahmedafrid/localflow/main"
UV="$(command -v uv || echo "$HOME/.local/bin/uv")"

if [ ! -x "$UV" ]; then
  echo "→ Installing uv (runs Python apps, about 30 MB)"
  curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null
fi

fetch() { curl -fsSL --retry 3 --connect-timeout 15 --max-time 120 "$BASE/$1" -o "$2/$1"; }

if [ "$(uname)" = "Darwin" ]; then
  [ "$(uname -m)" = "arm64" ] || { echo "✗ LocalFlow on macOS needs an Apple Silicon Mac (M1 or newer)."; exit 1; }
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "→ macOS needs its command line tools once. Click Install in the window that opens, then run this command again."
    xcode-select --install || true
    exit 1
  fi
  SRC="$(mktemp -d)"                       # build.sh copies the code into place and builds the app
  for f in flow.py ui.html build.sh; do fetch "$f" "$SRC"; done
  chmod +x "$SRC/build.sh"
  "$SRC/build.sh"
  rm -rf "$SRC"
else
  DIR="${XDG_DATA_HOME:-$HOME/.local/share}/LocalFlow/app"
  mkdir -p "$DIR"
  for f in flow.py ui.html; do fetch "$f" "$DIR"; done
  command -v xclip >/dev/null || command -v wl-copy >/dev/null || \
    echo "! Install a clipboard tool so LocalFlow can paste: sudo apt install xclip (Fedora: sudo dnf install xclip)"
  mkdir -p "$HOME/.config/autostart"         # start at login
  cat > "$HOME/.config/autostart/localflow.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=LocalFlow
Exec="$UV" run --quiet "$DIR/flow.py"
X-GNOME-Autostart-enabled=true
EOF
  echo "→ Starting LocalFlow (the first start downloads the speech model, this can take a few minutes)"
  nohup "$UV" run --quiet "$DIR/flow.py" --show >/dev/null 2>&1 &
  echo "✓ LocalFlow installed. Hold Right Ctrl to talk. It starts automatically when you log in."
fi
