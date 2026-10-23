#!/usr/bin/env bash
# Dump the OpenMAIC Postgres DB to ./backups/openmaic-<timestamp>.sql.gz (keeps last 14).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p backups
out="backups/openmaic-$(date -u +%Y%m%dT%H%M%SZ).sql.gz"
(cd upstream && docker compose exec -T postgres pg_dump -U openmaic -d openmaic) | gzip > "$out"
ls -1t backups/openmaic-*.sql.gz | tail -n +15 | xargs -r rm --
echo "wrote $out"
