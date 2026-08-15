"""Development-only API for onkofizjo.

This server uses synthetic records only. It is not production-ready and must be
replaced by authenticated, encrypted infrastructure before handling real health data.
"""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json
from urllib.parse import urlparse, parse_qs
import os
import sqlite3
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

ROUTES = {
    "/api/health": {"service": "onkofizjo-dev-api", "demo": True},
    "/api/patients": "demo-patients.json",
    "/api/diet-plans": "demo-diet-plan.json",
    "/api/assistant-runs": "demo-assistant-run.json",
    "/api/operations": "demo-operations.json",
    "/api/appointments": "demo-appointments.json",
    "/api/knowledge": "demo-knowledge.json",
    "/api/patient-context": "demo-clinical-profiles.json",
    "/api/notes": "demo-notes.json",
    "/api/permissions": {"demo": True, "roles": {"GOSIA": {"approve_diet": True, "edit_notes": True, "export_record": True}, "ASSISTANT": {"approve_diet": False, "edit_notes": False, "export_record": False}, "COLLABORATOR": {"approve_diet": False, "edit_notes": "ASSIGNED", "export_record": False}, "AI_AGENT": {"approve_diet": False, "edit_notes": "DRAFT", "export_record": False}}},
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

def read_notes():
    with (DATA / "demo-notes.json").open(encoding="utf-8") as file:
        return json.load(file)

def read_appointments():
    with (DATA / "demo-appointments.json").open(encoding="utf-8") as file:
        return json.load(file)

def write_appointments(document):
    with (DATA / "demo-appointments.json").open("w", encoding="utf-8") as file:
        json.dump(document, file, ensure_ascii=False, indent=2)

def known_patient(patient_id):
    document = json.loads((DATA / "demo-patients.json").read_text(encoding="utf-8"))
    return any(item.get("id") == patient_id for item in document.get("patients", []))

def appointment_for(appointment_id):
    document = read_appointments()
    return next((item for item in document.get("appointments", []) if item.get("id") == appointment_id), None)

def append_demo_note(payload):
    document = read_notes()
    now = datetime.now(timezone.utc).isoformat()
    note = {
        "id": f"demo-note-{now.replace(':', '').replace('+', '-')}",
        "patientId": payload.get("patientId"),
        "appointmentId": payload.get("appointmentId"),
        "author": payload.get("author", "Gosia"),
        "createdAt": now,
        "type": "VISIT_NOTE",
        "status": "DRAFT",
        "text": payload.get("text", ""),
        "recommendations": [],
        "humanReviewRequired": True,
    }
    document.setdefault("notes", []).append(note)
    with (DATA / "demo-notes.json").open("w", encoding="utf-8") as file:
        json.dump(document, file, ensure_ascii=False, indent=2)
    return note


class Handler(BaseHTTPRequestHandler):
    def _send(self, value, status=200):
        body = json.dumps(value, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Accept")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):  # noqa: N802
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Accept")
        self.end_headers()

    def do_GET(self):  # noqa: N802
        parsed = urlparse(self.path)
        route = parsed.path
        query = parse_qs(parsed.query)
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
        if route == "/api/patient-context" and query.get("patientId"):
            patient_id = query["patientId"][0]
            context = json.loads((DATA / "demo-clinical-profiles.json").read_text(encoding="utf-8")).get("profiles", {})
            if patient_id not in context:
                self._send({"error": "patient_context_not_found", "patientId": patient_id, "demo": True}, 404)
                return
            self._send({"demo": True, "profiles": {patient_id: context[patient_id]}})
            return
        if route == "/api/diet-plans" and query.get("patientId"):
            patient_id = query["patientId"][0]
            profiles = json.loads((DATA / "demo-clinical-profiles.json").read_text(encoding="utf-8")).get("profiles", {})
            profile = profiles.get(patient_id)
            if not profile:
                self._send({"error": "patient_context_not_found", "patientId": patient_id, "demo": True}, 404)
                return
            self._send({"demo": True, "patientId": patient_id, "status": "ASSISTANT_PROPOSED", "humanReviewRequired": True, "strategy": profile.get("tag"), "clinicalContext": {"state": profile.get("state"), "symptom": profile.get("symptom"), "detail": profile.get("detail")}, "sourcePolicy": "Synthetic demo context; verify against approved clinical sources before use."})
            return
        with (DATA / target).open(encoding="utf-8") as file:
            self._send(json.load(file))

    def do_POST(self):  # noqa: N802
        route = urlparse(self.path).path
        length = int(self.headers.get("Content-Length", "0"))
        payload = json.loads(self.rfile.read(length) or b"{}")
        if route == "/api/diet-plans":
            if payload.get("patientId") and not known_patient(payload.get("patientId")):
                self._send({"error": "patient_not_found", "patientId": payload.get("patientId"), "demo": True}, 422)
                return
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
        if route == "/api/assistant-runs":
            if not payload.get("patientId") or not payload.get("task"):
                self._send({"error": "patient_and_task_required", "demo": True}, 422)
                return
            if not known_patient(payload["patientId"]):
                self._send({"error": "patient_not_found", "patientId": payload["patientId"], "demo": True}, 422)
                return
            result = {"demo": True, "id": f"assistant-demo-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}", "patientId": payload["patientId"], "task": payload["task"], "status": "NEEDS_REVIEW", "answer": "No clinical conclusion generated. Review the linked patient context and approved sources before drafting.", "sources": payload.get("sources", []), "humanReviewRequired": True, "noInferenceWithoutEvidence": True}
            record_audit({"action": "CREATE_ASSISTANT_RUN", "resourceId": result["id"], "actor": payload.get("requestedBy", "demo-gosia")})
            self._send(result, 201)
            return
        if route == "/api/diet-plans/status":
            if payload.get("patientId") and not known_patient(payload.get("patientId")):
                self._send({"error": "patient_not_found", "patientId": payload.get("patientId"), "demo": True}, 422)
                return
            allowed = {"ASSISTANT_PROPOSED", "DRAFT", "IN_REVIEW", "APPROVED", "REJECTED"}
            status = payload.get("status")
            if status not in allowed:
                self._send({"error": "invalid_plan_status", "allowed": sorted(allowed), "demo": True}, 422)
                return
            if status == "APPROVED" and not payload.get("approvedBy"):
                self._send({"error": "human_approval_required", "demo": True}, 422)
                return
            if status == "APPROVED" and payload.get("role", "GOSIA") != "GOSIA":
                self._send({"error": "forbidden_role", "requiredRole": "GOSIA", "demo": True}, 403)
                return
            result = {"demo": True, "recorded": True, "patientId": payload.get("patientId"), "planId": payload.get("planId", "demo-plan-created"), "status": status, "humanApprovalRequired": status != "APPROVED"}
            record_audit({"action": "UPDATE_DIET_PLAN_STATUS", "resourceId": result["planId"], "status": status, "actor": payload.get("approvedBy", payload.get("actor", "unknown"))})
            self._send(result, 200)
            return
        if route == "/api/appointments":
            if not known_patient(payload.get("patientId")):
                self._send({"error": "patient_not_found", "patientId": payload.get("patientId"), "demo": True}, 422)
                return
            document = read_appointments()
            next_id = f"appt-demo-{len(document.get('appointments', [])) + 1:03d}"
            appointment = {"id": next_id, "patientId": payload.get("patientId"), "patient": payload.get("patient", ""), "ecosystem": payload.get("ecosystem", ""), "location": payload.get("location", ""), "service": payload.get("service", ""), "start": payload.get("start", ""), "end": payload.get("end", ""), "status": "SCHEDULED", "paymentStatus": "PENDING"}
            document.setdefault("appointments", []).append(appointment)
            write_appointments(document)
            record_audit({"action": "CREATE_APPOINTMENT", "resourceId": next_id, "actor": payload.get("actor", "demo-gosia")})
            self._send({"demo": True, "id": next_id, "status": "SCHEDULED", "humanConfirmationRequired": True, "appointment": appointment}, 201)
            return
        if route == "/api/appointments/status":
            allowed = {"SCHEDULED", "CONFIRMED", "TIME_BLOCKED", "CANCELLED_BY_PATIENT", "NO_SHOW", "COMPLETED", "VACATION", "BLOCKED"}
            status = payload.get("status")
            if not appointment_for(payload.get("appointmentId")):
                self._send({"error": "appointment_not_found", "appointmentId": payload.get("appointmentId"), "demo": True}, 404)
                return
            if status not in allowed:
                self._send({"error": "invalid_status", "allowed": sorted(allowed), "demo": True}, 422)
                return
            document = read_appointments()
            appointment = next((item for item in document.get("appointments", []) if item.get("id") == payload.get("appointmentId")), None)
            if appointment is None:
                self._send({"error": "appointment_not_found", "appointmentId": payload.get("appointmentId"), "demo": True}, 404)
                return
            appointment["status"] = status
            write_appointments(document)
            result = {"demo": True, "recorded": True, "appointmentId": appointment["id"], "status": status, "appointment": appointment, "auditRequired": True}
            record_audit({"action": "UPDATE_APPOINTMENT_STATUS", "resourceId": payload.get("appointmentId"), "status": status, "actor": payload.get("actor", "unknown")})
            self._send(result, 200)
            return
        if route == "/api/teleconsultations":
            if not known_patient(payload.get("patientId")):
                self._send({"error": "patient_not_found", "patientId": payload.get("patientId"), "demo": True}, 422)
                return
            if payload.get("appointmentId"):
                appointment = appointment_for(payload["appointmentId"])
                if not appointment:
                    self._send({"error": "appointment_not_found", "appointmentId": payload["appointmentId"], "demo": True}, 422)
                    return
                if appointment.get("patientId") != payload["patientId"]:
                    self._send({"error": "appointment_patient_mismatch", "demo": True}, 422)
                    return
            mode = payload.get("mode")
            if mode not in {"VIDEO", "PHONE"}:
                self._send({"error": "invalid_mode", "allowed": ["VIDEO", "PHONE"], "demo": True}, 422)
                return
            if payload.get("role", "GOSIA") == "AI_AGENT":
                self._send({"error": "forbidden_role", "requiredRole": "GOSIA or COLLABORATOR", "demo": True}, 403)
                return
            result = {"demo": True, "id": f"tele-demo-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}", "patientId": payload.get("patientId"), "appointmentId": payload.get("appointmentId"), "mode": mode, "status": "READY" if mode == "VIDEO" else "INITIATED", "consentRequired": mode == "VIDEO", "recording": False}
            record_audit({"action": "START_TELECONSULTATION", "resourceId": result["id"], "mode": mode, "actor": payload.get("actor", "demo-gosia")})
            self._send(result, 201)
            return
        if route == "/api/notes":
            if not known_patient(payload.get("patientId")):
                self._send({"error": "patient_not_found", "patientId": payload.get("patientId"), "demo": True}, 422)
                return
            if payload.get("appointmentId"):
                appointment = appointment_for(payload["appointmentId"])
                if not appointment:
                    self._send({"error": "appointment_not_found", "appointmentId": payload["appointmentId"], "demo": True}, 422)
                    return
                if appointment.get("patientId") != payload["patientId"]:
                    self._send({"error": "appointment_patient_mismatch", "demo": True}, 422)
                    return
            if payload.get("role") == "AI_AGENT" and payload.get("status", "DRAFT") != "DRAFT":
                self._send({"error": "forbidden_note_status", "allowedStatus": "DRAFT", "demo": True}, 403)
                return
            note = append_demo_note(payload)
            note["demo"] = True
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
