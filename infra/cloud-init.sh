#!/bin/bash
# DigitalOcean user-data for a fresh Ubuntu 24.04 droplet. the provisioner appends this repo as
# a base64 tarball (REPO_TARBALL) and sets DOMAIN. Secrets are generated HERE, on the droplet,
# so they never leave it: read them with `cat /opt/openmaic-classroom/{.env,openmaic.env}`.
set -euo pipefail  # no -x: it would log the generated secrets
exec > >(tee -a /var/log/openmaic-bootstrap.log) 2>&1

# Swap: the first Docker build of the Next.js monorepo peaks above 4 GB.
if [[ ! -f /swapfile ]]; then
  fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

command -v docker || curl -fsSL https://get.docker.com | sh

mkdir -p /opt && cd /opt
echo "$REPO_TARBALL" | base64 -d | tar -xz
cd /opt/openmaic-classroom

if [[ ! -f .env ]]; then
  cp .env.example .env
  sed -i "s|^DOMAIN=.*|DOMAIN=$DOMAIN|" .env
  sed -i "s|^PERSISTENCE_POSTGRES_PASSWORD=.*|PERSISTENCE_POSTGRES_PASSWORD=$(openssl rand -hex 24)|" .env
fi
if [[ ! -f openmaic.env ]]; then
  cp openmaic.env.example openmaic.env
  sed -i "s|^ACCESS_CODE=.*|ACCESS_CODE=$(openssl rand -hex 10)|" openmaic.env
fi
chmod 600 .env openmaic.env

./scripts/bootstrap.sh

echo '15 3 * * * root cd /opt/openmaic-classroom && ./scripts/backup.sh >> /var/log/openmaic-backup.log 2>&1' > /etc/cron.d/openmaic-backup
echo "BOOTSTRAP DONE" > /var/log/openmaic-bootstrap.done
