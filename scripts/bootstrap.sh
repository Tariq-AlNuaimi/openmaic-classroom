#!/usr/bin/env bash
# Clone the pinned OpenMAIC release into ./upstream, install our config, build and start.
# Safe to re-run: existing data volumes are kept.
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -f .env ]] || { echo "missing .env (cp .env.example .env)"; exit 1; }
[[ -f openmaic.env ]] || { echo "missing openmaic.env (cp openmaic.env.example openmaic.env)"; exit 1; }
set -a; source .env; set +a

require() { grep -Eq "^$1=.+" "$2" || { echo "refusing to start: $1 is empty in $2"; exit 1; }; }
require ACCESS_CODE openmaic.env
require OPENROUTER_API_KEY openmaic.env
[[ -n "${PERSISTENCE_POSTGRES_PASSWORD:-}" ]] || { echo "refusing to start: PERSISTENCE_POSTGRES_PASSWORD is empty"; exit 1; }
[[ -n "${DOMAIN:-}" ]] || { echo "refusing to start: DOMAIN is empty"; exit 1; }

if [[ ! -d upstream/.git ]]; then
  git clone --depth 1 --branch "$OPENMAIC_VERSION" https://github.com/THU-MAIC/OpenMAIC.git upstream
else
  git -C upstream fetch --depth 1 origin "refs/tags/$OPENMAIC_VERSION:refs/tags/$OPENMAIC_VERSION"
  git -C upstream checkout -q "$OPENMAIC_VERSION"
fi

cp openmaic.env upstream/.env.local
cp docker-compose.override.yml upstream/docker-compose.override.yml
cp .env upstream/.env # compose variable interpolation (DOMAIN, Postgres password)

cd upstream
docker compose up -d --build
docker compose ps
echo "OpenMAIC $OPENMAIC_VERSION starting at https://$DOMAIN (first build takes several minutes)"
