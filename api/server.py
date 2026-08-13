"""Development-only API for onkofizjo.

This server uses synthetic records only. It is not production-ready and must be
replaced by authenticated, encrypted infrastructure before handling real health data.
"""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json
from urllib.parse import urlparse
import os

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

ROUTES = {
    "/api/health": {"service": "onkofizjo-dev-api", "demo": True},
    "/api/patients": "demo-patient.json",
    "/api/diet-plans": "demo-diet-plan.json",
    "/api/assistant-runs": "demo-assistant-run.json",
    "/api/operations": "demo-operations.json",
    "/api/appointments": "demo-appointments.json",
}


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
            self._send({
                "demo": True,
                "id": "demo-plan-created",
                "status": "ASSISTANT_PROPOSED",
                "humanApprovalRequired": True,
                "payload": payload,
            }, 201)
            return
        if route == "/api/appointments":
            self._send({"demo": True, "id": "demo-appt-created", "status": "SCHEDULED", "humanConfirmationRequired": True, "payload": payload}, 201)
            return
        if route != "/api/audit-events":
            self._send({"error": "not_found", "demo": True}, 404)
            return
        event = {"demo": True, "recorded": True, "payload": payload}
        self._send(event, 201)

    def log_message(self, *_args):
        return


if __name__ == "__main__":
    port = int(os.environ.get("ONKOFIZJO_API_PORT", "8787"))
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"onkofizjo development API listening on http://127.0.0.1:{port}")
    server.serve_forever()
