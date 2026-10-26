# Porting plan

## Target and working rules

- Package upstream Codex CLI `rust-v0.164.0` for NetBSD/amd64 first.
- Use pkgsrc conventions and build the package on the NetBSD target.
- Use Mac-hosted Codex over SSH for editing and command orchestration; keep
  compiler output and build artifacts on NetBSD.
- Keep NetBSD sources, patches, package metadata, and Git history independent
  from the OpenBSD repository.
- Start with the existing pkgsrc-wip Codex recipe (currently version 0.91.0)
  as a reference. Recheck its files and assumptions against upstream 0.164.0.

## Milestones

### 1. Record the target environment

Record the NetBSD release, architecture, pkgsrc branch/date, installed package
tool versions, available disk space, memory, and current Rust/Clang/CMake
packages. See `NETBSD-DISCOVERY.md`. Confirm the target is amd64 before making
architecture-specific assumptions.

### 2. Audit sources and dependencies

- Compare the pkgsrc-wip package recipe with the OpenBSD 0.164.0 port.
- Enumerate vendored crates, Git-pinned crates, and unpublished crate sources.
- Identify pkgsrc build-time and runtime dependencies and their NetBSD package
  paths. Prefer matching binary packages where available.
- Refresh distfile URLs, versions, and checksums for the selected upstream tag.

### 3. Establish the Rust and V8 build

- Check the Rust version required by the locked 0.164.0 dependency graph.
- Build a small V8/rusty_v8 target on NetBSD before spending time on the full
  Codex build.
- Check upstream V8 and rusty_v8 for existing NetBSD support. Port only the
  missing NetBSD-specific behavior; OpenBSD's `pthread_stackseg_np()` patch is
  not a NetBSD solution.
- Keep each platform patch small, documented, and independently applicable.

### 4. Implement the pkgsrc package

Create the files described in `PACKAGE-LAYOUT.md`. Use pkgsrc's Cargo
framework where it fits; document any Git crate sources or Cargo overrides
that require explicit handling. Keep build and install paths under pkgsrc's
normal staging directories.

### 5. Build and package on NetBSD

Run pkgsrc phases incrementally: fetch/checksum, extract/patch, configure,
build, install staging, and package creation. Preserve a full build log on the
NetBSD host. Resolve failures in small steps and resume from pkgsrc's work
directory when safe.

### 6. Validate the resulting package

- Install the package on a clean or disposable NetBSD system of the target
  release and architecture.
- Check `codex --version`, startup, login/account bootstrap, and a basic local
  workspace interaction.
- Record installed runtime dependencies, package checksums, and any remaining
  limitations before calling the port usable.

## Completion criteria

The pkgsrc package builds on the target NetBSD release, installs cleanly,
starts successfully, reports Codex CLI 0.164.0, and has its runtime dependency
set represented in pkgsrc metadata.
