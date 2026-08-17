# onkofizjo API contract — first slice

The browser prototype currently reads local JSON. This contract defines the first
server boundary so the UI can switch to authenticated requests without changing
domain semantics.

## Read endpoints

`GET /api/patients` returns the selected patient record.

`GET /api/diet-plans` returns the current plan with status, warnings, meals,
sources and approval metadata.

`GET /api/assistant-runs` returns the latest assistant output and review state.

`GET /api/operations` returns documents and payment records.

`GET /api/knowledge` returns demo knowledge items. Production must version
internal rules separately from external evidence and retain source metadata.

`POST /api/notes` creates a clinical note draft and automatically records an
audit event. Production must validate the patient context, actor permission and
required fields before allowing a signed clinical entry.

## Audit endpoint

`POST /api/audit-events` records a demo event. Production events must include:

- authenticated actor;
- role;
- resource type and identifier;
- action;
- timestamp;
- reason or task context;
- correlation identifier.

`GET /api/audit-events` returns events persisted in the local development
SQLite database. Production must not expose unrestricted audit logs to the browser.

## Controlled write endpoint

`POST /api/diet-plans` creates a demo proposal with status `ASSISTANT_PROPOSED`.
It can never create `APPROVED` or `SENT` directly. Production must require an
authenticated actor, validate patient context and create an audit event.

Fase 5 proposals accept `patientId`, `goal` and `restrictions[]` and return a
patient-specific `profileSnapshot`, `version`, `meals`, `warnings`, `sources`
and `humanApprovalRequired: true`. They remain synthetic and must be reviewed
by GOSIA before delivery.

`POST /api/teleconsultations` accepts `patientId`, optional `appointmentId`,
`mode` (`VIDEO|PHONE`), `state` (`READY|RINGING|ACTIVE|ENDED|CANCELLED|FAILED`)
and `consent`. VIDEO rejects requests without explicit consent. Every response
has `recording: false`. The current provider is `DEMO_PROVIDER_NEUTRAL`: local
camera/microphone preflight and a `tel:` fallback are implemented, but no
external video or phone provider is connected yet.

`POST /api/appointments` creates a demo internal appointment with status
`SCHEDULED` and `humanConfirmationRequired: true`. It is intentionally not a
public booking endpoint.

`POST /api/appointments/status` accepts only the official lifecycle values and
returns `auditRequired: true`. Production must validate the current state and
the actor's permission before applying a transition.

## Production gate

This API must not receive real patient data until authentication, authorization,
encryption, EU hosting, backups, retention policy and a Polish legal review are in
place.
