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
