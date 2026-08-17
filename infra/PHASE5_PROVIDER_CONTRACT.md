# Fase 5 · contrato de proveedor de teleconsulta

Este contrato separa el flujo clínico de Onkofizjo del proveedor externo. La
implementación actual es `DEMO_PROVIDER_NEUTRAL`; no contiene credenciales ni
envía audio/vídeo fuera del navegador.

## Operaciones obligatorias

1. `createSession(patientId, appointmentId, mode, consent)` debe verificar que
   la cita pertenece al paciente y rechazar VIDEO sin consentimiento explícito.
2. `joinSession(sessionId, participant)` debe devolver una sala efímera y
   registrar quién entró y cuándo.
3. `transition(sessionId, state)` solo puede aceptar `READY`, `RINGING`,
   `ACTIVE`, `ENDED`, `CANCELLED` o `FAILED`.
4. `endSession(sessionId)` debe cerrar la sesión y escribir auditoría.
5. `phoneFallback(patientId, appointmentId)` debe registrar el intento y
   devolver un canal telefónico autorizado; nunca debe enviar el número al
   navegador si no existe una política de exposición aprobada.

## Invariantes

- `recording=false` por defecto y sin almacenamiento de grabaciones en Fase 5.
- Ningún agente AI puede iniciar, aceptar o aprobar una consulta.
- El paciente y la cita son siempre el mismo contexto.
- El proveedor debe residir en una región autorizada por la revisión legal y
  contractual de Fase 4.
- Los errores de proveedor deben dejar la sesión en `FAILED` y ofrecer el
  fallback telefónico sin perder la auditoría.

## Puerta de producción

La conexión real requiere completar Fase 4: identidad MFA, almacenamiento,
acuerdos de tratamiento de datos, retención, proveedor autorizado, secretos y
pruebas de restauración. Hasta entonces, la UI y el API solo pueden operar con
datos sintéticos y `DEMO_PROVIDER_NEUTRAL`.
