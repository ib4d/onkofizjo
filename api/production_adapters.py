"""Explicit provider boundary for the future clinical production service.

The local demo does not use these adapters. Until real implementations are
registered, every operation fails closed. This prevents a production process
from silently falling back to demo data, local files or an in-memory audit log.
"""
from dataclasses import dataclass
from typing import Protocol

from identity_contract import VerifiedIdentity


class ProductionIntegrationNotConfigured(RuntimeError):
    """Raised when a real clinical provider has not been registered."""


class IdentityVerifier(Protocol):
    def assert_ready(self) -> None:
        """Verify provider configuration, key discovery and revocation access."""

    def verify(self, authorization_header: str) -> VerifiedIdentity:
        """Verify an OIDC bearer token and return the scoped identity."""


class ClinicalObjectStorage(Protocol):
    def assert_ready(self) -> None:
        """Verify private-bucket access and encryption configuration."""

    def put(self, *, patient_id: str, object_key: str, content: bytes, content_type: str) -> None:
        """Store a private, encrypted clinical object under a patient scope."""

    def create_download_url(self, *, patient_id: str, object_key: str, ttl_seconds: int) -> str:
        """Return a short-lived URL after server-side authorization."""

    def delete(self, *, patient_id: str, object_key: str, workflow_id: str) -> None:
        """Delete an object only as part of an approved lifecycle workflow."""


class ClinicalDatabase(Protocol):
    def assert_ready(self) -> None:
        """Verify TLS, credentials, schema and RLS connectivity."""

    def health_check(self) -> None:
        """Verify that the private PostgreSQL clinical store is reachable."""


class ExternalAuditSink(Protocol):
    def assert_ready(self) -> None:
        """Verify append-only audit destination and retention configuration."""

    def append(self, *, event_hash: str, payload: dict[str, object]) -> str:
        """Append an event to an external immutable audit destination."""


class ClinicalBackup(Protocol):
    def assert_ready(self) -> None:
        """Verify encrypted backup policy, retention and access controls."""

    def restore_test(self) -> dict[str, object]:
        """Run or verify an isolated restore test and return its evidence."""


class _UnconfiguredIdentityVerifier:
    def assert_ready(self) -> None:
        raise ProductionIntegrationNotConfigured(
            "No production OIDC adapter is configured; demo sessions cannot authenticate production"
        )

    def verify(self, authorization_header: str) -> VerifiedIdentity:
        raise ProductionIntegrationNotConfigured(
            "No production OIDC adapter is configured; demo sessions cannot authenticate production"
        )


class _UnconfiguredClinicalObjectStorage:
    def assert_ready(self) -> None:
        raise ProductionIntegrationNotConfigured("No encrypted clinical object storage adapter is configured")

    def put(self, *, patient_id: str, object_key: str, content: bytes, content_type: str) -> None:
        raise ProductionIntegrationNotConfigured("No encrypted clinical object storage adapter is configured")

    def create_download_url(self, *, patient_id: str, object_key: str, ttl_seconds: int) -> str:
        raise ProductionIntegrationNotConfigured("No clinical download URL adapter is configured")

    def delete(self, *, patient_id: str, object_key: str, workflow_id: str) -> None:
        raise ProductionIntegrationNotConfigured("No clinical deletion workflow adapter is configured")


class _UnconfiguredClinicalDatabase:
    def assert_ready(self) -> None:
        raise ProductionIntegrationNotConfigured(
            "No private PostgreSQL clinical database adapter is configured"
        )

    def health_check(self) -> None:
        raise ProductionIntegrationNotConfigured(
            "No private PostgreSQL clinical database adapter is configured"
        )


class _UnconfiguredExternalAuditSink:
    def assert_ready(self) -> None:
        raise ProductionIntegrationNotConfigured("No external immutable audit sink adapter is configured")

    def append(self, *, event_hash: str, payload: dict[str, object]) -> str:
        raise ProductionIntegrationNotConfigured("No external immutable audit sink adapter is configured")


class _UnconfiguredClinicalBackup:
    def assert_ready(self) -> None:
        raise ProductionIntegrationNotConfigured("No encrypted clinical backup adapter is configured")

    def restore_test(self) -> dict[str, object]:
        raise ProductionIntegrationNotConfigured("No encrypted clinical backup adapter is configured")

@dataclass(frozen=True)
class ProductionAdapters:
    """All provider boundaries required by a clinical production service."""

    identity: IdentityVerifier
    database: ClinicalDatabase
    storage: ClinicalObjectStorage
    audit_sink: ExternalAuditSink
    backup: ClinicalBackup

    @classmethod
    def unconfigured(cls) -> "ProductionAdapters":
        return cls(
            identity=_UnconfiguredIdentityVerifier(),
            database=_UnconfiguredClinicalDatabase(),
            storage=_UnconfiguredClinicalObjectStorage(),
            audit_sink=_UnconfiguredExternalAuditSink(),
            backup=_UnconfiguredClinicalBackup(),
        )

    def assert_ready(self) -> None:
        adapters = (self.identity, self.database, self.storage, self.audit_sink, self.backup)
        if any(
            isinstance(
                adapter,
                (
                    _UnconfiguredIdentityVerifier,
                    _UnconfiguredClinicalDatabase,
                    _UnconfiguredClinicalObjectStorage,
                    _UnconfiguredExternalAuditSink,
                    _UnconfiguredClinicalBackup,
                ),
            )
            for adapter in adapters
        ):
            raise ProductionIntegrationNotConfigured(
                "Production adapters are incomplete; configure OIDC, private PostgreSQL, encrypted storage, external audit sink and encrypted backups"
            )

        required_methods = {
            "OIDC": ("assert_ready", "verify"),
            "private PostgreSQL": ("assert_ready", "health_check"),
            "encrypted storage": ("assert_ready", "put", "create_download_url", "delete"),
            "external audit sink": ("assert_ready", "append"),
            "encrypted backups": ("assert_ready", "restore_test"),
        }
        for name, adapter in zip(required_methods, adapters):
            missing = [method for method in required_methods[name] if not callable(getattr(adapter, method, None))]
            if missing:
                raise ProductionIntegrationNotConfigured(
                    f"{name} adapter is missing required operations: {', '.join(missing)}"
                )
            try:
                adapter.assert_ready()
            except ProductionIntegrationNotConfigured:
                raise
            except Exception as error:
                raise ProductionIntegrationNotConfigured(
                    f"{name} adapter readiness check failed"
                ) from error
