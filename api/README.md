# Development API

Run from the repository root:

```powershell
python api/server.py
```

Or start the web server and API together:

```powershell
.\start-dev.ps1
```

Endpoints:

- `GET /api/health`
- `GET /api/patients`
- `GET /api/diet-plans`
- `GET /api/assistant-runs`
- `GET /api/operations`
- `POST /api/audit-events`

This is a local demo API only. It uses verified in-memory demo sessions and
synthetic records so the frontend can exercise authorization boundaries without
real patient data. It is not production-ready: it does not provide a real
identity provider, encrypted clinical storage, rate limiting, managed backups,
or production health-data safeguards. See `SECURITY_BOUNDARY.md` for the
mandatory production gates.

The future service configuration contract can be checked without exposing
secrets:

```powershell
python api/validate_production_config.py
```

The provider-neutral identity boundary is checked separately:

```powershell
python api/validate_identity_contract.py
```

It accepts only claims already verified by a real OIDC adapter, with the exact
issuer and audience, a non-empty subject, valid time bounds and explicit MFA.
The application role is intentionally not read from the token; production code
must resolve it from `app_users.external_subject` after authentication.

The production configuration also refuses to start until the approved RODO
retention policy, deletion workflow and incident runbook are versioned, and
encryption has been confirmed for both clinical storage and backups. These are
operational gates, not a substitute for Polish legal review.
