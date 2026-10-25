# AppImage desktop libraries

The UI uses Odin, Clay and SDL3. On Wayland, SDL's libdecor integration can
load GTK even though GTK is not a direct ELF dependency of the application.
The AppImage also needs GLib, GIO, GDK-Pixbuf and librsvg through its media
and document dependencies.

`scripts/deploy-appimage-desktop.sh` runs after linuxdeploy in both AppImage
workflows. It deploys GTK3 and the build system's GIO, Pixbuf and GTK modules
with their dependency closures. Build dependencies include GVfs,
glib-networking and the librsvg Pixbuf loader. Keep deployment on the same
distribution as the application build. Do not copy modules from the target
desktop into the AppDir.

`packaging/appimage/AppRun` saves the original library, module, data and PATH
environment before it selects bundled values. Host curl, notifications and
external-link commands restore that snapshot in their child environment.
The application and packaged helpers retain bundled libraries and modules.
SDL's internal zenity fallback uses a static PATH launcher that restores the
same snapshot before it starts the host zenity. A shell launcher is not safe
because the host shell can also load incompatible bundled libraries.
Empty and unset variables
remain distinct. Restarting the AppImage retains the original snapshot.

The launcher does not
disable GIO, SVG, Wayland or file dialogs. The bundled GVfs client talks to
the desktop's existing GVfs services over D-Bus; backend daemons remain host
services. `GIO_EXTRA_MODULES` is cleared because extra host modules have the
same ABI risk as the default host directory. Host icon themes remain usable.
GI typelibs are not used by this native application.

Pixbuf and GTK input-method caches contain library basenames, resolved by
`g_module_open` through the bundled `LD_LIBRARY_PATH`. They contain no build
or mount paths. This works with a read-only AppDir at arbitrary locations,
including paths with spaces, without changing the working directory or
creating a writable loader cache at startup.

## Regression checks

Both workflows compile `tests/appimage-desktop-probe.c` and run
`tests/appimage-desktop-smoke.sh AppDir build/appimage-desktop-probe` before
signing. This requires Xvfb, xauth and D-Bus. It checks:

- A real GVfs client, including a `trash:///` metadata request to the daemon.
- SVG decoding of Adwaita's `image-missing.svg`.
- Themed icon rendering and file selection in a visible GTK file chooser.

The existing packaged SDL dummy-driver startup test remains separate. It
checks application boot, but cannot exercise the Wayland/libdecor GTK path.
The release workflow also extracts that same AppImage in an Arch container.
It runs `tests/appimage-host-tools.sh` against host curl, gio and zenity with
the production process-environment code. This checks newer host libraries
without rebuilding the application. The test executable is not shipped.
When changing this deployment, also test the AppImage under Wayland on a
distribution newer than the build system. For an isolated reproduction, use
a Debian 13 container with Weston headless, libdecor's GTK plugin, GTK3,
GVfs, librsvg's Pixbuf loader and the system libraries excluded by linuxdeploy
(installing the distribution's libmpv package supplies the latter).

Run Weston with a private mode-0700 `XDG_RUNTIME_DIR`, then launch the image
with `WAYLAND_DISPLAY` pointing to its socket and `SDL_VIDEODRIVER=wayland`.
Use a fresh data directory and `WN_SHOT=1 WN_SHOT_FRAME=120 WN_VAULT_PW=smoke`
to verify startup and normal shutdown. Do not set GIO or Pixbuf overrides.
Test the extracted AppDir after relocation too. In containers without FUSE,
the AppImage runtime's `--appimage-extract-and-run` provides a separate
dynamic-extraction-path check; this is not a FUSE-mount test.

## Failure that motivated the check

`WhiteNoise-v2026.10.23-build.2-x86_64.AppImage` bundled Ubuntu 24.04 GLib
and librsvg but no corresponding GIO or Pixbuf modules. Its `AppRun` was a
symlink to the ELF executable, with `$ORIGIN/../lib` as its RUNPATH.
On Debian 13 Wayland, host GTK loaded host modules against those libraries:

- `gvfs/libgvfscommon.so` required `g_variant_builder_init_static`.
- `libpixbufloader_svg.so` required `rsvg_handle_get_pixbuf_and_error`.

Neither symbol exists in the corresponding bundled library. The Debian
libraries export both. A Wayland launch under Weston reproduces the original
GTK assertion and exit status 134. Setting `GIO_MODULE_DIR=/dev/null` and
`GDK_PIXBUF_MODULE_FILE=/dev/null` avoids those modules but also removes
functionality; that diagnostic workaround is not part of the fix.
