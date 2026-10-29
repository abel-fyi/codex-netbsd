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
export V8_FROM_SOURCE=1
export GN="${REPO}/.work/gn-src/out/gn"
export NINJA=/usr/pkg/bin/ninja
export PYTHON=/usr/pkg/bin/python3.13
export CLANG_BASE_PATH=/usr/pkg
export LIBCLANG_PATH=/usr/pkg/lib
export LD_LIBRARY_PATH="/usr/pkg/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export GN_ARGS='clang_use_chrome_plugins=false fatal_linker_warnings=false is_clang=true use_lld=false use_custom_libcxx=true use_custom_libunwind=true use_libcxx_modules=false use_sysroot=false use_glib=false rust_sysroot_absolute="/usr/pkg" enable_rust=false enable_rust_cxx=false enable_pkeys=false icu_use_data_file=true v8_enable_temporal_support=false v8_enable_cet_ibt=true extra_cppflags="-D_NETBSD_SOURCE -idirafter /usr/pkg/include -idirafter /usr/X11R7/include" extra_ldflags="-Wno-error=unused-command-line-argument -L/usr/pkg/lib -L/usr/X11R7/lib"'

/usr/pkg/bin/cargo build --release \
  -p codex-cli --bin codex \
  -p codex-cli --bin logs_client \
  -p codex-code-mode-host --bin codex-code-mode-host

for binary in codex codex-code-mode-host logs_client; do
  [ "$(/usr/pkg/bin/patchelf --print-rpath "${WRKSRC}/target/release/${binary}")" = /usr/pkg/lib ] || /usr/pkg/bin/patchelf --force-rpath --set-rpath /usr/pkg/lib "${WRKSRC}/target/release/${binary}"
done

doas /usr/sbin/paxctl +m "${WRKSRC}/target/release/codex-code-mode-host"
