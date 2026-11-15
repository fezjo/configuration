#!/usr/bin/env bash
# Install the remote-desktop server helpers on knut.
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
exec bash "$here/remote/server/install.sh"
