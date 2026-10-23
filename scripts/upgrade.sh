#!/usr/bin/env bash
# Usage: scripts/upgrade.sh v1.3.0
# Backs up the DB, bumps OPENMAIC_VERSION in .env, rebuilds. Read upstream release notes first —
# they flag breaking changes.
set -euo pipefail
cd "$(dirname "$0")/.."
new="${1:?usage: upgrade.sh <tag>}"
[[ "$new" == *-rc* ]] && { echo "refusing release candidate $new"; exit 1; }

./scripts/backup.sh
sed -i.bak "s/^OPENMAIC_VERSION=.*/OPENMAIC_VERSION=$new/" .env && rm -f .env.bak
./scripts/bootstrap.sh
echo "Upgraded to $new. Commit the .env.example version bump if it should be the new default."
