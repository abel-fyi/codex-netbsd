// This focused target avoids compiling the full app-server integration suite
// on memory-constrained NetBSD hosts while running the upstream Code Mode test.
#[path = "suite/v2/code_mode_host.rs"]
mod code_mode_host;
