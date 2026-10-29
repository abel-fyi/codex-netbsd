# NetBSD Codex build status

Target: NetBSD 11.0/amd64; Codex rust-v0.164.0.
Repository: ~/src/codex-netbsd.

## Built and staged

Release binaries are under .work/codex-source/codex-rust-v0.164.0/codex-rs/target/release:
- codex: CLI 0.164.0; existing binary predates daemon-autostart patch.
- codex-code-mode-host: rusty_v8/V8 152.2.0 built from source.
- logs_client: staged as codex-logs-client.

Staged tree: .work/stage/usr/pkg. It contains the three binaries, Bash/Fish/Zsh completions, and CLI docs. Keep codex and codex-code-mode-host in the same bin directory. OpenSSL 3 is loaded from /usr/pkg/lib via RPATH. V8 JIT requires paxctl +m on codex-code-mode-host.

## Dependencies and build settings

Pkgsrc binary tools used include Rust 1.96.1, Clang/LLVM 21, CMake, Ninja, protobuf, SQLite, OpenSSL, Python 3.13, and patchelf. GN was built from source because no pkgsrc binary was available. Cargo and Ninja use four jobs; heavy builds apply an 8 GiB data limit and Cargo offline mode.

## Verification passed

- codex --version and codex --help.
- ldd for CLI, host, and logs helper without LD_LIBRARY_PATH.
- InstallContext sibling-host discovery.
- V8 JavaScript execution and yielded-cell behavior in the host.
- App-server Code Mode JavaScript request using the staged host.

Main verification exit: .work/netbsd-verification.exit (0). Staged-host Code Mode results: .work/staged-code-mode-verification.log and .work/staged-app-server-code-mode.log.

## Remaining

The existing CLI needs --no-daemon because daemon autostart expects a complete managed package containing codex-package.json. A patch disabling daemon autostart by default is included in porting/cargo-patches and pkgsrc/devel/codex/patches. It is applied to the working source, but rebuilding the CLI with it was intentionally interrupted; .work/codex-daemon-default-build.exit contains 130. Resume with porting/build-code-mode-host.sh.

The pkgsrc recipe has not been run in a complete pkgsrc checkout because /usr/pkgsrc is absent. Distfiles, patch checksums, and staged files were checked, but pkgsrc package installation remains unverified.
