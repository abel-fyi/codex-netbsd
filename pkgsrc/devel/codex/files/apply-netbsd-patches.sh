#!/bin/sh
set -eu

: "${WRKSRC:?WRKSRC must point to the extracted Codex source root}"
: "${CARGO_VENDOR_DIR:?CARGO_VENDOR_DIR must point to Cargo's vendored crates}"
: "${PREFIX:?PREFIX must be set}"
: "${WRKDIR:?WRKDIR must be set}"

HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
V8=${CARGO_VENDOR_DIR}/v8-152.2.0
MXC=${WRKSRC}/mxc-b21120168d70befe12356411423266bfef168446
ICU=${CARGO_VENDOR_DIR}/deno_core_icudata-0.78.0/src/icudtl.dat

[ -d "${V8}" ] || { echo "missing rusty_v8 source: ${V8}" >&2; exit 1; }
[ -d "${MXC}" ] || { echo "missing MXC source: ${MXC}" >&2; exit 1; }
[ -f "${ICU}" ] || { echo "missing deno ICU data: ${ICU}" >&2; exit 1; }

apply_v8_patch() {
    patch -s -t -N -p0 -d "${V8}" < "$1"
}

for patchfile in "${HERE}"/v8-patches/patch-v8_*; do
    apply_v8_patch "${patchfile}"
done
for patchfile in "${HERE}"/v8-patches/patch-build_config_* \
    "${HERE}"/v8-patches/patch-build_toolchain_* \
    "${HERE}"/v8-patches/patch-third__party_* \
    "${HERE}"/v8-patches/patch-buildtools_*; do
    [ -f "${patchfile}" ] || continue
    if [ "$(basename "${patchfile}")" = patch-build_config_rust.gni ]; then
        sed "s|@PREFIX@|${PREFIX}|g" "${patchfile}" > "${WRKDIR}/patch-build_config_rust.gni"
        patch -s -t -N -p0 -d "${V8}" < "${WRKDIR}/patch-build_config_rust.gni"
    else
        apply_v8_patch "${patchfile}"
    fi
done
patch -s -t -N -p1 -d "${V8}" < "${HERE}/v8-patches/patch-v8-build-rs-netbsd"
mkdir -p "${V8}/third_party/icu/common"
cp "${ICU}" "${V8}/third_party/icu/common/icudtl.dat"

patch -s -t -N -p2 -d "${CARGO_VENDOR_DIR}/nix-0.29.0" \
    < "${HERE}/cargo-patches/patch-cargo-nix-0.29.0-netbsd-if_.rs"
patch -s -t -N -p2 -d "${MXC}" \
    < "${HERE}/cargo-patches/patch-cargo-mxc-netbsd-engine.rs"
patch -s -t -N -p1 -d "${WRKSRC}" \
    < "${HERE}/cargo-patches/patch-code-mode-protocol-system-protoc"

for dir in "${V8}" "${CARGO_VENDOR_DIR}/nix-0.29.0" "${MXC}" "${WRKSRC}/codex-rs/code-mode-protocol"; do
    find "${dir}" -name '*.orig' -type f -exec rm -f {} \;
done
