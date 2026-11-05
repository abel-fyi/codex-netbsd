#!/bin/sh
set -u

REPO=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
WRKSRC="${REPO}/.work/upstream-codex/codex-rs"
TARGET="${WRKSRC}/target/release"
STAGE=${STAGE:-${REPO}/.work/stage}
CLI="${STAGE}/usr/pkg/bin/codex"
HOST="${STAGE}/usr/pkg/bin/codex-code-mode-host"
LOGS_CLIENT="${STAGE}/usr/pkg/bin/codex-logs-client"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
LOGDIR="${REPO}/.work/verification-${STAMP}"
mkdir "${LOGDIR}"
STATUS=${STATUS:-${LOGDIR}/netbsd-verification.exit}
[ ! -e "${STATUS}" ] || { echo "refusing to overwrite ${STATUS}" >&2; exit 1; }

ulimit -d 8388608
export PATH="/usr/pkg/bin:/usr/bin:/bin"
export CARGO_HOME="${REPO}/.work/cargo-home"
export CARGO_BUILD_JOBS=4
export CARGO_NET_OFFLINE=true
export V8_FROM_SOURCE=1
export GN="${REPO}/.work/gn-src/out/gn"
export NINJA=/usr/pkg/bin/ninja
export PYTHON=/usr/pkg/bin/python3.13
export CLANG_BASE_PATH=/usr/pkg
export LIBCLANG_PATH=/usr/pkg/lib
export LD_LIBRARY_PATH="/usr/pkg/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export GN_ARGS='clang_use_chrome_plugins=false fatal_linker_warnings=false is_clang=true use_lld=false use_custom_libcxx=true use_custom_libunwind=true use_libcxx_modules=false use_sysroot=false use_glib=false rust_sysroot_absolute="/usr/pkg" enable_rust=false enable_rust_cxx=false enable_pkeys=false icu_use_data_file=true v8_enable_temporal_support=false v8_enable_cet_ibt=true extra_cppflags="-D_NETBSD_SOURCE -idirafter /usr/pkg/include -idirafter /usr/X11R7/include" extra_ldflags="-Wno-error=unused-command-line-argument -L/usr/pkg/lib -L/usr/X11R7/lib"'

cd "${WRKSRC}"

fail() {
  result=$1
  shift
  echo "FAIL: $* (exit ${result})"
  echo "${result}" > "${STATUS}"
  exit "${result}"
}

run() {
  label=$1
  shift
  echo
  echo "===== ${label} ====="
  if "$@"; then
    echo "PASS: ${label}"
  else
    result=$?
    fail "${result}" "${label}"
  fi
}

run_test() {
  label=$1
  output=$2
  shift 2
  echo
  echo "===== ${label} ====="
  if "$@" > "${output}" 2>&1; then
    cat "${output}"
    if grep -q '[1-9][0-9]* passed' "${output}"; then
      echo "PASS: ${label}"
    else
      fail 1 "${label} ran zero tests"
    fi
  else
    result=$?
    cat "${output}"
    fail "${result}" "${label}"
  fi
}

