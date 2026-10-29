#!/bin/sh
set -eu

REPO=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
GN_SRC=${GN_SRC:-${REPO}/.work/gn-src}
GN_COMMIT=938087829fcbcc8fd87835ee301dd522c7637685

ulimit -d 8388608
export PATH="/usr/pkg/bin:/usr/bin:/bin"
export CC=/usr/pkg/bin/clang
export CXX=/usr/pkg/bin/clang++
export PYTHON=/usr/pkg/bin/python3.13

if [ ! -d "${GN_SRC}/.git" ]; then
  git clone https://gn.googlesource.com/gn "${GN_SRC}"
fi
if ! git -C "${GN_SRC}" cat-file -e "${GN_COMMIT}^{commit}" 2>/dev/null; then
  git -C "${GN_SRC}" fetch origin "${GN_COMMIT}"
fi
git -C "${GN_SRC}" checkout --detach "${GN_COMMIT}"
cd "${GN_SRC}"
"${PYTHON}" build/gen.py --no-last-commit-position --allow-warnings
/usr/pkg/bin/ninja -C out -j4 gn
