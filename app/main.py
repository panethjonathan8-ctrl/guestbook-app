import logging
import os
import sqlite3
from flask import Flask, jsonify, redirect, render_template, request

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Configuration from environment variables.
# All of these are set by Helm/Kubernetes in production. Defaults let the app
# run locally with no extra setup.
# ---------------------------------------------------------------------------
DB_PATH = os.environ.get("DB_PATH", "./data/guestbook.db")
ENV_NAME = os.environ.get("ENV_NAME", "local")
ENV_COLOR = os.environ.get("ENV_COLOR", "#607D8B")   # grey = local
VERSION = os.environ.get("VERSION", "dev")
POD_NAME = os.environ.get("POD_NAME", "local")
BUILT_AT = os.environ.get("BUILT_AT", "unknown")
# DB_SECRET is synced from AWS Secrets Manager by the External Secrets
# Operator.  When it is absent the footer shows "db: disconnected" so you
# can see at a glance whether ESO is working.
DB_SECRET = os.environ.get("DB_SECRET", "")


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

def init_db() -> None:
    db_dir = os.path.dirname(DB_PATH)
    if db_dir:
        os.makedirs(db_dir, exist_ok=True)
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS messages (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                name       TEXT NOT NULL,
                message    TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """
        )


def get_db_status() -> str:
    """
    Returns 'connected' only when both conditions are true:
      1. The DB_SECRET env var is present (proves ESO synced the secret).
      2. SQLite is actually reachable (proves the PVC is mounted).
    """
    if not DB_SECRET:
        return "disconnected"
    try:
        with sqlite3.connect(DB_PATH) as conn:
            conn.execute("SELECT 1")
        return "connected"
    except Exception:
        return "disconnected"


# Run once at import time so Gunicorn workers initialise the schema on startup.
try:
    init_db()
    logging.info("Database ready at %s", DB_PATH)
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
    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            "SELECT id, name, message, created_at FROM messages ORDER BY id DESC"
        ).fetchall()
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

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            "INSERT INTO messages (name, message) VALUES (?, ?)",
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

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        messages = conn.execute(
            "SELECT name, message, created_at FROM messages ORDER BY id DESC"
        ).fetchall()

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
