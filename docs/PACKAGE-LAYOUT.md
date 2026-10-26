# Planned pkgsrc package layout

The package will live at `pkgsrc/devel/codex/` in this repository. This is a
development copy of the package files, not yet a checkout of the full pkgsrc
tree.

Expected package files:

- `Makefile` — upstream version, source location, dependencies, build, and
  staged installation rules.
- `DESCR` — concise package description.
- `PLIST` — files installed by the package.
- `distinfo` — source checksums and patch checksums.
- `patches/` — narrowly scoped NetBSD or pkgsrc fixes.
- `cargo-depends.mk` or the applicable pkgsrc Cargo metadata — pinned crate
  sources that are not available through the standard Cargo framework.

Do not copy the old pkgsrc-wip files as-is: its recipe targets Codex 0.91.0.
Refresh the metadata and inspect every carried patch against the 0.164.0
source tree before building.
