#!/bin/sh
set -eu

REPO=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
WORK=${REPO}/.work
UPSTREAM=${WORK}/upstream-codex
WRKSRC=${UPSTREAM}/codex-rs
CARGO_HOME=${WORK}/cargo-home
LOGDIR=${WORK}/logs
PREPARED=${WORK}/netbsd-codex-0.166.0.prepared

mkdir -p "${LOGDIR}"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
LOG=${LOG:-${LOGDIR}/prepare-netbsd-0.166.0-${STAMP}.log}
if [ -e "${LOG}" ]; then
  echo "Refusing to overwrite existing log ${LOG}" >&2
  exit 1
fi
exec >"${LOG}" 2>&1

if [ -f "${PREPARED}" ]; then
  actual=$(git -C "${UPSTREAM}" rev-parse HEAD)
  recorded=$(cat "${PREPARED}")
  [ "${actual}" = "6ff1e1ca3b30fc8b914720681fcf5fe62e95f856" ] && \
    [ "${recorded}" = "${actual}" ] || {
      echo "prepared-source marker does not match the current upstream checkout" >&2
      exit 1
    }
  echo "NetBSD 0.166.0 source is already prepared: ${UPSTREAM}"
  exit 0
fi
if [ -e "${UPSTREAM}" ]; then
  echo "Refusing to overwrite existing upstream source ${UPSTREAM}. Inspect or preserve it first." >&2
  exit 1
fi

mkdir -p "${WORK}"
export PATH="/usr/pkg/bin:/usr/bin:/bin"
export CARGO_HOME

git clone --depth=1 --branch rust-v0.166.0 \
  https://github.com/openai/codex.git "${UPSTREAM}"
actual=$(git -C "${UPSTREAM}" rev-parse HEAD)
expected=6ff1e1ca3b30fc8b914720681fcf5fe62e95f856
[ "${actual}" = "${expected}" ] || {
  echo "unexpected upstream commit: ${actual}" >&2
  exit 1
}

# Fetch the upstream lockfile before replacing pinned Git dependencies with the
# local sibling paths used by pkgsrc.
cd "${WRKSRC}"
/usr/pkg/bin/cargo fetch

checkout_for() {
  short=$1
  found=$(find "${CARGO_HOME}/git/checkouts" -mindepth 2 -maxdepth 2 \
    -type d -name "${short}" -print)
  set -- ${found}
  [ "$#" -eq 1 ] || {
    echo "expected one Cargo checkout for ${short}; found $#" >&2
    exit 1
  }
  printf '%s\n' "$1"
}

link_checkout() {
  dirname=$1
  short=$2
  path=$(checkout_for "${short}")
  target=${UPSTREAM}/${dirname}
  [ ! -e "${target}" ] || {
    echo "refusing to replace existing dependency source ${target}" >&2
    exit 1
  }
  ln -s "${path}" "${target}"
}

link_checkout mxc-b21120168d70befe12356411423266bfef168446 b211201
link_checkout rust-sdk-98a54789b80110ad210495c4ad845c89e1980471 98a5478
link_checkout rules_rust-b56cbaa8465e74127f1ea216f813cd377295ad81 b56cbaa
link_checkout h3-e07e69412876f7e26f026bd75a48b2704d8c8283 e07e694

patch -t -N -p1 -d "${WRKSRC}" \
  < "${REPO}/pkgsrc/devel/codex/patches/patch-Cargo.toml"
patch -t -N -p1 -d "${WRKSRC}" \
  < "${REPO}/pkgsrc/devel/codex/patches/patch-tcp-tunnel_Cargo.toml"
patch -t -N -p1 -d "${WRKSRC}" \
  < "${REPO}/pkgsrc/devel/codex/patches/patch-features_src_lib_rs"

# Re-resolve the patched manifest. This fetches the crates.io V8 152.2.0 source
# selected by the NetBSD patch and records the sibling Git crates as path deps.
/usr/pkg/bin/cargo fetch

REGISTRY_SRC=$(find "${CARGO_HOME}/registry/src" -mindepth 1 -maxdepth 1 \
  -type d -name 'index.crates.io-*' -print | head -1)
[ -n "${REGISTRY_SRC}" ] || {
  echo "Cargo registry source directory is missing" >&2
  exit 1
}
CARGO_VENDOR_DIR=${REGISTRY_SRC} WRKSRC=${WRKSRC} PREFIX=/usr/pkg \
  WRKDIR=${WORK} sh "${REPO}/pkgsrc/devel/codex/files/apply-netbsd-patches.sh"

printf '%s\n' "${actual}" > "${PREPARED}"
echo "Prepared Codex ${actual} for NetBSD under ${UPSTREAM}"
