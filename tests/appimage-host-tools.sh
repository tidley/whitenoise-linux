#!/usr/bin/env bash
# Run on a distribution newer than the AppDir's build distribution.
set -euo pipefail
appdir="$(realpath "${1:?AppDir required}")"
probe="$(realpath "${2:?compiled appimage-host-probe required}")"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/wn-host-tools.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
mkdir "$fixture/host" "$fixture/shadow"
printf '#!/bin/sh\nprintf "host\\n"\n' > "$fixture/host/wn-path-check"
printf '#!/bin/sh\nprintf "wrong-path\\n"\n' > "$fixture/shadow/wn-path-check"
chmod +x "$fixture/host/wn-path-check" "$fixture/shadow/wn-path-check"
export PATH="$fixture/host:$PATH"
# Establish that the host tools work without the AppImage environment first.
curl --version
gio help open
test_zenity=0
if command -v zenity >/dev/null; then
  zenity --version
  test_zenity=1
fi
export APPDIR="$appdir"
. "$appdir/usr/lib/whitenoise-linux/appimage-desktop-env.sh"
export PATH="$fixture/shadow:$PATH"
test "$("$probe" wn-path-check)" = host
"$probe" --tool curl --version
"$probe" gio help open
if [ "$test_zenity" = 1 ]; then
  zenity --version
  "$probe" zenity --version
fi
# A packaged helper's direct execution still receives the bundled environment.
test "$("$probe" --tool /usr/bin/printenv LD_LIBRARY_PATH)" = "$LD_LIBRARY_PATH"
