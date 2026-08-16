"""Static checks for the psql staging RLS harness.

The SQL itself must run against a real staging database to provide runtime
evidence; this script only prevents accidental removal of important cases.
"""
from pathlib import Path


sql = (Path(__file__).resolve().parent / "staging_rls_checks.sql").read_text(encoding="utf-8")
required = (
    "\\set ON_ERROR_STOP on",
    "BEGIN;",
    "ROLLBACK;",
    "current_setting('onkofizjo.test_patient_a')",
    "current_setting('onkofizjo.test_patient_b')",
    "clinical_notes",
    "teleconsultations",
    "diet_plans",
    "audit_events",
    "audit update unexpectedly succeeded",
    "audit delete unexpectedly succeeded",
    "prev_hash IS NOT NULL AND event_hash IS NOT NULL",
)
for token in required:
    if token not in sql:
        raise AssertionError(f"staging harness is missing: {token}")

if "SELECT set_config('onkofizjo.test_audit_sequence', :'audit_sequence', TRUE);" not in sql:
    raise AssertionError("psql audit sequence must be copied into a transaction-local setting")

print("PASS: staging RLS harness retains rollback, cross-patient, role and audit checks.")
