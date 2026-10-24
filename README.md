# openmaic-classroom

Self-hosted [OpenMAIC](https://github.com/THU-MAIC/OpenMAIC) (Tsinghua, MIT) — turn any topic or
document into an interactive AI classroom (slides, quizzes, simulations, AI teacher + classmates).

This repo is a **deploy wrapper**, not a fork: it pins an upstream release, overlays our config, and
runs it with Docker Compose behind Caddy (automatic HTTPS) on one VM. Upstream updates are a one-line
version bump instead of a merge.

```
openmaic-classroom/
├── .env.example          # secrets + pinned version  → copy to .env (never commit)
├── openmaic.env.example  # app config (OpenRouter models, access code) → copy to openmaic.env
├── caddy/Caddyfile       # HTTPS reverse proxy
├── docker-compose.override.yml  # adds Caddy, keeps app/DB off the public interface
├── scripts/bootstrap.sh  # clone pinned upstream, install config, build, start
├── scripts/upgrade.sh    # bump OPENMAIC_VERSION, rebuild, keep data
├── scripts/backup.sh     # pg_dump to ./backups
└── RUNBOOK.md            # VM setup, day-2 ops, troubleshooting
```

## Quick start (on the VM)

```bash
git clone git@github.com:Tariq-AlNuaimi/openmaic-classroom.git && cd openmaic-classroom
cp .env.example .env               # set DOMAIN, PERSISTENCE_POSTGRES_PASSWORD
cp openmaic.env.example openmaic.env  # set ACCESS_CODE (OpenRouter key: here or in Settings)
./scripts/bootstrap.sh
```

Then open `https://$DOMAIN` and enter the access code.

## Decisions

| Choice | Why |
|---|---|
| Docker Compose on a VM | OpenMAIC ≥ 1.2 needs a long-running Node host + Postgres; Vercel/serverless is unsupported upstream. |
| Pinned stable release (`v1.2.1`) | Upstream ships fast and flags breaking changes; we upgrade deliberately. |
| OpenRouter | One key, any model; swap models without a redeploy of config code. |
| `ACCESS_CODE` required | Without it the site is open to anyone and burns your OpenRouter credit. `bootstrap.sh` refuses to start without it. |
| App bound to 127.0.0.1, only Caddy on 80/443 | Postgres and the raw app are never exposed. |

See [RUNBOOK.md](RUNBOOK.md) for everything else.
