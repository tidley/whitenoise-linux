#!/usr/bin/env bash
# Run after the main linuxdeploy pass, on the same build distribution.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
appdir="$(realpath "${1:?AppDir required}")"
linuxdeploy="$(realpath "${2:?linuxdeploy required}")"
gio_modules="$(pkg-config --variable=giomoduledir gio-2.0)"
pixbuf_modules="$(pkg-config --variable=gdk_pixbuf_moduledir gdk-pixbuf-2.0)"
pixbuf_cache="$(pkg-config --variable=gdk_pixbuf_cache_file gdk-pixbuf-2.0)"
gtk_lib="$(pkg-config --variable=libdir gtk+-3.0)"
gtk_modules="$gtk_lib/gtk-3.0/$(pkg-config --variable=gtk_binary_version gtk+-3.0)"
schemas="$(pkg-config --variable=schemasdir gio-2.0)"

# DT_NEEDED cannot discover these plugins. Deploy their dependency closures,
# including libgvfscommon, TLS/proxy providers and the matching librsvg.
test -f "$gio_modules/libgvfsdbus.so"
grep -q '^"svg" ' "$pixbuf_cache"
libraries=(--library "$gtk_lib/libgtk-3.so.0")
while IFS= read -r -d '' module; do
  libraries+=(--library "$module")
done < <(find "$gio_modules" "$pixbuf_modules" "$gtk_modules" -name '*.so' -print0)
"$linuxdeploy" --appdir "$appdir" "${libraries[@]}"

# linuxdeploy places libraries in usr/lib. Point module discovery there without
# retaining symlinks or absolute paths into the build host's multiarch tree.
mkdir -p "$appdir/usr/lib/gio/modules" "$appdir/usr/lib/gdk-pixbuf-2.0" \
  "$appdir/usr/lib/gtk-3.0" "$appdir/usr/share/glib-2.0"
for module in "$gio_modules/"*.so; do
  ln -sfn "../../$(basename "$module")" "$appdir/usr/lib/gio/modules/$(basename "$module")"
done
gio-querymodules "$appdir/usr/lib/gio/modules"
for directory in immodules printbackends; do
  mkdir -p "$appdir/usr/lib/gtk-3.0/$(basename "$gtk_modules")/$directory"
  for module in "$gtk_modules/$directory/"*.so; do
    test -f "$module" || continue
    ln -sfn "../../../$(basename "$module")" \
      "$appdir/usr/lib/gtk-3.0/$(basename "$gtk_modules")/$directory/$(basename "$module")"
  done
done

# g_module_open resolves basenames through LD_LIBRARY_PATH. Unlike absolute
# cache entries, these work at any FUSE mount/extraction path, with no writable
# AppDir, per-launch cache generation, temporary files or working-dir change.
sed -E 's|^".*/([^/]+\.so)"[[:space:]]*$|"\1"|' "$pixbuf_cache" \
  > "$appdir/usr/lib/gdk-pixbuf-2.0/loaders.cache"
sed -E 's|^".*/([^/]+\.so)"[[:space:]]*$|"\1"|' "$gtk_modules/immodules.cache" \
  > "$appdir/usr/lib/gtk-3.0/immodules.cache"
cp -a "$schemas" "$appdir/usr/share/glib-2.0/"
glib-compile-schemas "$appdir/usr/share/glib-2.0/schemas"
install -m 644 "$here/packaging/appimage/desktop-env.sh" \
  "$appdir/usr/lib/whitenoise-linux/appimage-desktop-env.sh"
mkdir -p "$appdir/usr/lib/whitenoise-linux/host-bin"
cc -static -O2 "$here/packaging/appimage/host-zenity.c" \
  -o "$appdir/usr/lib/whitenoise-linux/host-bin/zenity"
# AppRun is normally a symlink to the binary. Unlink before installing a script.
rm -f "$appdir/AppRun"
install -m 755 "$here/packaging/appimage/AppRun" "$appdir/AppRun"
