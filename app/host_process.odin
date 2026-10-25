package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"

// Host programs must use the desktop's libraries and modules, not the AppImage's.
// Packaged helpers continue to use os.process_exec/start with the bundle environment.
@(private)
host_process_exec :: proc(
	desc: os.Process_Desc,
	allocator: runtime.Allocator,
) -> (state: os.Process_State, stdout, stderr: []u8, err: os.Error) {
	desc := desc
	when ODIN_OS == .Linux {
		desc.env, err = appimage_host_environment(desc.env)
		if err != nil {return {}, nil, nil, err}
		if os.get_env("WN_APPIMAGE_ENV_SAVED", context.temp_allocator) == "1" &&
		   len(desc.command) > 0 && strings.index_byte(desc.command[0], '/') < 0 {
			// Odin searches the parent's PATH, not desc.env's PATH. Resolve the
			// host command in a clean child instead, without interpolating argv.
			args := make([]string, len(desc.command) + 4, context.temp_allocator)
			copy(args[:4], []string{"/bin/sh", "-c", "exec \"$@\"", "sh"})
			copy(args[4:], desc.command)
			desc.command = args
		}
	}
	return os.process_exec(desc, allocator)
}

@(private)
appimage_host_environment :: proc(source: []string) -> (environment: []string, err: os.Error) {
	source := source
	if source == nil {
		source, err = os.environ(context.temp_allocator)
		if err != nil {return nil, err}
	}
	active := false
	for entry in source {if entry == "WN_APPIMAGE_ENV_SAVED=1" {active = true}}
	if !active {return source, nil}

	prefix :: "WN_APPIMAGE_ORIGINAL_"
	saved := make(map[string]string, context.temp_allocator)
	for entry in source {
		separator := strings.index_byte(entry, '=')
		if separator > len(prefix) && strings.has_prefix(entry, prefix) {
			saved[entry[len(prefix):separator]] = entry[separator + 1:]
		}
	}
	env := make([dynamic]string, context.temp_allocator)
	for entry in source {
		separator := strings.index_byte(entry, '=')
		if separator < 0 {continue}
		key := entry[:separator]
		if key == "WN_APPIMAGE_ENV_SAVED" || strings.has_prefix(key, prefix) {continue}
		if _, restore := saved[key]; restore {continue}
		append(&env, entry)
	}
	for key, value in saved {
		if len(value) > 0 && value[0] == '1' {
			append(&env, fmt.tprintf("%s=%s", key, value[1:]))
		}
	}
	return env[:], nil
}
