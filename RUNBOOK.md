# Runbook — openmaic-classroom

## 1. VM (one time)

- Hetzner CX22 / DigitalOcean 2 GB is enough (~$5–12/mo); 4 GB if you enable video export.
  Ubuntu 24.04. First Docker build needs ~4 GB RAM — add swap on a 2 GB box:
  `sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile`
- Docker: `curl -fsSL https://get.docker.com | sh`
- Firewall: `sudo ufw allow 22,80,443/tcp && sudo ufw enable`
- DNS: A record `classroom.<your-domain>` → VM public IP (before bootstrap, so Caddy can get a cert).

## 2. Credentials (one time)

- **OpenRouter:** https://openrouter.ai/keys → new key **with a credit limit** → add it in the app's
  **Settings → providers** (stored encrypted server-side with `OPENMAIC_SECRET_KEY`). Setting
  `OPENROUTER_API_KEY` in `openmaic.env` also works and pins it for every user.
- **ACCESS_CODE:** `openssl rand -base64 18` → `openmaic.env`. Share it only with people who should
  generate lessons on your credit.
- **Postgres password:** `openssl rand -hex 24` → `.env`.

## 3. Start

```bash
./scripts/bootstrap.sh
```

Open `https://<DOMAIN>`, enter the access code, generate a test lesson on a small topic.

## Day 2

| Task | Command |
|---|---|
| Status / logs | `cd upstream && docker compose ps` / `docker compose logs -f --tail 200 openmaic` |
| Backup (nightly cron) | `0 3 * * * cd ~/openmaic-classroom && ./scripts/backup.sh` — copy `backups/` off the box |
| Restore | `gunzip -c backups/<file> \| (cd upstream && docker compose exec -T postgres psql -U openmaic -d openmaic)` |
| Upgrade | read release notes → `./scripts/upgrade.sh v1.x.y` |
| Change models | edit `OPENROUTER_MODELS` in `openmaic.env` → `./scripts/bootstrap.sh` |
| Rotate access code | edit `ACCESS_CODE` → `./scripts/bootstrap.sh` |

## Troubleshooting

- **Server exits on start** — `DATABASE_URL` missing/wrong in upstream's defaults; check
  `docker compose logs openmaic`. Compose sets it from `PERSISTENCE_POSTGRES_PASSWORD`.
- **No models in the picker** — `OPENROUTER_API_KEY` / `OPENROUTER_MODELS` not set, or model IDs
  misspelled (copy from https://openrouter.ai/models).
- **Generation cuts off mid-lesson** — proxy timeout; Caddyfile already allows 15 min, raise it.
- **Cert not issued** — DNS not pointing at the VM yet, or ports 80/443 blocked.
- **Want MP4 export** — set `NEXT_PUBLIC_ENABLE_VIDEO_EXPORT=true` and `RENDER_SERVICE_URL` per
  upstream docs, run compose with `--profile video-export`; needs 8 GB RAM.
