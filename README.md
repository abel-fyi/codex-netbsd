# Codex for NetBSD

This repository is the working area for packaging OpenAI Codex CLI 0.164.0 for
NetBSD with pkgsrc. It is separate from the OpenBSD port because the build
framework, operating-system patches, dependencies, and package metadata differ.

**Status: blueprint only. This is not yet a buildable pkgsrc package.** The
first target is NetBSD/amd64. Builds and runtime checks must run on NetBSD; a
Mac can host Codex and connect to the NetBSD machine over SSH to edit and drive
the work.

## Starting point

The NetBSD pkgsrc-wip repository contains an earlier Codex package recipe for
0.91.0. Use it as a packaging reference, not as a ready-made port for 0.164.0:

- [pkgsrc-wip Codex Makefile](https://raw.githubusercontent.com/NetBSD/pkgsrc-wip/master/codex/Makefile)
- [NetBSD pkgsrc developer guide](https://www.netbsd.org/docs/pkgsrc/pkgsrc.html)
- [Codex upstream 0.164.0 source tag](https://github.com/openai/codex/tree/rust-v0.164.0)

The OpenBSD port is useful for identifying upstream patches and build
dependencies. Its OpenBSD-specific V8 changes must not be copied blindly.

## First steps on the NetBSD host

Capture the target system details using the commands in
[`docs/NETBSD-DISCOVERY.md`](docs/NETBSD-DISCOVERY.md). Then inspect the
pkgsrc-wip recipe and compare its Rust, Clang/libclang, CMake, OpenSSL, and
Cargo dependency requirements with the target's pkgsrc tree and binary
packages.

See [`docs/PORTING-PLAN.md`](docs/PORTING-PLAN.md) for the staged work and
[`docs/PACKAGE-LAYOUT.md`](docs/PACKAGE-LAYOUT.md) for the pkgsrc files this
port will need.
