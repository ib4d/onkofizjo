"""Validate the checked-in production configuration template.

The template is intentionally not a runnable production configuration. This
check guarantees that onboarding cannot silently omit a required setting or
turn off a mandatory security control while still keeping credentials out of
Git.
"""
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "api"))
from production_config import REQUIRED


TEMPLATE = ROOT / "infra" / "production.env.example"
lines = TEMPLATE.read_text(encoding="utf-8").splitlines()
assignments: dict[str, str] = {}
duplicates: set[str] = set()
for line in lines:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        continue
    match = re.fullmatch(r"([A-Z0-9_]+)=(.*)", stripped)
    if not match:
        raise AssertionError(f"invalid template line: {stripped}")
    name, value = match.groups()
    if name in assignments:
        duplicates.add(name)
    assignments[name] = value

expected = {
    "ONKOFIZJO_ENV",
    "ONKOFIZJO_DEMO_MODE",
    "ONKOFIZJO_ALLOWED_ORIGINS",
    "ONKOFIZJO_DATABASE_SSL_MODE",
    "ONKOFIZJO_BACKUP_RESTORE_TESTED",
    "ONKOFIZJO_BACKUP_ENCRYPTION_CONFIRMED",
    "ONKOFIZJO_STORAGE_ENCRYPTION_CONFIRMED",
    "ONKOFIZJO_SESSION_COOKIE_SECURE",
    "ONKOFIZJO_SESSION_COOKIE_HTTPONLY",
    "ONKOFIZJO_SESSION_COOKIE_SAMESITE",
    "ONKOFIZJO_MFA_REQUIRED",
    *REQUIRED,
}
missing = expected - assignments.keys()
if missing:
    raise AssertionError(f"production template is missing: {', '.join(sorted(missing))}")
if duplicates:
    raise AssertionError(f"production template repeats: {', '.join(sorted(duplicates))}")

security_values = {
    "ONKOFIZJO_ENV": "production",
    "ONKOFIZJO_DEMO_MODE": "false",
    "ONKOFIZJO_DATABASE_SSL_MODE": "verify-full",
    "ONKOFIZJO_BACKUP_RESTORE_TESTED": "true",
    "ONKOFIZJO_BACKUP_ENCRYPTION_CONFIRMED": "true",
    "ONKOFIZJO_STORAGE_ENCRYPTION_CONFIRMED": "true",
    "ONKOFIZJO_SESSION_COOKIE_SECURE": "true",
    "ONKOFIZJO_SESSION_COOKIE_HTTPONLY": "true",
    "ONKOFIZJO_SESSION_COOKIE_SAMESITE": "Lax",
    "ONKOFIZJO_MFA_REQUIRED": "true",
    "ONKOFIZJO_MFA_AAL": "aal2",
}
for name, expected_value in security_values.items():
    if assignments[name] != expected_value:
        raise AssertionError(f"template security control changed: {name}")

if any(value.strip() == "" for value in assignments.values()):
    raise AssertionError("production template contains an empty value")
if any(re.search(r"-----BEGIN |service_role|sb_secret_|eyJ[A-Za-z0-9_-]+\.", value) for value in assignments.values()):
    raise AssertionError("production template contains a credential-like value")

print("PASS: production environment template contains all required controls and no credentials.")
