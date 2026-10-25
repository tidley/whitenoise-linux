#+build linux
package main

import "core:strings"
import "core:testing"

@(test)
appimage_host_environment_restores_original_values :: proc(t: ^testing.T) {
	source := []string{
		"WN_APPIMAGE_ENV_SAVED=1",
		"LD_LIBRARY_PATH=/bundle/lib", "WN_APPIMAGE_ORIGINAL_LD_LIBRARY_PATH=1/original lib:a=b",
		"GIO_MODULE_DIR=/bundle/modules", "WN_APPIMAGE_ORIGINAL_GIO_MODULE_DIR=",
		"GTK_PATH=/bundle/gtk", "WN_APPIMAGE_ORIGINAL_GTK_PATH=1",
		"XDG_DATA_DIRS=/bundle/share:/usr/share", "WN_APPIMAGE_ORIGINAL_XDG_DATA_DIRS=1/custom:/usr/share",
		"KEEP=a=b", "all_proxy=socks5h://example.invalid:9050",
	}
	env, err := appimage_host_environment(source)
	testing.expect(t, err == nil)
	for expected in ([]string{"LD_LIBRARY_PATH=/original lib:a=b", "GTK_PATH=", "XDG_DATA_DIRS=/custom:/usr/share", "KEEP=a=b", "all_proxy=socks5h://example.invalid:9050"}) {
		found := false
		for entry in env {if entry == expected {found = true}}
		testing.expect(t, found, expected)
	}
	for entry in env {
		testing.expect(t, !strings.has_prefix(entry, "WN_APPIMAGE_"), entry)
		testing.expect(t, !strings.has_prefix(entry, "GIO_MODULE_DIR="), entry)
	}
	testing.expect(t, source[1] == "LD_LIBRARY_PATH=/bundle/lib", "Do not change the application's environment.")
}

@(test)
appimage_host_environment_leaves_non_appimage_launches_unchanged :: proc(t: ^testing.T) {
	source := []string{"LD_LIBRARY_PATH=/custom", "GIO_MODULE_DIR=/custom/modules", "KEEP=1"}
	env, err := appimage_host_environment(source)
	testing.expect(t, err == nil && len(env) == len(source))
	for entry, i in env {testing.expect(t, entry == source[i])}
}

@(test)
appimage_host_environment_distinguishes_empty_and_unset_path :: proc(t: ^testing.T) {
	for saved in ([]string{"", "1"}) {
		source := []string{
			"WN_APPIMAGE_ENV_SAVED=1", "PATH=/bundle/host-bin:/usr/bin",
			strings.concatenate({"WN_APPIMAGE_ORIGINAL_PATH=", saved}, context.temp_allocator),
		}
		env, err := appimage_host_environment(source)
		testing.expect(t, err == nil)
		testing.expect(t, len(env) == (saved == "" ? 0 : 1))
		if len(env) == 1 {testing.expect(t, env[0] == "PATH=")}
	}
}
