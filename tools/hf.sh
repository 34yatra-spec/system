#!/usr/bin/env bash
set -e
source /kaggle/working/tools/bootstrap.sh >/dev/null 2>&1
exec hyperframes "$@"
