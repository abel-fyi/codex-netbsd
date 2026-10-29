#!/bin/sh
set -eu

REPO=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
WRKSRC="${REPO}/.work/codex-source/codex-rust-v0.164.0/codex-rs"
TARGET="${WRKSRC}/target/release"
PREFIX=${PREFIX:-/usr/pkg}
STAGE=${STAGE:-${REPO}/.work/stage}
BINDIR="${STAGE}${PREFIX}/bin"
[ -x /usr/pkg/bin/patchelf ] || { echo "patchelf is required to stage runnable binaries" >&2; exit 1; }
export LD_LIBRARY_PATH="${PREFIX}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

for binary in codex codex-code-mode-host logs_client; do
  [ -x "${TARGET}/${binary}" ] || {
    echo "missing built binary: ${TARGET}/${binary}" >&2
    exit 1
  }
done

install -d "${BINDIR}" \
  "${STAGE}${PREFIX}/share/bash-completion/completions" \
  "${STAGE}${PREFIX}/share/fish/vendor_completions.d" \
  "${STAGE}${PREFIX}/share/zsh/site-functions" \
  "${STAGE}${PREFIX}/share/doc/codex"
install -m 755 "${TARGET}/codex" "${BINDIR}/codex"
install -m 755 "${TARGET}/codex-code-mode-host" "${BINDIR}/codex-code-mode-host"
install -m 755 "${TARGET}/logs_client" "${BINDIR}/codex-logs-client"
for binary in codex codex-code-mode-host codex-logs-client; do
  [ "$(/usr/pkg/bin/patchelf --print-rpath "${BINDIR}/${binary}")" = "${PREFIX}/lib" ] || /usr/pkg/bin/patchelf --force-rpath --set-rpath "${PREFIX}/lib" "${BINDIR}/${binary}"
done

"${BINDIR}/codex" completion bash > "${STAGE}${PREFIX}/share/bash-completion/completions/codex"
"${BINDIR}/codex" completion fish > "${STAGE}${PREFIX}/share/fish/vendor_completions.d/codex.fish"
"${BINDIR}/codex" completion zsh > "${STAGE}${PREFIX}/share/zsh/site-functions/_codex"
for doc in CLA.md agents_md.md authentication.md config.md contributing.md \
  example-config.md exec.md execpolicy.md getting-started.md install.md \
  license.md open-source-fund.md sandbox.md skills.md slash_commands.md; do
  install -m 644 "${WRKSRC}/../docs/${doc}" "${STAGE}${PREFIX}/share/doc/codex/${doc}"
done

if [ "$(id -u)" -eq 0 ]; then
  /usr/sbin/paxctl +m "${BINDIR}/codex-code-mode-host"
else
  doas /usr/sbin/paxctl +m "${BINDIR}/codex-code-mode-host"
fi

echo "Staged Codex files under ${STAGE}${PREFIX}"
