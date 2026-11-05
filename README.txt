CODEX

Codex 0.166.0 for NetBSD 11/amd64.
A terminal coding agent from OpenAI.
Includes the CLI and V8 Code Mode host.


BUILD

  sh porting/build-netbsd.sh

Builds the CLI, Code Mode host, and logs helper. It also
stages and verifies them under .work/. The first build
can take hours and needs substantial disk space and swap.
See docs/BUILD-NETBSD.txt before building.


INSTALL

pkgsrc/devel/codex/ is the package recipe. Copy it into a
complete pkgsrc tree, then run bmake install in that folder.
The pkgsrc install has not been tested on this machine.


FILES

  pkgsrc/devel/codex/   NetBSD package and patches
  porting/              Build, stage, and verification scripts
  docs/                 Build requirements
  .work/                Cached source, objects, logs, and staging

Keep .work/ to reuse downloads and build files.
