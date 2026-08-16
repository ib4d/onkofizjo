"""Static guard against removing mandatory production runbook gates."""
from pathlib import Path


runbook = (Path(__file__).resolve().parent / "PRODUCTION_RUNBOOK.md").read_text(encoding="utf-8")
required = (
    "Preflight de identidad y autorización",
    "Preflight de datos clínicos",
    "Retención, acceso y borrado",
    "Backups y recuperación",
    "Incidentes y auditoría",
    "Gate de activación",
    "validate_verified_identity",
    "audit_events",
    "revisión independiente de seguridad",
)
for token in required:
    if token not in runbook:
        raise AssertionError(f"production runbook is missing: {token}")

print("PASS: production runbook retains identity, clinical data, lifecycle, recovery and incident gates.")
