"""Executable contract checks for the production identity boundary."""
from datetime import datetime, timezone

from identity_contract import IdentityRejected, validate_verified_identity


REFERENCE = datetime(2026, 8, 17, 12, 0, tzinfo=timezone.utc)
BASE = {
    "iss": "https://id.example.eu/",
    "aud": ["onkofizjo-api", "other-client"],
    "sub": "user-123",
    "iat": REFERENCE.timestamp() - 30,
    "exp": REFERENCE.timestamp() + 300,
    "mfa_satisfied": True,
    "aal": "aal2",
}


identity = validate_verified_identity(
    BASE,
    adapter_verified=True,
    expected_issuer="https://id.example.eu/",
    expected_audience="onkofizjo-api",
    now=REFERENCE,
)
assert identity.subject == "user-123"
assert identity.mfa_satisfied is True


def rejects(changes: dict[str, object], expected: str, *, adapter_verified: bool = True) -> None:
    candidate = BASE | changes
    try:
        validate_verified_identity(
            candidate,
            adapter_verified=adapter_verified,
            expected_issuer="https://id.example.eu/",
            expected_audience="onkofizjo-api",
            now=REFERENCE,
        )
    except IdentityRejected as error:
        assert expected in str(error), (expected, error)
    else:
        raise AssertionError(f"identity contract accepted invalid claims: {changes}")


rejects({}, "cryptographically verified", adapter_verified=False)
rejects({"iss": "https://attacker.example/"}, "issuer")
rejects({"aud": ["different-api"]}, "audience")
rejects({"sub": ""}, "subject")
rejects({"exp": REFERENCE.timestamp() - 1}, "expired")
rejects({"mfa_satisfied": False}, "MFA")
rejects({"aal": "aal1"}, "aal2")

print("PASS: production identity contract accepts only verified, scoped, unexpired MFA identities.")
