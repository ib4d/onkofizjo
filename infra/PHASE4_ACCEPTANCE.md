# Onkofizjo · matriz de aceptación de la Fase 4

Este documento evita confundir infraestructura provisionada con infraestructura
aprobada para datos clínicos. La fase solo se cierra cuando cada fila tiene
evidencia reproducible, fecha, responsable y resultado.

## Estado de las puertas

| Puerta | Estado actual | Evidencia mínima para cerrar | No basta con |
|---|---|---|---|
| Proyecto UE y PostgreSQL | `VERIFICADA` para staging vacío | Proyecto `xhemiwewdbnnnlsoulvz` en `eu-central-1`, migraciones 1–4, 19 tablas, 19/19 RLS, 0 pacientes | Tener una URL de proyecto |
| Identidad y MFA | `PENDIENTE` | IdP aprobado, issuer/audience/JWKS probados, revocación, rotación, MFA AAL2 y pruebas negativas | `MFA_REQUIRED=true` en un `.env` |
| Storage clínico | `PENDIENTE` | Bucket privado, políticas por paciente/ecosistema, upload/download/delete autorizados, URLs temporales y logs | Un bucket público o escribir en tablas internas de Storage |
| Backups y restauración | `PENDIENTE` | Backup cifrado, retención aprobada, restore en entorno aislado, RPO/RTO medidos y evidencia de acceso restringido | Que el proveedor diga que hace backups |
| Auditoría externa | `PENDIENTE` | Sink append-only fuera de la base, recepción de eventos, retención, integridad y recuperación verificadas | Solo la cadena hash interna de PostgreSQL |
| Legal y seguridad | `PENDIENTE` | DPA/RODO revisado, retención/borrado aprobados, threat model y revisión independiente firmados | Plantillas legales sin revisión |

## Decisiones técnicas ya fijadas

- El proyecto Supabase se usa únicamente como staging vacío hasta cerrar todas
  las puertas.
- El API permanece `synthetic-only` y el arranque de producción permanece
  fail-closed.
- Los secretos, claves publicables y credenciales no se almacenan en Git.
- No se conectará la UI directamente a la base clínica; el acceso pasará por
  el runtime autenticado y sus políticas RLS.
- La aplicación exigirá MFA en el nivel de identidad y también en las reglas
  de acceso clínico. La documentación de Supabase describe el nivel `aal2` y
  los flujos de enrollment/challenge/verify: [MFA de Supabase](https://supabase.com/docs/guides/auth/auth-mfa).
- Los documentos clínicos deben permanecer en un bucket privado y descargarse
  mediante JWT autorizado o URL firmada temporal; un bucket público no es
  aceptable: [Buckets privados de Supabase](https://supabase.com/docs/guides/storage/buckets/fundamentals).

## Evidencia pendiente de solicitar o ejecutar

1. Configurar MFA TOTP obligatorio para el rol clínico y conservar evidencia de
   una sesión AAL1 rechazada y una sesión AAL2 aceptada.
2. Configurar el bucket privado mediante la API soportada por el proveedor,
   crear políticas RLS por ecosistema/paciente y probar expiración de URL.
3. Seleccionar el sink externo y probar reintentos, duplicados, retención y
   recuperación de una cadena de auditoría.
4. Ejecutar backup y restore con datos sintéticos aislados; registrar RPO, RTO,
   operador y resultado sin exportar datos clínicos.
5. Obtener revisión jurídica polaca y revisión independiente de seguridad.

Hasta completar los cinco puntos, la conclusión correcta es **Fase 4 en
progreso**, no “producción lista”.
