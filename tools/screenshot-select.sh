#!/usr/bin/env bash
#
# Interactive Screenshot Selector 
#
# This script allows you to select a screen region, then copies the
# screenshot directly to the clipboard. It works on both X11 and
# Wayland environments, automatically detecting the session type
# and using the appropriate screenshot and clipboard tools.#
#
# Requirements:
#	- maim (for screen capture)
#	- xlip (for X11 clipboard) OR wl-copy (for Wayland clipboard)
#
# Usage:
#	Run the script directly or bind it to a key shortcut.
#
# Example: 
# 	./screenshot-select.sh
# 	OR
# 	Bind to Alt+Shift+4 for a MacOS style screenshot shortcut
#
#
# Note:
#	- The script detects session type via XDG_SESSION_TYPE or loginctl.
#	- Notifications use notify-send but failures are silenced to avoid
#	DBus errors if no notifications daemon is active.
#

set -euo pipefail

# Strict tool check helper
require_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo "Error: '$1' is required but not installed." >&2
    exit 1
  fi
}

# Determine session type
SESSION_TYPE="${XDG_SESSION_TYPE:-$(loginctl show-session $(loginctl | grep "$(whoami)" | awk '{print $1}') -p Type --value)}"

# === Wayland block ===
wayland_screenshot() {
  echo "Detected environment: Wayland"
  require_cmd grim
  require_cmd slurp
  require_cmd wl-copy

  echo "Select region for screenshot (Wayland)..."
  grim -g "$(slurp)" - | wl-copy

  # Notify only if no D-Bus error
  if command -v notify-send >/dev/null; then
    notify-send -u low "Screenshot" "📸 Region copied to clipboard (Wayland)" 2>/dev/null || true
  fi
}

# === X11 block ===
x11_screenshot() {
  echo "Detected environment: X11"
  require_cmd maim
  require_cmd xclip

  echo "Select region for screenshot (X11)..."
  maim -s | xclip -selection clipboard -t image/png

  if command -v notify-send >/dev/null; then
    notify-send -u low "Screenshot" "📸 Region copied to clipboard (X11)" 2>/dev/null || true
  fi
}

# === Routing ===
case "$SESSION_TYPE" in
  wayland)
    wayland_screenshot
    ;;
  x11)
    x11_screenshot
    ;;
  *)
    echo "Unsupported session type: $SESSION_TYPE" >&2
    exit 1
    ;;
esac

exit 0
