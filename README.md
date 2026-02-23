# automatic-eureka

**Architecture**
- **Two containers:** an `app` (Node.js) service and a `db` (Postgres) service managed by Docker Compose.
- **Communication:** both services run on the same Docker network; the `app` connects to the database using the `db` hostname and credentials provided via environment variables. The `app` depends on the `db` being healthy before starting (`depends_on` with `condition: service_healthy`).

**Quick Start**
- Start everything with a single command: `docker compose up` (or run detached: `docker compose up -d`).
- View logs: `docker compose logs -f`
- Stop and remove: `docker compose down`

**Stability Features**
- **Healthchecks:** the `db` uses `pg_isready` and the `app` uses a `wget`-based HTTP probe to verify `http://localhost:3000` is responding. Healthchecks let Compose and orchestrators know when a service is operational.
- **Restart policies:** both services are configured with `restart: always` so Docker will automatically restart a failed container to minimize downtime.

**Environment Management**
- Secrets and runtime configuration are handled with environment files. The `app` loads variables from `.env.production` via the `env_file` directive in `docker-compose.yml`.
- Keep secrets out of source control: add `.env.production` to `.gitignore` and use a secret manager for production deployments.

**Business Value**
- For BrightPath (educational apps), uptime and reliability are critical to avoid disrupting learners and instructors. Healthchecks and automatic restarts reduce manual intervention, improve availability during transient failures, and make the platform more trustworthy for classrooms.

**Screenshot (both services healthy)**
![services healthy](docs/services-healthy.png)

How to reproduce the screenshot locally:
1. `docker compose up -d`
2. `docker compose ps` — verify both services have `healthy` under the `State` column
3. Take a screenshot of the terminal or the Docker Desktop view and replace `docs/services-healthy.png` with your image.

**Why orchestration matters**
- Orchestration gives you lifecycle control (start order, health checks), automatic recovery (restart policies), and consistent networking — all of which make delivery and operation of educational services predictable and resilient.
