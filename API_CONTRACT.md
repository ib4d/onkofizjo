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

## Audit endpoint

`POST /api/audit-events` records a demo event. Production events must include:

- authenticated actor;
- role;
- resource type and identifier;
- action;
- timestamp;
- reason or task context;
- correlation identifier.

## Production gate

This API must not receive real patient data until authentication, authorization,
encryption, EU hosting, backups, retention policy and a Polish legal review are in
place.
