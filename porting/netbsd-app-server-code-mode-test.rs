// This focused target avoids compiling the full app-server integration suite
// on memory-constrained NetBSD hosts while running the upstream Code Mode test.
#[path = "netbsd_code_mode_host_cases.rs"]
mod code_mode_host;
