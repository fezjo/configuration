#!/usr/bin/env bash
# Install the remote-desktop client helpers on anna.
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
exec bash "$here/remote/client/install.sh"
