# Onkofizjo · runbook post-lanzamiento

## Principios

- No usar logs, métricas ni tickets para nombres, IDs de pacientes, notas,
  dietas, llamadas o cualquier dato de salud.
- Todo cambio pasa por branch, revisión, smoke tests y rollback definido.
- Si falla una puerta de seguridad, se detiene el release y se mantiene la
  última versión conocida.

## Severidad

- **P0:** exposición de datos, autenticación rota o operación clínica insegura.
  Aislar el servicio, conservar evidencia mínima no clínica, notificar al
  responsable y no reabrir hasta revisión de seguridad.
- **P1:** caída de una función clínica sin exposición de datos. Activar
  fallback documentado, registrar impacto agregado y preparar rollback.
- **P2:** degradación visual o funcional no clínica. Priorizar en la próxima
  ventana de mantenimiento.

## Checklist de release

1. Confirmar issue, alcance y rollback.
2. Ejecutar tests unitarios, `api-smoke.ps1`, `web-smoke.ps1` y el smoke de la
   fase afectada.
3. Revisar diff y artefactos generados; no incluir fixtures clínicos reales.
4. Publicar en staging autorizado y observar health/readiness.
5. Registrar versión, fecha, responsable y resultado.

## Métricas permitidas

Disponibilidad, latencia, errores por ruta, estado de release, uso agregado por
ecosistema y conversiones de marketing con consentimiento. Nunca se agregan
por paciente ni se envía contenido clínico a analítica.
