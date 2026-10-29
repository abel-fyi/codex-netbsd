#!/bin/sh
set -eu
ulimit -d 8388608
exec cargo "$@"
