# Onkofizjo · Fase 7

## Alcance actual

La fase se ejecuta sobre el entorno sintético. El API expone health, readiness
y métricas operativas sin datos clínicos; readiness devuelve `503 NOT_READY`
hasta que existan las puertas productivas.

## Implementado

- `GET /api/health`: declara `demo` y `synthetic-only`.
- `GET /api/readiness`: fail-closed con bloqueadores explícitos.
- `GET /api/metrics`: contadores mínimos sin payload clínico.
- `phase7-smoke.ps1`: valida los tres contratos.
- Tests unitarios y smoke de Fases 5 y 6 permanecen ejecutables.

## Pendiente

E2E de navegador, observabilidad externa, alertas, backups/restauración y
staging productivo dependen de reanudar Fase 4.
