import contextlib
import logging
import os

import psycopg2
import psycopg2.extras
from flask import Flask, jsonify, redirect, render_template, request

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Configuration from environment variables.
# All of these are set by Helm/Kubernetes in production. Defaults let the app
# start cleanly with no extra setup (DATABASE_URL being empty means the app
# starts but reports db: disconnected until ESO syncs the secret).
# ---------------------------------------------------------------------------
DATABASE_URL = os.environ.get("DATABASE_URL", "")
ENV_NAME = os.environ.get("ENV_NAME", "local")
ENV_COLOR = os.environ.get("ENV_COLOR", "#607D8B")   # grey = local
VERSION = os.environ.get("VERSION", "dev")
POD_NAME = os.environ.get("POD_NAME", "local")
BUILT_AT = os.environ.get("BUILT_AT", "unknown")


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

@contextlib.contextmanager
def get_db():
    """Open a PostgreSQL connection, commit on success, rollback on error."""
    conn = psycopg2.connect(DATABASE_URL)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def init_db() -> None:
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS messages (
                    id         SERIAL PRIMARY KEY,
                    name       TEXT NOT NULL,
                    message    TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )


def get_db_status() -> str:
    """
    Returns 'connected' only when both conditions are true:
      1. DATABASE_URL is set (proves ESO synced the secret from Secrets Manager).
      2. PostgreSQL is actually reachable (proves RDS is up and network is open).
    """
    if not DATABASE_URL:
        return "disconnected"
    try:
        with get_db() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
        return "connected"
    except Exception:
        return "disconnected"


# Run once at import time so Gunicorn workers initialise the schema on startup.
try:
    init_db()
    logging.info("Database ready")
except Exception as exc:
    logging.warning("Database init deferred — will retry on first request: %s", exc)


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.get("/health")
def health():
    """Liveness and readiness probe target. Always returns 200."""
    return jsonify({"status": "ok"})


@app.get("/version")
def version():
    """Returns the image metadata baked in at Docker build time."""
    return jsonify({"git_sha": VERSION, "built_at": BUILT_AT})


@app.get("/messages")
def get_messages():
    """JSON list of all messages, newest first."""
    with get_db() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                "SELECT id, name, message, created_at FROM messages ORDER BY id DESC"
            )
            rows = cur.fetchall()
    return jsonify([dict(r) for r in rows])


@app.post("/messages")
def post_message():
    """
    Accepts a message from either:
      - an HTML form  (Content-Type: application/x-www-form-urlencoded)
      - a JSON client (Content-Type: application/json)
    """
    if request.is_json:
        data = request.get_json() or {}
        name = (data.get("name") or "").strip()
        message = (data.get("message") or "").strip()
    else:
        name = (request.form.get("name") or "").strip()
        message = (request.form.get("message") or "").strip()

    if not name or not message:
        if request.is_json:
            return jsonify({"error": "name and message are required"}), 400
        return redirect("/")

    with get_db() as conn:
        with conn.cursor() as cur:
            # %s placeholders are the PostgreSQL standard (not ? like SQLite).
            cur.execute(
                "INSERT INTO messages (name, message) VALUES (%s, %s)",
                (name, message),
            )

    if request.is_json:
        return jsonify({"status": "ok"}), 201
    return redirect("/")


@app.get("/")
def index():
    """Renders the main HTML page."""
    try:
        init_db()   # no-op if table already exists; retries if startup init failed
    except Exception as exc:
        logging.error("DB init failed on request: %s", exc)

    messages = []
    try:
        with get_db() as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute(
                    "SELECT name, message, created_at FROM messages ORDER BY id DESC"
                )
                messages = cur.fetchall()
    except Exception as exc:
        logging.error("Failed to fetch messages: %s", exc)

    return render_template(
        "index.html",
        messages=messages,
        env_name=ENV_NAME.upper(),
        env_color=ENV_COLOR,
        version=VERSION,
        pod_name=POD_NAME,
        db_status=get_db_status(),
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
