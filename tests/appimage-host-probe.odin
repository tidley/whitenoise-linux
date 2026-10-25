package main

import "core:os"

// These unrelated settings/path dependencies keep this probe independent of
// the UI and Marmot. Proxy validation itself has separate app-package tests.
curl_path :: proc() -> string {return "curl"}
socks5_proxy_valid :: proc(value: string) -> bool {return false}
socks5_auth_valid :: proc(username, password: string) -> bool {return false}

// Compile beside the production host/process and HTTP worker sources.
main :: proc() {
	args := os.args[1:]
	execute := host_process_exec
	if len(args) > 0 && args[0] == "--tool" {
		args = args[1:]
		execute = tool_exec
	}
	state, out, errout, err := execute({command = args}, context.temp_allocator)
	os.write(os.stdout, out)
	os.write(os.stderr, errout)
	if err != nil {os.exit(1)}
	os.exit(state.exit_code)
}
