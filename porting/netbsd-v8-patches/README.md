# NetBSD patches for rusty_v8 152.2.0

The patch files in this directory were selected from pkgsrc's NetBSD Chromium 152 port and applied to rusty_v8 152.2.0 on the NetBSD build host. They add NetBSD GN/toolchain support and adapt V8, libc++, libc++abi, libunwind, and Abseil sources. The source set is in `.work/v8-152.2.0-netbsd`; the original crate archive remains in Cargo's registry cache for recovery.

`patch-build_config_rust.gni` uses pkgsrc's `@PREFIX@` placeholder. Substitute `/usr/pkg` when applying it. The upstream rusty_v8 build script also needs the small NetBSD change in `patch-v8-build-rs-netbsd`: its pinned Chromium DEPS contains no NetBSD Rust-toolchain archive, so the build uses the installed NetBSD Rust toolchain and selects bundled libunwind.

V8's source archive omits ICU's runtime data file. Before building, copy `deno_core_icudata-0.78.0/src/icudtl.dat` to `v8-152.2.0/third_party/icu/common/icudtl.dat`, as the OpenBSD port does.

The pkgsrc CCTZ `time_zone_format.cc` patch did not apply to this rusty_v8 source and is intentionally excluded. These patches have applied to a staging copy; compilation and runtime behavior still need verification.
The Chromium-root `patch-BUILD.gn` also does not apply to the rusty_v8 crate
wrapper and is excluded. The NetBSD build-config and toolchain patches that do
apply to the crate are included here.

The .gn patch disables V8 internal Rust targets and Temporal support. This mirrors the OpenBSD v8-152.2.0 patch and avoids the missing temporal_capi source omitted from the crates.io V8 source archive. The V8 JavaScript engine and Code Mode remain enabled; the Temporal JavaScript API is also disabled by the OpenBSD port.

The NetBSD clang_x64 toolchain pins cc, cxx, and ld to pkgsrc Clang 21 so its compiler flags are not sent to the base-system GCC.

The PartitionAlloc pkeys condition now excludes BSD, matching the OpenBSD port and avoiding Linux-only pkey syscalls on NetBSD.

Chromium pkgsrc classifies the BSD hosts as is_linux for shared build
conditions. libc++abi uses a separate guard that must exclude is_bsd before
defining _LIBCXXABI_USE_FUTEX; NetBSD does not provide that Linux futex API.
PartitionAlloc pkeys are explicitly disabled because NetBSD does not provide
the Linux pkey syscalls. The V8 build script passes enable_pkeys=false, and
the pkgsrc patches preserve the same default for package builds.

NetBSD pkgsrc Clang does not provide LLD here, so the host build sets
use_lld=false and uses the system linker. The V8 linker driver also receives
-Wno-error=unused-command-line-argument because Clang reports
--unwindlib=none as unused with this system linker; the flag is only in link
arguments, so it does not weaken C++ compilation warnings.

The allocator shim follows NetBSD libc declarations: its C++ declarations omit
the glibc-style exception specification on NetBSD, and malloc_usable_size uses
const void*. The POSIX stack-bound fallback skips a BSD-only DCHECK whose
helper is not built on BSD.

The NetBSD external-reference encoder patch also adds a fallback scan of V8's authoritative reference table when its address map misses a table entry. On NetBSD, `mksnapshot` rejected `base::ieee754::exp` during the startup reference-table consistency pass even though the function is in the reference list; the fallback allowed snapshot generation to complete.

The NetBSD external-reference encoder patch also adds a fallback scan of V8's authoritative reference table when its address map misses a table entry. On NetBSD, `mksnapshot` rejected `base::ieee754::exp` during the startup reference-table consistency pass even though the function is in the reference list; the fallback allowed snapshot generation to complete.
