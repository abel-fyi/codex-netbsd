#!/bin/sh
set -eu

REPO=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
WRKSRC="${REPO}/.work/codex-source/codex-rust-v0.164.0/codex-rs"
[ -x /usr/pkg/bin/patchelf ] || { echo "patchelf is required before building; install pkgsrc devel/patchelf" >&2; exit 1; }

cd "${WRKSRC}"
ulimit -d 8388608
export PATH="/usr/pkg/bin:/usr/bin:/bin"
export CARGO_BUILD_JOBS=4
export CARGO_NET_OFFLINE=true
export CARGO_PROFILE_RELEASE_LTO=off
export LD_LIBRARY_PATH="/usr/pkg/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

/usr/pkg/bin/cargo build --release -p codex-cli --bin logs_client
for binary in codex codex-code-mode-host logs_client; do
  [ "$(/usr/pkg/bin/patchelf --print-rpath "${WRKSRC}/target/release/${binary}")" = /usr/pkg/lib ] || /usr/pkg/bin/patchelf --force-rpath --set-rpath /usr/pkg/lib "${WRKSRC}/target/release/${binary}"
done
doas /usr/sbin/paxctl +m "${WRKSRC}/target/release/codex-code-mode-host"