run_direct_integration_test() {
  label=$1
  package=$2
  test_target=$3
  filter=$4
  output=$5
  shift 5
  build_output="${LOGDIR}/${test_target}-build.log"

  echo
  echo "===== ${label}: compile test harness ====="
  if [ "${package}" = "codex-app-server" ]; then
    test_cases="${WRKSRC}/app-server/tests/netbsd_code_mode_host_cases.rs"
    test_home_root="${LOGDIR}/code-mode-codex-home"
    mkdir -p "${test_home_root}"
    cp "${REPO}/porting/netbsd-app-server-code-mode-test.rs" \
      "${WRKSRC}/app-server/tests/netbsd_code_mode_host.rs" || fail 1 "prepare focused Code Mode integration test"
    sed 's@let codex_home = TempDir::new()?;@let codex_home = TempDir::new_in(std::env::var("CODEX_NETBSD_TEST_TEMP")?)?;@g' \
      "${WRKSRC}/app-server/tests/suite/v2/code_mode_host.rs" > "${test_cases}" || fail 1 "prepare NetBSD-safe Code Mode test home"
    trap 'rm -f "${WRKSRC}/app-server/tests/netbsd_code_mode_host.rs" "${WRKSRC}/app-server/tests/netbsd_code_mode_host_cases.rs"' EXIT HUP INT TERM
    # Compile the focused integration harness in Cargo's debug profile. At
    # runtime its shim invokes the staged `codex app-server --stdio` command.
    if ! /usr/pkg/bin/cargo test -p "${package}" --test "${test_target}" --no-run > "${build_output}" 2>&1; then
      cat "${build_output}"
      fail 1 "compile ${test_target} test harness"
    fi
    rm -f "${WRKSRC}/app-server/tests/netbsd_code_mode_host.rs"
    trap - EXIT HUP INT TERM
  elif ! /usr/pkg/bin/cargo test --release -p "${package}" --test "${test_target}" --no-run > "${build_output}" 2>&1; then
    cat "${build_output}"
    fail 1 "compile ${test_target} test harness"
  fi
  test_bin=$(sed -n 's/^  Executable .* (\(.*\))$/\1/p' "${build_output}" | tail -1)
  case "${test_bin}" in
    /*) ;;
    *) test_bin="${WRKSRC}/${test_bin}" ;;
  esac
  [ -x "${test_bin}" ] || fail 1 "missing ${test_target} test harness"

  # Cargo may relink the host while compiling an integration-test target.
  # Restore its runtime path and JIT permission after compilation, immediately before exec.
  if [ -x /usr/pkg/bin/patchelf ]; then
    /usr/pkg/bin/patchelf --force-rpath --set-rpath /usr/pkg/lib "${HOST}" || fail 1 "could not set pkgsrc runtime path on ${HOST}"
  else
    echo "NOTICE: patchelf unavailable; verification uses LD_LIBRARY_PATH"
  fi
  if ! doas /usr/sbin/paxctl +m "${HOST}"; then
    fail 1 "could not enable JIT memory for ${HOST}"
  fi

  echo
  echo "===== ${label} ====="
  if [ "${package}" = "codex-app-server" ]; then
    if env "CARGO_BIN_EXE_codex-code-mode-host=${HOST}" \
      "CARGO_BIN_EXE_codex-app-server=${REPO}/porting/netbsd-codex-app-server-shim.sh" \
      "CODEX_NETBSD_CLI=${CLI}" \
      "CODEX_NETBSD_TEST_TEMP=${test_home_root}" \
      "${test_bin}" "${filter}" "$@" > "${output}" 2>&1; then
      cat "${output}"
    else
      result=$?
      cat "${output}"
      fail "${result}" "${label}"
    fi
  elif env "CARGO_BIN_EXE_codex-code-mode-host=${HOST}" \
    "${test_bin}" "${filter}" "$@" > "${output}" 2>&1; then
    cat "${output}"
  else
    result=$?
    cat "${output}"
    fail "${result}" "${label}"
  fi
  if grep -q '[1-9][0-9]* passed' "${output}"; then
    echo "PASS: ${label}"
  else
    fail 1 "${label} ran zero tests"
  fi
}

[ -x "${CLI}" ] || fail 1 "missing staged CLI ${CLI}; run stage-netbsd-install.sh first"
[ -x "${HOST}" ] || fail 1 "missing staged Code Mode host ${HOST}; run stage-netbsd-install.sh first"
[ -x "${LOGS_CLIENT}" ] || fail 1 "missing staged logs helper ${LOGS_CLIENT}; run stage-netbsd-install.sh first"
if ! doas /usr/sbin/paxctl +m "${HOST}"; then
  fail 1 "could not enable JIT memory for ${HOST}"
fi

echo "===== codex --version ====="
if env -u LD_LIBRARY_PATH "${CLI}" --version > "${LOGDIR}/codex-version.txt" 2>&1; then
  cat "${LOGDIR}/codex-version.txt"
  grep -q "0.166.0" "${LOGDIR}/codex-version.txt" || fail 1 "unexpected CLI version"
else
  result=$?
  cat "${LOGDIR}/codex-version.txt"
  fail "${result}" "codex --version"
fi

run "codex --help (without LD_LIBRARY_PATH)" env -u LD_LIBRARY_PATH "${CLI}" --help
run "codex app-server startup command" env -u LD_LIBRARY_PATH "${CLI}" app-server --help
run "dynamic dependencies: codex RPATH" env -u LD_LIBRARY_PATH ldd "${CLI}"
run "dynamic dependencies: Code Mode host RPATH" env -u LD_LIBRARY_PATH ldd "${HOST}"
run "dynamic dependencies: logs helper RPATH" env -u LD_LIBRARY_PATH ldd "${LOGS_CLIENT}"

run_test "InstallContext chooses the sibling code-mode host" \
  "${LOGDIR}/install-context-test.log" \
  /usr/pkg/bin/cargo test --release -p codex-install-context \
  code_mode_host_program_is_next_to_the_executable

run_direct_integration_test "host process executes V8 JavaScript and handles yielded cells" \
  codex-code-mode-host stdio \
  interrupt_yields_observations_without_stopping_the_cell \
  "${LOGDIR}/code-mode-host-stdio-test.log" --exact

run_direct_integration_test "Codex app-server launches local host for Code Mode JavaScript" \
  codex-app-server netbsd_code_mode_host exec_stdio_host_only \
  "${LOGDIR}/app-server-code-mode-test.log" --nocapture

echo 0 > "${STATUS}"
echo "All NetBSD Codex verification steps passed."
