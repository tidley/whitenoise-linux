# Sourced by AppRun and the desktop regression test. APPDIR is an absolute path.
export LD_LIBRARY_PATH="$APPDIR/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export GIO_MODULE_DIR="$APPDIR/usr/lib/gio/modules"
# Extra host modules can require a newer GLib than the bundled one too.
unset GIO_EXTRA_MODULES
export GDK_PIXBUF_MODULEDIR="$APPDIR/usr/lib"
export GDK_PIXBUF_MODULE_FILE="$APPDIR/usr/lib/gdk-pixbuf-2.0/loaders.cache"
export GTK_PATH="$APPDIR/usr/lib/gtk-3.0"
export GTK_IM_MODULE_FILE="$APPDIR/usr/lib/gtk-3.0/immodules.cache"
export GSETTINGS_SCHEMA_DIR="$APPDIR/usr/share/glib-2.0/schemas"
export XDG_DATA_DIRS="$APPDIR/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
