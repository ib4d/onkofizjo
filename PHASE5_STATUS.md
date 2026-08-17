# Onkofizjo · Fase 5

## Alcance actual

La fase se ejecuta con datos sintéticos y proveedor-neutral porque Fase 4 está
congelada. No es una autorización para tratar pacientes reales.

## Subfases

- **5.1 Teleconsulta segura de demo:** implementada en `teleconsult.html` y
  `api/server.py`: selección contextual de paciente/cita, consentimiento
  explícito para vídeo, preflight de cámara/micrófono, vista previa local,
  alternativa telefónica, estados de sesión, finalización/cancelación,
  auditoría y grabación desactivada.
- **5.2 Automatización dietética grounded:** implementada en el endpoint de
  propuestas: perfil contextual por paciente, objetivo, restricciones,
  advertencias, fuentes placeholder verificables, comidas propuestas,
  versionado y aprobación humana obligatoria.
- **5.3 Integración CRM:** completada para demo. El workspace enlaza con
  teleconsulta y dietética; `diet-data-bridge.js` permite generar una propuesta
  contextualizada y registrar aprobación; los contextos se mantienen por
  `patientId`.
- **5.4 QA automatizado:** completada para demo. `api-smoke.ps1` verifica
  consentimiento, permisos, contexto paciente-cita, propuesta dietética,
  auditoría y grabación desactivada; `web-smoke.ps1` verifica las 18 rutas,
  contratos de pantalla y headers responsive/seguridad.

La prueba específica de fase `phase5-smoke.ps1` también pasa: vídeo con
consentimiento, rechazo sin consentimiento, fallback telefónico, aislamiento
por paciente, propuesta dietética versionada y aprobación humana.

## Frontera honesta

La pantalla prepara una sala local de demostración y registra el contrato de
sesión. Todavía no existe conexión con un proveedor externo de vídeo/telefonía,
grabación, almacenamiento clínico ni entrega automática de dietas. Eso requiere
reanudar Fase 4 y aportar proveedores/autorizaciones. Por tanto, la Fase 5 queda
cerrada únicamente en su alcance proveedor-neutral y sintético; no es una
declaración de disponibilidad clínica o comercial en producción.
