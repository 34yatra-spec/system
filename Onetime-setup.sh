#!/usr/bin/env bash
# Back-compat alias. Real installer: install.sh
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$REPO/install.sh" "$@"
