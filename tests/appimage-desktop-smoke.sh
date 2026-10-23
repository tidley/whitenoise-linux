#!/usr/bin/env bash
# Run after linuxdeploy, before signing. Requires Xvfb, D-Bus and GTK dev files.
set -euo pipefail
appdir="$(realpath "${1:?AppDir required}")"
probe="$(realpath "${2:?compiled appimage-desktop-probe required}")"
# Start the host session bus outside the bundled environment, as on a desktop.
xvfb-run -a dbus-run-session -- sh -eu -c '
  APPDIR="$1"; export APPDIR
  . "$APPDIR/usr/lib/whitenoise-linux/appimage-desktop-env.sh"
  exec "$2" /usr/share/icons/Adwaita/scalable/status/image-missing.svg
' sh "$appdir" "$probe"
