#!/usr/bin/env bash
set -euo pipefail
environment="$(realpath "${1:?desktop-env.sh required}")"
export APPDIR='/appimage test'
unset WN_APPIMAGE_ENV_SAVED LD_LIBRARY_PATH GDK_PIXBUF_MODULE_FILE
export GIO_EXTRA_MODULES=''
export GIO_MODULE_DIR='/host modules:a=b;$(false)'
export GTK_PATH=$'/host gtk\nsecond line'
export XDG_DATA_DIRS='/host/share:/usr/share'
. "$environment"
test "${WN_APPIMAGE_ENV_SAVED-}" = 1
test "${WN_APPIMAGE_ORIGINAL_LD_LIBRARY_PATH-unrecorded}" = ''
test "${WN_APPIMAGE_ORIGINAL_GIO_EXTRA_MODULES-}" = 1
test "${WN_APPIMAGE_ORIGINAL_GIO_MODULE_DIR-}" = '1/host modules:a=b;$(false)'
test "${WN_APPIMAGE_ORIGINAL_GTK_PATH-}" = $'1/host gtk\nsecond line'
test "${WN_APPIMAGE_ORIGINAL_XDG_DATA_DIRS-}" = '1/host/share:/usr/share'
# A second source/relaunch must not replace the original values with bundle paths.
. "$environment"
test "$WN_APPIMAGE_ORIGINAL_LD_LIBRARY_PATH" = ''
test "$WN_APPIMAGE_ORIGINAL_GIO_MODULE_DIR" = '1/host modules:a=b;$(false)'
test "$LD_LIBRARY_PATH" = "$APPDIR/usr/lib"
printf '%s\n' 'AppImage environment snapshot: OK'
