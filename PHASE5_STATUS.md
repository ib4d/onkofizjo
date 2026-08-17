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
- **5.3 Integración CRM:** pendiente de validación visual y de flujo en todas las
  rutas de CRM; no se marca completa por existir solo el endpoint y la pantalla.
- **5.4 QA y cierre:** pendiente hasta ejecutar pruebas de estado, permisos,
  pacientes distintos, consentimiento, fallback telefónico y restricciones.

## Frontera honesta

La pantalla prepara una sala local de demostración y registra el contrato de
sesión. Todavía no existe conexión con un proveedor externo de vídeo/telefonía,
grabación, almacenamiento clínico ni entrega automática de dietas. Eso requiere
reanudar Fase 4 y aportar proveedores/autorizaciones.
