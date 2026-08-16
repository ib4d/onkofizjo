"""Executable checks for the production configuration contract."""
from production_config import validate_production_environment


def valid_fixture() -> dict[str, str]:
    return {
        "ONKOFIZJO_ENV": "production",
        "ONKOFIZJO_OIDC_ISSUER_URL": "https://id.example.eu/",
        "ONKOFIZJO_OIDC_AUDIENCE": "onkofizjo-api",
        "ONKOFIZJO_DATABASE_URL": "postgresql://app@example.eu/onkofizjo",
        "ONKOFIZJO_DATABASE_SSL_MODE": "verify-full",
        "ONKOFIZJO_STORAGE_ENDPOINT": "https://storage.example.eu/",
        "ONKOFIZJO_STORAGE_BUCKET": "onkofizjo-clinical",
        "ONKOFIZJO_BACKUP_POLICY_ID": "daily-eu-30d",
        "ONKOFIZJO_BACKUP_RESTORE_TESTED": "true",
        "ONKOFIZJO_AUDIT_SINK_URL": "https://audit.example.eu/onkofizjo",
        "ONKOFIZJO_RODO_POLICY_VERSION": "2026-08",
        "ONKOFIZJO_SESSION_COOKIE_SECURE": "true",
        "ONKOFIZJO_SESSION_COOKIE_HTTPONLY": "true",
        "ONKOFIZJO_SESSION_COOKIE_SAMESITE": "Lax",
        "ONKOFIZJO_MFA_REQUIRED": "true",
        "ONKOFIZJO_DEMO_MODE": "false",
    }


valid_fixture_result = validate_production_environment(valid_fixture())
assert valid_fixture_result.database_url.startswith("postgresql://")

try:
    validate_production_environment({"ONKOFIZJO_ENV": "production"})
except ValueError as error:
    assert "missing ONKOFIZJO_OIDC_ISSUER_URL" in str(error)
else:
    raise AssertionError("incomplete production configuration was accepted")

invalid = valid_fixture()
invalid["ONKOFIZJO_DATABASE_SSL_MODE"] = "disable"
try:
    validate_production_environment(invalid)
except ValueError as error:
    assert "DATABASE_SSL_MODE" in str(error)
else:
    raise AssertionError("insecure database configuration was accepted")

print("PASS: production configuration contract rejects incomplete and insecure settings.")
