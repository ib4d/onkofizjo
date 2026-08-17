"""Static contract checks for the production PostgreSQL migration.

This does not connect to PostgreSQL and is not a substitute for applying the
migration in a disposable staging database with RLS tests.
"""
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SCHEMA = (ROOT / "001_initial_production.sql").read_text(encoding="utf-8")

REQUIRED_TABLES = (
    "ecosystems", "locations", "app_users", "patients", "patient_access",
    "patient_ecosystems", "user_ecosystems", "user_locations", "patient_consents", "appointments", "clinical_notes", "diet_plans",
    "diet_plan_versions", "documents", "teleconsultations", "payments",
    "knowledge_items", "assistant_runs", "audit_events",
)
REQUIRED_POLICIES = (
    "patients_select", "app_users_self_or_gosia", "ecosystems_read", "locations_read",
    "appointments_access", "clinical_notes_access",
    "diet_plans_access", "documents_access", "teleconsultations_access",
    "payments_access", "assistant_runs_access", "knowledge_items_read", "audit_events_insert",
)


def require(text: str, label: str) -> None:
    if text not in SCHEMA:
        raise AssertionError(f"missing {label}: {text}")


for table in REQUIRED_TABLES:
    require(f"CREATE TABLE {table} (", f"table {table}")

for policy in REQUIRED_POLICIES:
    require(f"CREATE POLICY {policy} ", f"policy {policy}")

for table in (
    "ecosystems", "locations", "patients", "app_users", "user_ecosystems", "user_locations", "patient_access", "patient_consents", "appointments",
    "clinical_notes", "diet_plans", "diet_plan_versions", "documents",
    "teleconsultations", "payments", "knowledge_items", "assistant_runs", "audit_events",
):
    require(f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY", f"RLS for {table}")

for trigger in (
    "audit_events_hash_before_insert",
    "audit_events_no_update",
    "audit_events_no_delete",
    "clinical_notes_patient_match",
):
    require(f"CREATE TRIGGER {trigger}", f"trigger {trigger}")

require("CREATE EXTENSION IF NOT EXISTS pgcrypto", "hashing extension")
require("SECURITY DEFINER", "security-definer access functions")
require("SELECT onkofizjo.current_role_code() = 'GOSIA'", "schema-qualified Gosia role lookup")
require("ON CONFLICT (code) DO NOTHING", "reference-data idempotency")
for function in ("validate_note_appointment_patient", "current_subject", "clinical_mfa_satisfied", "prevent_audit_mutation"):
    function_token = f"FUNCTION onkofizjo.{function}()" if function == "clinical_mfa_satisfied" else f"FUNCTION {function}()"
    require(function_token, f"function {function}")
    if function == "current_subject":
        require("SET search_path = pg_catalog", f"fixed search path for {function}")
    else:
        require("SET search_path = onkofizjo, pg_catalog", f"fixed search path for {function}")
for index in ("appointments_created_by_idx", "clinical_notes_author_idx", "patient_access_user_idx"):
    require(f"CREATE INDEX {index}", f"foreign-key index {index}")
require("BEGIN;", "transaction start")
require("COMMIT;", "transaction commit")

for forbidden in ("demo-", "synthetic", "CHECK (appointment_id IS NULL OR"):
    if forbidden.casefold() in SCHEMA.casefold():
        raise AssertionError(f"forbidden production-schema token found: {forbidden}")

if " FOR ALL " in SCHEMA or " FOR DELETE " in SCHEMA:
    raise AssertionError("production RLS contract must not grant broad or physical-delete policies")

print(f"PASS: production schema contract ({len(REQUIRED_TABLES)} tables, RLS and append-only audit checks).")
