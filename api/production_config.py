"""Fail-closed production configuration contract.

This module validates configuration for the future production service. It does
not connect to any provider and deliberately does not read secret values beyond
checking that required variables are present.
"""
from dataclasses import dataclass
from os import environ
from urllib.parse import urlparse


REQUIRED = (
    "ONKOFIZJO_OIDC_ISSUER_URL",
    "ONKOFIZJO_OIDC_AUDIENCE",
    "ONKOFIZJO_DATABASE_URL",
    "ONKOFIZJO_STORAGE_ENDPOINT",
    "ONKOFIZJO_STORAGE_BUCKET",
    "ONKOFIZJO_BACKUP_POLICY_ID",
    "ONKOFIZJO_AUDIT_SINK_URL",
    "ONKOFIZJO_RODO_POLICY_VERSION",
    "ONKOFIZJO_RETENTION_POLICY_VERSION",
    "ONKOFIZJO_DELETION_WORKFLOW_ID",
    "ONKOFIZJO_INCIDENT_RUNBOOK_VERSION",
    "ONKOFIZJO_MFA_AAL",
)


@dataclass(frozen=True)
class ProductionConfig:
    oidc_issuer_url: str
    oidc_audience: str
    database_url: str
    storage_endpoint: str
    storage_bucket: str
    backup_policy_id: str
    audit_sink_url: str
    rodo_policy_version: str
    retention_policy_version: str
    deletion_workflow_id: str
    incident_runbook_version: str
    mfa_assurance_level: str


def _https_url(name: str, value: str, errors: list[str]) -> None:
    parsed = urlparse(value)
    if parsed.scheme != "https" or not parsed.netloc:
        errors.append(f"{name} must be an absolute HTTPS URL")


def validate_production_environment(values: dict[str, str] | None = None) -> ProductionConfig:
    source = environ if values is None else values
    errors: list[str] = []
    missing = [name for name in REQUIRED if not source.get(name)]
    if missing:
        errors.extend(f"missing {name}" for name in missing)

    if source.get("ONKOFIZJO_ENV", "development").lower() not in {"production", "prod"}:
        errors.append("ONKOFIZJO_ENV must be production")
    if source.get("ONKOFIZJO_DEMO_MODE", "false").lower() == "true":
        errors.append("ONKOFIZJO_DEMO_MODE must not be true")
    if source.get("ONKOFIZJO_SESSION_COOKIE_SECURE", "").lower() != "true":
        errors.append("ONKOFIZJO_SESSION_COOKIE_SECURE must be true")
    if source.get("ONKOFIZJO_SESSION_COOKIE_HTTPONLY", "").lower() != "true":
        errors.append("ONKOFIZJO_SESSION_COOKIE_HTTPONLY must be true")
    if source.get("ONKOFIZJO_SESSION_COOKIE_SAMESITE", "").lower() not in {"lax", "strict"}:
        errors.append("ONKOFIZJO_SESSION_COOKIE_SAMESITE must be Lax or Strict")
    if source.get("ONKOFIZJO_MFA_REQUIRED", "").lower() != "true":
        errors.append("ONKOFIZJO_MFA_REQUIRED must be true")
    if source.get("ONKOFIZJO_MFA_AAL", "") != "aal2":
        errors.append("ONKOFIZJO_MFA_AAL must be aal2")
    if source.get("ONKOFIZJO_DATABASE_SSL_MODE", "").lower() not in {"require", "verify-full"}:
        errors.append("ONKOFIZJO_DATABASE_SSL_MODE must be require or verify-full")
    if source.get("ONKOFIZJO_BACKUP_RESTORE_TESTED", "").lower() != "true":
        errors.append("ONKOFIZJO_BACKUP_RESTORE_TESTED must be true")
    if source.get("ONKOFIZJO_BACKUP_ENCRYPTION_CONFIRMED", "").lower() != "true":
        errors.append("ONKOFIZJO_BACKUP_ENCRYPTION_CONFIRMED must be true")
    if source.get("ONKOFIZJO_STORAGE_ENCRYPTION_CONFIRMED", "").lower() != "true":
        errors.append("ONKOFIZJO_STORAGE_ENCRYPTION_CONFIRMED must be true")

    for name in ("ONKOFIZJO_OIDC_ISSUER_URL", "ONKOFIZJO_STORAGE_ENDPOINT", "ONKOFIZJO_AUDIT_SINK_URL"):
        if source.get(name):
            _https_url(name, source[name], errors)

    database_url = source.get("ONKOFIZJO_DATABASE_URL", "")
    if database_url and not database_url.startswith(("postgresql://", "postgres://")):
        errors.append("ONKOFIZJO_DATABASE_URL must use PostgreSQL")

    if errors:
        raise ValueError("Production configuration rejected: " + "; ".join(errors))

    return ProductionConfig(
        oidc_issuer_url=source["ONKOFIZJO_OIDC_ISSUER_URL"],
        oidc_audience=source["ONKOFIZJO_OIDC_AUDIENCE"],
        database_url=database_url,
        storage_endpoint=source["ONKOFIZJO_STORAGE_ENDPOINT"],
        storage_bucket=source["ONKOFIZJO_STORAGE_BUCKET"],
        backup_policy_id=source["ONKOFIZJO_BACKUP_POLICY_ID"],
        audit_sink_url=source["ONKOFIZJO_AUDIT_SINK_URL"],
        rodo_policy_version=source["ONKOFIZJO_RODO_POLICY_VERSION"],
        retention_policy_version=source["ONKOFIZJO_RETENTION_POLICY_VERSION"],
        deletion_workflow_id=source["ONKOFIZJO_DELETION_WORKFLOW_ID"],
        incident_runbook_version=source["ONKOFIZJO_INCIDENT_RUNBOOK_VERSION"],
        mfa_assurance_level=source["ONKOFIZJO_MFA_AAL"],
    )
