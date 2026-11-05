#!/bin/sh
set -eu

REPO=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PATH="/usr/pkg/bin:/usr/bin:/bin"
export PATH
WORK=${REPO}/.work
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
LOGDIR=${WORK}/logs/build-${STAMP}
STAGE=${WORK}/stage-codex-0.166.0-${STAMP}
mkdir -p "${WORK}/logs"
mkdir "${LOGDIR}"
[ ! -e "${STAGE}" ] || { echo "refusing to overwrite existing stage ${STAGE}" >&2; exit 1; }
echo "Build and verification logs: ${LOGDIR}" >&2

for tool in /usr/pkg/bin/cargo /usr/pkg/bin/clang /usr/pkg/bin/clang++ \
  /usr/pkg/bin/cmake /usr/pkg/bin/ninja /usr/pkg/bin/patchelf \
  /usr/pkg/bin/python3.13 /usr/pkg/bin/protoc /usr/pkg/bin/pkg-config \
  /usr/pkg/bin/git /usr/pkg/bin/openssl /usr/pkg/bin/sqlite3 \
  /usr/sbin/paxctl; do
  [ -x "${tool}" ] || {
    echo "missing prerequisite ${tool}; see docs/BUILD-NETBSD.txt" >&2
    exit 1
  }
done
command -v doas >/dev/null 2>&1 || {
  echo "missing prerequisite doas; see docs/BUILD-NETBSD.txt" >&2
  exit 1
}

run_step() {
  name=$1
  logfile=$2
  shift 2
  if "$@" > "${logfile}" 2>&1; then
    return 0
  else
    result=$?
  fi
  echo "${name} failed (exit ${result}); concise log tail:" >&2
  tail -40 "${logfile}" >&2
  exit "${result}"
}

run_step "source preparation" "${LOGDIR}/prepare-invocation.log" \
  env LOG="${LOGDIR}/prepare-source.log" sh "${REPO}/porting/prepare-netbsd-build.sh"
run_step "GN build" "${LOGDIR}/gn.log" "${REPO}/porting/build-gn.sh"
run_step "Codex, Code Mode host, and logs helper build" \
  "${LOGDIR}/codex.log" "${REPO}/porting/build-code-mode-host.sh"
run_step "staging" "${LOGDIR}/stage.log" \
  env STAGE="${STAGE}" sh "${REPO}/porting/stage-netbsd-install.sh"
run_step "staged CLI and Code Mode verification" "${LOGDIR}/verification.log" \
  env STAGE="${STAGE}" sh "${REPO}/porting/run-netbsd-verification.sh"

echo "Codex 0.166.0 is built and staged at ${STAGE}/usr/pkg/bin/codex"
echo "Code Mode host: ${STAGE}/usr/pkg/bin/codex-code-mode-host"
echo "Logs: ${LOGDIR}"
