"""Executable checks for the production startup gate."""
from production_adapters import ProductionAdapters, ProductionIntegrationNotConfigured
from production_config import validate_production_environment
from production_startup import build_production_runtime


def valid_config() -> dict[str, str]:
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
        "ONKOFIZJO_BACKUP_ENCRYPTION_CONFIRMED": "true",
        "ONKOFIZJO_STORAGE_ENCRYPTION_CONFIRMED": "true",
        "ONKOFIZJO_AUDIT_SINK_URL": "https://audit.example.eu/onkofizjo",
        "ONKOFIZJO_RODO_POLICY_VERSION": "2026-08",
        "ONKOFIZJO_RETENTION_POLICY_VERSION": "2026-08",
        "ONKOFIZJO_DELETION_WORKFLOW_ID": "rodo-deletion-v1",
        "ONKOFIZJO_INCIDENT_RUNBOOK_VERSION": "ir-v1",
        "ONKOFIZJO_SESSION_COOKIE_SECURE": "true",
        "ONKOFIZJO_SESSION_COOKIE_HTTPONLY": "true",
        "ONKOFIZJO_SESSION_COOKIE_SAMESITE": "Lax",
        "ONKOFIZJO_MFA_REQUIRED": "true",
        "ONKOFIZJO_DEMO_MODE": "false",
    }


config = valid_config()
assert validate_production_environment(config).oidc_audience == "onkofizjo-api"

try:
    build_production_runtime(config, ProductionAdapters.unconfigured())
except ProductionIntegrationNotConfigured:
    pass
else:
    raise AssertionError("startup gate accepted unconfigured production adapters")

try:
    build_production_runtime({"ONKOFIZJO_ENV": "production"}, ProductionAdapters.unconfigured())
except ValueError as error:
    assert "missing ONKOFIZJO_OIDC_ISSUER_URL" in str(error)
else:
    raise AssertionError("startup gate accepted incomplete production configuration")


class FakeReady:
    def assert_ready(self):
        pass


class MissingReadiness:
    pass


runtime = build_production_runtime(
    config,
    ProductionAdapters(
        identity=FakeReady(),
        database=FakeReady(),
        storage=FakeReady(),
        audit_sink=FakeReady(),
    ),
)
assert runtime.config.storage_bucket == "onkofizjo-clinical"

try:
    build_production_runtime(
        config,
        ProductionAdapters(
            identity=MissingReadiness(),
            database=FakeReady(),
            storage=FakeReady(),
            audit_sink=FakeReady(),
        ),
    )
except ProductionIntegrationNotConfigured as error:
    assert "assert_ready" in str(error)
else:
    raise AssertionError("startup gate accepted an adapter without a readiness check")

print("PASS: production startup requires complete config and non-placeholder provider adapters.")
