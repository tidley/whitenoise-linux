# Sourced by AppRun and the desktop regression test. APPDIR is an absolute path.
# Save presence as well as value: an unset variable differs from an empty one.
# Preserve the first snapshot across helper launches and AppImage restarts.
if [ "${WN_APPIMAGE_ENV_SAVED-}" != 1 ]; then
  for wn_key in LD_LIBRARY_PATH GIO_MODULE_DIR GIO_EXTRA_MODULES \
    GDK_PIXBUF_MODULEDIR GDK_PIXBUF_MODULE_FILE GTK_PATH GTK_IM_MODULE_FILE \
    GSETTINGS_SCHEMA_DIR XDG_DATA_DIRS PATH; do
    eval 'export "WN_APPIMAGE_ORIGINAL_'"$wn_key"'=${'"$wn_key"'+1}${'"$wn_key"'-}"'
  done
  export WN_APPIMAGE_ENV_SAVED=1
fi
wn_library_path="${WN_APPIMAGE_ORIGINAL_LD_LIBRARY_PATH#?}"
wn_data_dirs="${WN_APPIMAGE_ORIGINAL_XDG_DATA_DIRS#?}"
wn_host_path="${WN_APPIMAGE_ORIGINAL_PATH#?}"
export LD_LIBRARY_PATH="$APPDIR/usr/lib${wn_library_path:+:$wn_library_path}"
export GIO_MODULE_DIR="$APPDIR/usr/lib/gio/modules"
# Extra host modules can require a newer GLib than the bundled one too.
unset GIO_EXTRA_MODULES
export GDK_PIXBUF_MODULEDIR="$APPDIR/usr/lib"
export GDK_PIXBUF_MODULE_FILE="$APPDIR/usr/lib/gdk-pixbuf-2.0/loaders.cache"
export GTK_PATH="$APPDIR/usr/lib/gtk-3.0"
export GTK_IM_MODULE_FILE="$APPDIR/usr/lib/gtk-3.0/immodules.cache"
export GSETTINGS_SCHEMA_DIR="$APPDIR/usr/share/glib-2.0/schemas"
export XDG_DATA_DIRS="$APPDIR/usr/share:${wn_data_dirs:-/usr/local/share:/usr/share}"
# SDL's fallback dialog launches zenity internally, outside host_process_exec.
export PATH="$APPDIR/usr/lib/whitenoise-linux/host-bin${wn_host_path:+:$wn_host_path}"
unset wn_key wn_library_path wn_data_dirs wn_host_path
