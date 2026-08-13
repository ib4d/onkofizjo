# Development API

Run from the repository root:

```powershell
python api/server.py
```

Endpoints:

- `GET /api/health`
- `GET /api/patients`
- `GET /api/diet-plans`
- `GET /api/assistant-runs`
- `GET /api/operations`
- `POST /api/audit-events`

This is a local demo API only. It has no authentication, encryption, persistence,
rate limiting or production health-data safeguards.
