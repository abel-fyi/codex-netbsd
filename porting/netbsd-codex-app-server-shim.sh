#!/bin/sh
set -eu

: "${CODEX_NETBSD_CLI:?set CODEX_NETBSD_CLI to the codex executable}"

# TestAppServer supplies a flag accepted by the dedicated app-server test
# binary. Remove it, then exercise the production `codex app-server` command.
if [ "${1-}" = --disable-plugin-startup-tasks-for-tests ]; then
  shift
fi
unset LD_LIBRARY_PATH
exec "${CODEX_NETBSD_CLI}" app-server --stdio "$@"
