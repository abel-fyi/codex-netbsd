# Codex for NetBSD

This repository contains NetBSD-specific packaging work for Codex CLI 0.164.0 on NetBSD 11/amd64.

**Status:** The CLI, V8-backed Code Mode host, and logs helper are built and staged. CLI startup, sibling-host discovery, and V8 JavaScript through the app server passed. The daemon-autostart default patch is applied to source, but its CLI rebuild was intentionally interrupted; use codex --no-daemon with the current executable. The pkgsrc recipe has not been tested in a complete pkgsrc checkout.

## Build and verification

Source checkout and release binaries are under .work/codex-source/codex-rust-v0.164.0/codex-rs/target/release/.

- porting/build-code-mode-host.sh builds Codex and the V8-backed host.
- porting/build-logs-client.sh builds logs_client.
- porting/run-netbsd-verification.sh runs CLI and Code Mode checks.
- porting/stage-netbsd-install.sh stages binaries, completions, and docs under .work/stage/usr/pkg.

Keep codex and codex-code-mode-host together in the same bin directory. V8 JIT requires NetBSD PaX MPROTECT to be disabled on the host; the build and staging helpers apply paxctl +m.

See docs/NETBSD-BUILD-STATUS.md for artifact paths, runtime requirements, test results, and remaining work. NetBSD patches are in porting/ and pkgsrc/devel/codex/.
