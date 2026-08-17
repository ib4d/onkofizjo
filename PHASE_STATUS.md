# Onkofizjo · estado global de ejecución

Última verificación: 2026-08-17

## Estado actual

**Fase activa: Fase 4 · persistencia, identidad, permisos y seguridad clínica — en progreso.**

La aplicación dispone de un prototipo navegable y una frontera de seguridad para
desarrollo. Sigue prohibido introducir datos reales: el API local declara
`demo: true` y `dataMode: synthetic-only`.

## Fases

| Fase | Estado | Evidencia / alcance |
|---|---|---|
| 0. Alcance y requisitos | Completada | Nichos, idiomas, canales de cita, CRM y criterios de teleconsulta definidos. |
| 1. Fundación técnica | Completada para demo | Rutas web, API local, datos sintéticos, flujo de arranque y smoke tests. |
| 2. Producto integrado | Completada para prototipo | Marketing PL/EN, CRM, pacientes, calendario, notas, dietas, documentos, Hermes demo y teleconsulta demo. |
| 3. Responsive y accesibilidad base | Completada para prototipo | Navegación responsive, reducción de ruido durante scroll, cierre de paneles y rutas móviles verificadas. |
| 4. Persistencia, identidad y seguridad clínica | **En progreso** | Controles de desarrollo implementados; infraestructura real pendiente. |
| 5. Teleconsulta real y automatización dietética | Pendiente | Proveedor de vídeo/teléfono, consentimiento, almacenamiento y workflow clínico real. |
| 6. Hermes/LLM y agentes grounded | Pendiente | RAG con fuentes aprobadas, permisos por tarea, trazabilidad y revisión humana en producción. |
| 7. QA, observabilidad y despliegue | Pendiente | Tests E2E, monitorización, alertas, backups probados y entorno de staging/producción. |
| 8. Lanzamiento y distribución | Pendiente | Dominio, SEO, analítica consentida, operación y publicación masiva. |

## Fase 4 · subfases verificadas

- **4.1 Sesión de desarrollo:** completada para demo. Las lecturas clínicas y las
  escrituras operativas exigen una sesión válida; el rol efectivo se deriva en
  servidor.
- **4.2 Autorización y consistencia:** completada para demo. Se validan paciente,
  cita, relación cita-paciente, estados, aprobación humana de dietas y límites
  del agente AI.
- **4.3 Frontera web/API:** completada para demo. CORS usa allowlist explícita,
  permite `Authorization` en preflight y el servidor web envía headers base de
  seguridad.
- **4.4 Auditoría:** completada para demo. Los eventos tienen cadena hash y el
  endpoint verifica su integridad; los eventos sintéticos históricos se migran
  determinísticamente.
- **4.5 Contrato de persistencia:** preparado, no conectado. Existe una
  migración PostgreSQL sin datos demo con RLS por usuario/paciente, separación
  de ecosistemas y ubicaciones, dietas versionadas, teleconsulta, documentos,
  pagos y auditoría append-only. La validación local es estática porque este
  entorno no tiene PostgreSQL de staging. También existe un guion de pruebas
  negativas para ejecutar allí con fixtures sintéticos y rollback transaccional,
  un bootstrap Docker con roles separados y volumen local aislado, y un workflow
  de integración continua que ejecuta el mismo contrato en PostgreSQL efímero.
  El workflow de integración continua se ha verificado correctamente en
  GitHub Actions, incluyendo migración, fixtures, auditoría append-only y RLS
  con rol de aplicación no propietario. El bootstrap local sigue requiriendo
  Docker/PostgreSQL en la máquina de desarrollo; la ejecución más reciente se
  debe comprobar en el historial del workflow antes de cada entrega.
- **4.6 Infraestructura clínica de producción:** en progreso. Ya existe un
  proyecto Supabase UE vacío, con el esquema aplicado y los asesores de
  seguridad sin lints; todavía faltan
  IdP real con MFA, cookies HttpOnly/Secure/SameSite, base de datos cifrada,
  almacenamiento de documentos cifrado, backups y restauración probados,
  retención/borrado, acuerdos RODO/GDPR, respuesta a incidentes y revisión de
  seguridad independiente. Existe un contrato ejecutable que rechaza una
  configuración incompleta o insegura, una frontera OIDC fail-closed con MFA y
  un runbook operativo versionado en `ops/PRODUCTION_RUNBOOK.md`, además de una
  plantilla de onboarding sin secretos en `infra/production.env.example`.
  Todavía no
  hay IdP, almacenamiento clínico, auditoría externa ni credenciales de
  infraestructura real conectados. El mapa
  de datos y los workflows jurídicos están documentados en
  `PRIVACY_DATA_MAP.md`, y la decisión de infraestructura pendiente está
  documentada en `infra/PROVIDER_DECISION.md`. Las interfaces provider-neutral
  de OIDC, almacenamiento clínico y auditoría externa fallan cerradas en
  `api/production_adapters.py` (incluye ahora el adaptador privado de
  PostgreSQL, operaciones obligatorias y comprobaciones `assert_ready()` por
  proveedor), y
  `api/production_startup.py` impide iniciar el runtime si falta cualquiera de
  esas integraciones; estos artefactos requieren revisión jurídica polaca y
  proveedores autorizados antes de conectar datos reales. El proyecto creado es
  únicamente staging vacío y no cambia el estado `synthetic-only` del API.
  El registro formal de autorización está en
  `infra/PROVIDER_AUTHORIZATION.md`; registra la autorización del staging vacío.
  El registro técnico no sensible del proyecto provisionado está en
  `infra/SUPABASE_PROJECT.md`.

## Evidencia ejecutada

```powershell
.\api-smoke.ps1 -Port 8809
.\web-smoke.ps1 -Port 4183
```

Resultado actual: API smoke completo y 18 rutas web verificadas. El API demo
rechaza el modo `ONKOFIZJO_ENV=production`; esa negativa es intencional hasta
que exista un servicio de producción revisado.

## Regla de avance

Una fase solo se marcará como completada cuando exista evidencia reproducible de
todo su alcance. Las comprobaciones de demo no se presentarán como cumplimiento
de producción.
