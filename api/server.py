"""Development-only API for onkofizjo.

This server uses synthetic records only. It is not production-ready and must be
replaced by authenticated, encrypted infrastructure before handling real health data.
"""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json
from urllib.parse import urlparse
import os
import sqlite3
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

ROUTES = {
    "/api/health": {"service": "onkofizjo-dev-api", "demo": True},
    "/api/patients": "demo-patient.json",
    "/api/diet-plans": "demo-diet-plan.json",
    "/api/assistant-runs": "demo-assistant-run.json",
    "/api/operations": "demo-operations.json",
    "/api/appointments": "demo-appointments.json",
    "/api/knowledge": "demo-knowledge.json",
    "/api/notes": "demo-notes.json",
}
AUDIT_DB = ROOT / "data" / "dev-audit.sqlite3"

def audit_db():
    conn = sqlite3.connect(AUDIT_DB)
    conn.execute("CREATE TABLE IF NOT EXISTS audit_events (id INTEGER PRIMARY KEY AUTOINCREMENT, created_at TEXT NOT NULL, payload TEXT NOT NULL)")
    return conn

def record_audit(payload):
    with audit_db() as conn:
        conn.execute("INSERT INTO audit_events(created_at, payload) VALUES (?, ?)", (datetime.now(timezone.utc).isoformat(), json.dumps(payload, ensure_ascii=False)))

def read_audits():
    with audit_db() as conn:
        rows = conn.execute("SELECT id, created_at, payload FROM audit_events ORDER BY id DESC").fetchall()
    return [{"id": row[0], "createdAt": row[1], "payload": json.loads(row[2])} for row in rows]


class Handler(BaseHTTPRequestHandler):
    def _send(self, value, status=200):
        body = json.dumps(value, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):  # noqa: N802
        route = urlparse(self.path).path
        if route == "/api/audit-events":
            self._send({"demo": True, "persistent": True, "events": read_audits()})
            return
        target = ROUTES.get(route)
        if target is None:
            self._send({"error": "not_found", "demo": True}, 404)
            return
        if isinstance(target, dict):
            self._send(target)
            return
        with (DATA / target).open(encoding="utf-8") as file:
            self._send(json.load(file))

    def do_POST(self):  # noqa: N802
        route = urlparse(self.path).path
        length = int(self.headers.get("Content-Length", "0"))
        payload = json.loads(self.rfile.read(length) or b"{}")
        if route == "/api/diet-plans":
            result = {
                "demo": True,
                "id": "demo-plan-created",
                "status": "ASSISTANT_PROPOSED",
                "humanApprovalRequired": True,
                "payload": payload,
            }
            record_audit({"action": "CREATE_DIET_PROPOSAL", "resourceId": result["id"], "actor": payload.get("requestedBy", "unknown")})
            self._send(result, 201)
            return
        if route == "/api/appointments":
            self._send({"demo": True, "id": "demo-appt-created", "status": "SCHEDULED", "humanConfirmationRequired": True, "payload": payload}, 201)
            return
        if route == "/api/appointments/status":
            allowed = {"SCHEDULED", "CONFIRMED", "TIME_BLOCKED", "CANCELLED_BY_PATIENT", "NO_SHOW", "COMPLETED", "VACATION", "BLOCKED"}
            status = payload.get("status")
            if status not in allowed:
                self._send({"error": "invalid_status", "allowed": sorted(allowed), "demo": True}, 422)
                return
            result = {"demo": True, "recorded": True, "appointmentId": payload.get("appointmentId"), "status": status, "auditRequired": True}
            record_audit({"action": "UPDATE_APPOINTMENT_STATUS", "resourceId": payload.get("appointmentId"), "status": status, "actor": payload.get("actor", "unknown")})
            self._send(result, 200)
            return
        if route == "/api/notes":
            note = {"demo": True, "id": "demo-note-created", "status": "DRAFT", "humanReviewRequired": True, "payload": payload}
            record_audit({"action": "CREATE_CLINICAL_NOTE_DRAFT", "resourceId": note["id"], "actor": payload.get("author", "unknown")})
            self._send(note, 201)
            return
        if route != "/api/audit-events":
            self._send({"error": "not_found", "demo": True}, 404)
            return
        event = {"demo": True, "recorded": True, "payload": payload}
        record_audit(payload)
        self._send(event, 201)

    def log_message(self, *_args):
        return


if __name__ == "__main__":
    port = int(os.environ.get("ONKOFIZJO_API_PORT", "8787"))
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"onkofizjo development API listening on http://127.0.0.1:{port}")
    server.serve_forever()
