#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* SDL invokes zenity internally. This launcher must be static: even /bin/sh
 * can depend on host libraries incompatible with the AppImage's search path. */
int main(int argc, char **argv) {
    (void)argc;
    const char *active = getenv("WN_APPIMAGE_ENV_SAVED");
    if (!active || strcmp(active, "1"))
        return 127;
    const char *keys[] = {
        "LD_LIBRARY_PATH", "GIO_MODULE_DIR", "GIO_EXTRA_MODULES",
        "GDK_PIXBUF_MODULEDIR", "GDK_PIXBUF_MODULE_FILE", "GTK_PATH",
        "GTK_IM_MODULE_FILE", "GSETTINGS_SCHEMA_DIR", "XDG_DATA_DIRS", "PATH",
    };
    for (size_t i = 0; i < sizeof(keys) / sizeof(keys[0]); i++) {
        char saved[128];
        snprintf(saved, sizeof(saved), "WN_APPIMAGE_ORIGINAL_%s", keys[i]);
        const char *value = getenv(saved);
        if (value && value[0] == '1') {
            if (setenv(keys[i], value + 1, 1))
                return 127;
        } else if (unsetenv(keys[i])) {
            return 127;
        }
        if (unsetenv(saved))
            return 127;
    }
    if (unsetenv("WN_APPIMAGE_ENV_SAVED"))
        return 127;
    argv[0] = "zenity";
    execvp(argv[0], argv);
    perror("zenity");
    return 127;
}
