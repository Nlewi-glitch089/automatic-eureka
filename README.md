## Architecture

This project runs as two containers managed by Docker Compose:

- **app** — Node.js service (the application)
- **db** — PostgreSQL database

Both services share a Docker network so the `app` can connect to the database using the hostname `db`. Credentials and configuration are provided via environment variables.

Example Compose snippet (startup ordering):

```yaml
depends_on:
  db:
    condition: service_healthy
```

## Quick Start

Start the full stack with a single command:

```bash
docker compose up
```

Run detached:

```bash
docker compose up -d
```

View logs:

```bash
docker compose logs -f
```

Stop and remove containers:

```bash
docker compose down
```

## Stability Features

### Healthchecks

Each service includes a healthcheck so the orchestrator can tell if it is actually functional (not just running).

- **db:** `pg_isready` to verify Postgres is accepting connections.
- **app:** `wget` HTTP probe against `http://localhost:3000`.

Healthchecks enable smarter startup ordering, visible service state (`healthy` / `unhealthy`), and better automation.

### Restart Policies

Both services use a restart policy to automatically recover from crashes:

```yaml
restart: always
```

This reduces downtime and manual intervention for transient failures.

## Environment Management

Runtime configuration is loaded from environment files. The `app` uses:

```yaml
env_file:
  - .env.production
```

Important: never commit secrets. Add `.env.production` to `.gitignore` and use a secret manager in production.

## Business Value

For educational platforms (e.g., BrightPath), reliability matters: students and instructors depend on predictable availability. Healthchecks and restart policies reduce disruptions, lower operational overhead, and build trust in the platform.

## Screenshot (Both Services Healthy)

![services healthy](docs/services-healthy.png)

To reproduce locally:

```bash
docker compose up -d
docker compose ps
# Confirm both services show "healthy" in the State column
```

## Why Orchestration Matters

Orchestration (Compose, etc.) provides controlled startup order, health awareness, automatic recovery, and consistent networking — making deployments predictable and resilient.

## Troubleshooting Lab Notes

This project is used for hands-on failure and recovery drills. The following concise notes summarize common failure modes observed during the lab and how to diagnose and fix them.

- **Scenario: Wrong database port**
  - Symptom: `app` repeatedly restarts; `db` shows `healthy`.
  - Why `db` is healthy: Postgres' own healthcheck (`pg_isready`) talks to the DB process on the DB container's internal port (usually 5432) — the DB itself is fine.
  - Why `app` fails: `app` reads `DATABASE_URL` at runtime. If that URL uses the wrong port (e.g. 9999) connections fail with "connection refused" or timeout.
  - Why restart doesn't fix it: Restart policy restarts the container but re-applies the same (wrong) configuration so the failure repeats.
  - Quick commands:

```bash
docker compose down
docker compose up -d
docker compose ps
docker compose logs app
```

- **Scenario: Inspecting runtime env inside the container**
  - Fix: restore `DATABASE_URL` to correct value (port 5432) in `.env.production` and restart the stack.
  - Login and inspect:

```bash
docker compose exec app sh
env | grep DATABASE_URL
exit
```

  - Note: environment variables are injected at container start and live in the running process environment (they are runtime values, not baked into the image).

- **Scenario: Stop DB while app runs**
  - Commands:

```bash
docker ps            # find db container name
docker stop <db_name>
docker compose ps
docker compose logs app
docker start <db_name>
```

  - Explain: restart policies bring back containers after external kills; if configuration is correct the app will reconnect. Production failures differ when persistent misconfig or data corruption exists.

- **Scenario: Volume drift and data persistence**
  - `docker compose down` keeps named volumes. `docker compose down -v` removes volumes and their data.
  - Use `down -v` intentionally when you need a clean DB; otherwise stale data (old schema/rows) may mask bugs.

- **Scenario: Corrupt/missing secret (DATABASE_URL with no password)**
  - Symptom: authentication failures in logs.
  - Fix: restore the correct `DATABASE_URL` in `.env.production` and restart. Restart policy cannot fix bad credentials.

