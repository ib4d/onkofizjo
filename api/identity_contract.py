"""Provider-neutral boundary for identities verified by a production OIDC adapter.

This module deliberately does not parse or verify JWT signatures. A production
OIDC adapter must perform signature, JWKS, nonce and token-type validation first
and pass a separate internal verification flag only afterwards. The application
then applies this stricter, provider-neutral claim contract.
"""
from dataclasses import dataclass
from datetime import datetime, timezone
from numbers import Real
from typing import Mapping


class IdentityRejected(ValueError):
    """Raised when a verified OIDC identity fails the application contract."""


@dataclass(frozen=True)
class VerifiedIdentity:
    """Minimal identity handed to authorization and internal role lookup."""

    subject: str
    issuer: str
    audience: str
    expires_at: datetime
    issued_at: datetime
    mfa_satisfied: bool
    assurance_level: str


def _timestamp(claims: Mapping[str, object], name: str) -> datetime:
    value = claims.get(name)
    if not isinstance(value, Real) or isinstance(value, bool):
        raise IdentityRejected(f"OIDC claim {name} must be a numeric timestamp")
    return datetime.fromtimestamp(float(value), tz=timezone.utc)


def _audience(claims: Mapping[str, object], expected: str) -> str:
    value = claims.get("aud")
    if isinstance(value, str):
        values = [value]
    elif isinstance(value, list) and all(isinstance(item, str) for item in value):
        values = value
    else:
        raise IdentityRejected("OIDC claim aud must be a string or a list of strings")
    if expected not in values:
        raise IdentityRejected("OIDC audience does not match the configured API audience")
    return expected


def validate_verified_identity(
    claims: Mapping[str, object],
    *,
    adapter_verified: bool,
    expected_issuer: str,
    expected_audience: str,
    now: datetime | None = None,
    clock_skew_seconds: int = 60,
) -> VerifiedIdentity:
    """Validate claims after an external adapter has verified the token.

    Roles are intentionally absent. They must be loaded from ``app_users`` by
    ``external_subject`` after this boundary, never trusted from token claims.
    """
    if adapter_verified is not True:
        raise IdentityRejected("OIDC claims must come from a cryptographically verified adapter")

    issuer = claims.get("iss")
    subject = claims.get("sub")
    if not isinstance(issuer, str) or issuer != expected_issuer:
        raise IdentityRejected("OIDC issuer does not match the configured issuer")
    if not isinstance(subject, str) or not subject.strip():
        raise IdentityRejected("OIDC subject is required")

    issued_at = _timestamp(claims, "iat")
    expires_at = _timestamp(claims, "exp")
    reference = now or datetime.now(timezone.utc)
    skew = max(0, clock_skew_seconds)
    if expires_at <= reference:
        raise IdentityRejected("OIDC token is expired")
    if issued_at.timestamp() > reference.timestamp() + skew:
        raise IdentityRejected("OIDC token was issued in the future")

    if claims.get("mfa_satisfied") is not True:
        raise IdentityRejected("MFA is required for clinical access")
    if claims.get("aal") != "aal2":
        raise IdentityRejected("MFA assurance level aal2 is required for clinical access")

    return VerifiedIdentity(
        subject=subject,
        issuer=issuer,
        audience=_audience(claims, expected_audience),
        expires_at=expires_at,
        issued_at=issued_at,
        mfa_satisfied=True,
        assurance_level="aal2",
    )
