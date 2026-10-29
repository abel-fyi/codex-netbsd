# Porting plan

## Target

- Codex CLI 0.164.0 on NetBSD 11.0/amd64.
- Keep Code Mode with codex-code-mode-host and V8 built from source.
- Use pkgsrc binary dependencies where available; build GN from source.
- Use four Cargo/Ninja jobs and an 8 GiB build data limit, per the latest user instruction.
- Keep NetBSD fixes reproducible in this repository.

## Completed

- Recorded NetBSD environment and installed dependencies.
- Built GN and the V8 152.2.0 Code Mode host from source.
- Built Codex CLI and logs_client; set runtime RPATHs and V8 PaX permissions.
- Staged executables, completions, and documentation.
- Verified CLI version/help, dynamic libraries, sibling host discovery, V8 JavaScript, and an app-server Code Mode request using the staged host.

## Remaining

1. Validate the pkgsrc package in a complete pkgsrc checkout. The target has no /usr/pkgsrc; metadata and staged files are checked, but pkgsrc install is unverified.
2. Rebuild codex with daemon_auto_start disabled by default. The patch is applied in the working source and included in pkgsrc, but that rebuild was stopped intentionally. Until it is rebuilt, use codex --no-daemon.
3. Run final checks against the rebuilt package and update NETBSD-BUILD-STATUS.md.

## Completion criteria

The pkgsrc package builds and installs Codex 0.164.0 with its V8-backed Code Mode host; the installed CLI finds and launches the host; and a JavaScript Code Mode request succeeds. Package metadata must describe installed files and dependencies. A CLI-only build is insufficient.