- **Scenario: Healthcheck removal**
  - Without a healthcheck Docker can report containers as `Up` while the service inside is not ready.
  - `Running` vs `Healthy`: `Running` = container process exists; `Healthy` = healthcheck probe succeeded and service is ready to serve.

- **Scenario: Image drift and dependency install**
  - If `node_modules` are removed locally and the image is rebuilt, the Dockerfile must run `npm install` during build so the image is self-contained.
  - Beware mounting the host directory in development — it can overwrite container-installed `node_modules` and break the app.

- **Scenario: Manual container kill**
  - `docker kill <app>` triggers the restart policy which will recreate the container and (if config is correct) it will reconnect successfully.
  - This demonstrates restart policies heal transient crashes, but they do not fix broken configuration.

Troubleshooting quick checklist:

- Use `docker compose ps` to inspect state and restart counters.
- Use `docker compose logs <service>` and `docker logs <container>` to read errors; look for "connection refused" vs "authentication failed".
- Use `docker compose exec <service> sh` then `env` to confirm runtime environment values.
- Use `docker compose down -v` when you explicitly want to reset named volumes (destructive).
- Restore config/secrets and then restart. Sidenote: restarts alone won't fix configuration errors.

Troubleshooting Lab Exercises — How I Broke and Fixed the System

This lab documents practical drills and remediation steps so you can reproduce and diagnose failures quickly.

- Scenario 1 — Wrong Database Port:
  - Break: edit `.env.production` change `5432` → `9999`.
  - Reproduce: `docker compose down && docker compose up -d`
  - Inspect: `docker compose ps` (see `app` restart loop), `docker compose logs app` (look for "connection refused").
  - Fix: revert port to `5432` in `.env.production` and restart.
  - Why: `db` healthcheck probes Postgres process (internal port) so `db` can be `healthy` while `app` can't connect; restart policy restarts the process but re-applies the same bad config.

- Scenario 2 — Inspecting Runtime Environment:
  - Enter: `docker compose exec app sh`
  - Inspect: `env | grep DATABASE_URL`
  - Note: env vars are injected at container start and live in the process environment — they are runtime values, not baked into the image.

- Scenario 3 — Stop DB While App Runs:
  - Commands: `docker ps` → `docker stop <db_container>` → observe `docker compose ps` and `docker compose logs app` → `docker start <db_container>`.
  - Behavior: restart policy will bring containers back; if configuration is correct, the app reconnects.

- Scenario 4 — Volume Drift:
  - Recreate without `-v`: data persists.
  - Recreate with `-v`: `docker compose down -v` removes named volumes and data.
  - Lesson: stale data can mask bugs (old schema, hidden rows). Use `-v` intentionally.

- Scenario 5 — Corrupt Environment Variable:
  - Break: remove password from `DATABASE_URL`.
  - Observe: authentication failures in `docker compose logs app`.
  - Fix: restore correct `DATABASE_URL` and restart — restart policy cannot fix bad credentials.

- Scenario 6 — Healthcheck Removed:
  - Remove app healthcheck and rebuild.
  - Observe: container may show `Up` but not `Healthy`.
  - Lesson: `Running` != `Healthy`. Keep healthchecks for readiness and routing.

- Scenario 7 — Image Drift and Missing Dependencies:
  - Delete local `node_modules` and run `docker compose up -d --build`.
  - Lesson: Dockerfile must install dependencies so image is self-contained; avoid relying on host `node_modules`.

- Scenario 8 — Manual Container Kill:
  - `docker kill <app_container>` triggers restart policy — if config is correct, service comes back and connects.
  - Lesson: restart heals crashes, not bad configs.

Demo checklist:

- Both containers show `healthy` in `docker compose ps`.
- No restart loops.
- Correct env values inside the running container.
- Understand volume persistence and optionally demonstrate `down -v`.
- Explain root cause for each failure using logs and commands shown above.

