# RakshaPoorvak Database (Docker / Rancher Desktop)

PostgreSQL runs in Rancher Desktop as a Docker container. The DB is available when Rancher Desktop is running and stops when Rancher Desktop is quit.

## Prerequisites

- **Rancher Desktop** must be running (Docker runtime)

## Start database

```bash
docker compose -f docker-compose.raksha-db.yml up -d
```

## Stop database

```bash
docker compose -f docker-compose.raksha-db.yml down
```

## Connect with pgAdmin

- **Host:** localhost
- **Port:** 25432
- **Database:** rakshapoorvak_dev
- **Username:** rakshapoorvak
- **Password:** dev_password

## Verify readiness

```bash
./scripts/setup-environment.sh
```

## Backend configuration

Set `DB_PORT=25432` (or use `application-dev.yml` defaults which point to port 25432).
