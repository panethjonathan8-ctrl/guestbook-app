# guestbook-app

A small Flask "guestbook" web app — visitors leave a name + message, stored in PostgreSQL. The app itself is intentionally simple: it exists as a realistic payload to exercise a production-grade CI/CD pipeline, not as the point of the project. Infrastructure and deployment live in a separate repo, [`guestbook-gitops`](https://github.com/panethjonathan8-ctrl/guestbook-gitops) — see [Relationship to guestbook-gitops](#relationship-to-guestbook-gitops) below.

## Endpoints

| Method/Path | Purpose |
|---|---|
| `GET /` | Renders the guestbook page — message list, env banner, pod name, db status |
| `GET /health` | Liveness/readiness probe target |
| `GET /version` | `{"git_sha": ..., "built_at": ...}` — image metadata baked in at build time |
| `GET /stats` | `{"total_messages": ...}` |
| `GET /messages` | JSON list of all messages, newest first |
| `POST /messages` | Add a message (JSON or HTML form) |

Config is entirely environment-variable driven (`DATABASE_URL`, `ENV_NAME`, `ENV_COLOR`, `VERSION`, `POD_NAME`, `BUILT_AT`) — all set by Helm/Kubernetes in every real environment, with safe local defaults so the app boots standalone.

## Running locally

```
pip install -r app/requirements.txt
python app/main.py
```

Without a `DATABASE_URL` set, the app still starts — the footer shows `db: disconnected` and message history won't persist, but `/health`, `/version`, and the page itself all work.

## CI/CD pipeline

Three GitHub Actions workflows:

- **`ci.yml`** — runs on every PR to `main`: lint (`ruff`), Dockerfile lint (`hadolint`), tests (placeholder — no real test suite exists yet), and a build-only Docker build (no push) to confirm the Dockerfile actually works.
- **`deploy.yml`** — runs on push to `main` when `app/`, `Dockerfile`, or related files changed. Builds and pushes exactly **one** image to ECR, tagged with the git short SHA, then updates `guestbook-gitops`'s `values-dev.yaml` and forces an ArgoCD sync to deploy it to the dev environment.
- **`release-please.yml`** — runs on every push to `main`. Manages semantic versioning from Conventional Commits (`feat:`/`fix:`/`infra:`). When its Release PR is merged, it **retags** (never rebuilds) the exact dev image that corresponds to the release and promotes that same image to staging, then production, with smoke tests at each stage.

The core design principle: **an image is built exactly once.** Staging and production always run the identical artifact that was already validated in dev — never a fresh rebuild — so what you tested is guaranteed to be what you shipped.

## Relationship to guestbook-gitops

This repo owns the application and its CI. It has no knowledge of Kubernetes, Helm, or AWS beyond pushing images to ECR and committing a values-file change into `guestbook-gitops` — it never runs `kubectl` or `helm upgrade` directly against a cluster. `guestbook-gitops` owns everything about how and where the app actually runs; ArgoCD there is the only thing with write access to any cluster.

## Known gaps

- No real test suite yet — `ci.yml`'s `test` job explicitly treats pytest's "no tests collected" exit code as a pass, as an honest placeholder rather than a false green.
