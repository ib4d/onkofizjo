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
    def verify(self, authorization_header: str) -> VerifiedIdentity:
        """Verify an OIDC bearer token and return the scoped identity."""


class ClinicalObjectStorage(Protocol):
    def put(self, *, patient_id: str, object_key: str, content: bytes, content_type: str) -> None:
        """Store a private, encrypted clinical object under a patient scope."""

    def create_download_url(self, *, patient_id: str, object_key: str, ttl_seconds: int) -> str:
        """Return a short-lived URL after server-side authorization."""

    def delete(self, *, patient_id: str, object_key: str, workflow_id: str) -> None:
        """Delete an object only as part of an approved lifecycle workflow."""


class ClinicalDatabase(Protocol):
    def health_check(self) -> None:
        """Verify that the private PostgreSQL clinical store is reachable."""


class ExternalAuditSink(Protocol):
    def append(self, *, event_hash: str, payload: dict[str, object]) -> str:
        """Append an event to an external immutable audit destination."""


class _UnconfiguredIdentityVerifier:
    def verify(self, authorization_header: str) -> VerifiedIdentity:
        raise ProductionIntegrationNotConfigured(
            "No production OIDC adapter is configured; demo sessions cannot authenticate production"
        )


class _UnconfiguredClinicalObjectStorage:
    def put(self, *, patient_id: str, object_key: str, content: bytes, content_type: str) -> None:
        raise ProductionIntegrationNotConfigured("No encrypted clinical object storage adapter is configured")

    def create_download_url(self, *, patient_id: str, object_key: str, ttl_seconds: int) -> str:
        raise ProductionIntegrationNotConfigured("No clinical download URL adapter is configured")

    def delete(self, *, patient_id: str, object_key: str, workflow_id: str) -> None:
        raise ProductionIntegrationNotConfigured("No clinical deletion workflow adapter is configured")


class _UnconfiguredClinicalDatabase:
    def health_check(self) -> None:
        raise ProductionIntegrationNotConfigured(
            "No private PostgreSQL clinical database adapter is configured"
        )


class _UnconfiguredExternalAuditSink:
    def append(self, *, event_hash: str, payload: dict[str, object]) -> str:
        raise ProductionIntegrationNotConfigured("No external immutable audit sink adapter is configured")


@dataclass(frozen=True)
class ProductionAdapters:
    """All provider boundaries required by a clinical production service."""

    identity: IdentityVerifier
    database: ClinicalDatabase
    storage: ClinicalObjectStorage
    audit_sink: ExternalAuditSink

    @classmethod
    def unconfigured(cls) -> "ProductionAdapters":
        return cls(
            identity=_UnconfiguredIdentityVerifier(),
            database=_UnconfiguredClinicalDatabase(),
            storage=_UnconfiguredClinicalObjectStorage(),
            audit_sink=_UnconfiguredExternalAuditSink(),
        )

    def assert_ready(self) -> None:
        if any(
            isinstance(
                adapter,
                (
                    _UnconfiguredIdentityVerifier,
                    _UnconfiguredClinicalDatabase,
                    _UnconfiguredClinicalObjectStorage,
                    _UnconfiguredExternalAuditSink,
                ),
            )
            for adapter in (self.identity, self.database, self.storage, self.audit_sink)
        ):
            raise ProductionIntegrationNotConfigured(
                "Production adapters are incomplete; configure OIDC, private PostgreSQL, encrypted storage and external audit sink"
            )
