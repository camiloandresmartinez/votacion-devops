# Voting App — DevOps pipeline

This is a containerized voting app (Flask, Node.js, Redis and PostgreSQL) from a
DevOps learning challenge. The application code already existed — what I built is
everything around it: the images, the deployment automation, and a CI/CD pipeline
with quality gates that block a merge when something is wrong.

## Architecture

```
Browser ──POST──▶ Vote (Flask) ──rpush──▶ Redis ──lpop──▶ Worker (Node)
                                                              │
                                                            upsert
                                                              ▼
Browser ◀──WebSocket── Result (Node) ◀──select── PostgreSQL (volume)
```

A vote is never written directly to the database. The web service pushes it to a
Redis list and answers in about a millisecond; the worker consumes the queue and
stores the vote in PostgreSQL. If the worker or the database is down, votes wait
in the queue instead of being lost.

| Service    | Stack             | Published port | Notes                          |
|------------|-------------------|----------------|--------------------------------|
| vote       | Flask + Gunicorn  | 8091           | Writes to the Redis queue      |
| result     | Node + Socket.IO  | 3001           | Live results over WebSocket    |
| worker     | Node              | —              | Consumes the queue             |
| redis      | redis:7-alpine    | —              | Ephemeral on purpose           |
| postgres   | postgres:16-alpine| —              | Named volume for the data      |

Redis and PostgreSQL are not published to the host: they are only reachable from
inside the Compose network.

## Quick start

You need Docker and Docker Compose. From the repository root:

```bash
cd roxs-voting-app
docker compose up -d --build
```

Check that the services are healthy:

```bash
docker compose ps
```

Then open the app in your browser:

- Vote: <http://localhost:8091>
- Results: <http://localhost:3001>

To stop it without losing data use `docker compose stop`.
Never use `docker compose down -v` — that deletes the volume and the votes with it.

## Project commands

Everything the project does lives in the `Makefile`, so the same commands run on
a laptop and in CI:

```bash
make ayuda              # list every target
make pruebas            # run the test stage of the vote image
make calidad            # hadolint + gitleaks + Trivy
make levantar           # build and start the stack
make respaldo           # timestamped database dump
```

## The pipeline

Two workflows run on GitHub Actions.

**Calidad** — on every pull request and on `master`:

1. **Tests** — pytest, run inside the image's `pruebas` stage.
2. **Build** — the three images.
3. **Quality gates** — hadolint (Dockerfile linting), gitleaks (leaked secrets,
   full git history) and Trivy (critical vulnerabilities with a known fix).

The stages are ordered by cost: what fails in seconds runs before what takes a
minute. `master` is a protected branch, so a pull request cannot be merged while
this check is red — and the rule applies to the repository owner too.

**Publicar** — only on `master` and on version tags. A matrix builds the three
services in parallel and pushes them to GHCR with three tags: the commit SHA
(traceability), the semver version (releases) and `latest`.

## Design decisions

**PostgreSQL uses a named volume.** The votes have to outlive the container: if
it is deleted and recreated, the data stays. Redis is ephemeral on purpose — it
is a queue, not a store.

**Containers run as an unprivileged user.** If the application is compromised,
the attacker does not get root inside the container, which limits the blast
radius.

**The runtime images contain no build tools.** The vote image is multi-stage, so
pytest lives only in the test stage; npm is removed from the Node images after
`npm ci`. This cut about 150 MB per image and removed a critical CVE that only
affected a tool nobody runs in production.

**Dependencies are installed from a lock file.** `npm ci` and pinned pip versions
mean the image built today and the image built in three months contain the same
packages.

**Configuration comes from the environment.** The same image runs locally and in
production; only the environment changes. Credentials live in a `.env` file that
is never committed, and `.env.example` documents which variables are needed.

**Health checks, not process checks.** `depends_on` waits for `service_healthy`,
not for "started", so a service never boots against a database that is not
accepting connections yet.

## What's missing

- **Continuous Deployment.** The pipeline builds and publishes the images, but
  nothing deploys them to a server yet. The next step is an Ansible playbook that
  pulls the published image and restarts the stack.
- **Unit tests for the worker and result services.** Only the vote service has
  real tests today.
- **A quality gate for generated files**, so database dumps and build artifacts
  cannot be committed by mistake.

## Credits

The application code comes from [roxs-devops-project90](https://github.com/roxsross/roxs-devops-project90)
by [roxsross](https://github.com/roxsross), which is itself based on the
[Docker Example Voting App](https://github.com/dockersamples/example-voting-app).
Licensed under MIT — see `LICENCE`.

The infrastructure, container images, Makefile, workflows and documentation in
this fork are mine.
