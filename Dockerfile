# ============================================================
# Stage 1 — Builder
# Install Python dependencies into an isolated virtual env.
# Build tools (pip, wheel, setuptools) stay here and never
# reach the final runtime image.
# ============================================================
FROM python:3.12-slim AS builder

WORKDIR /build

# Copy requirements BEFORE app code so Docker can cache this
# layer. If requirements.txt is unchanged, the pip install step
# is skipped entirely on the next build even if main.py changed.
COPY app/requirements.txt .

RUN python -m venv /venv && \
    /venv/bin/pip install --no-cache-dir -r requirements.txt


# ============================================================
# Stage 2 — Runtime
# Start from a clean base. Copy only the venv and app code.
# Nothing from the builder stage leaks into this image.
# ============================================================
FROM python:3.12-slim AS runtime

# Passed by the CI pipeline at build time:
#   docker build \
#     --build-arg GIT_SHA=$(git rev-parse --short HEAD) \
#     --build-arg BUILT_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ) .
# Baked into the image so GET /version can return them.
ARG GIT_SHA=dev
ARG BUILT_AT=unknown

# Non-root user. Default Docker behaviour is root, which means
# a compromised container has root inside the host's kernel
# namespace. A dedicated system user limits the blast radius.
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 --ingroup appgroup --no-create-home appuser

WORKDIR /app

# Copy the virtual environment from the builder stage.
COPY --from=builder /venv /venv

# Copy only the application source. --chown ensures the files
# are owned by appuser, not root, before we switch users.
COPY --chown=appuser:appgroup app/ .

ENV PATH="/venv/bin:$PATH" \
    # Baked-in image metadata exposed by GET /version
    VERSION=${GIT_SHA} \
    BUILT_AT=${BUILT_AT} \
    # Default DB path — overridden by Helm to /data/guestbook.db
    # which is where the EBS-backed PVC is mounted in Kubernetes.
    DB_PATH=/data/guestbook.db \
    # Disable Python stdout buffering so logs appear immediately
    # in `kubectl logs` and CloudWatch.
    PYTHONUNBUFFERED=1 \
    # Do not write .pyc bytecode files — unnecessary in a container.
    PYTHONDONTWRITEBYTECODE=1

USER appuser

EXPOSE 8080

# Gunicorn is the production WSGI server.
# Flask's built-in server is single-threaded and warns against
# production use. Gunicorn runs multiple worker processes.
#
# --access-logfile - : send HTTP access logs to stdout
# --error-logfile  - : send error logs to stdout
# main:app           : the Flask object named 'app' in main.py
#
# Note: Kubernetes liveness/readiness probes are defined in the
# Helm chart, not here. The HEALTHCHECK Dockerfile instruction
# is for standalone Docker use only and is ignored by Kubernetes.
CMD ["/venv/bin/gunicorn", \
     "--workers", "2", \
     "--bind", "0.0.0.0:8080", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "main:app"]
