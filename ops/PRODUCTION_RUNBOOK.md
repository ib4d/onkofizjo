# Onkofizjo · runbook operativo de producción

Este documento define los controles que deben existir antes de activar datos
clínicos reales. No fija por sí mismo plazos legales ni sustituye la revisión
del responsable del tratamiento y de un asesor jurídico polaco.

## Regla de seguridad

El API demo y todos sus fixtures son sintéticos. Está prohibido migrar datos
reales al entorno demo, al repositorio Git o a los logs de desarrollo.

La producción solo puede activarse si cada control de esta lista tiene un
responsable, una evidencia fechada y una versión de política o procedimiento.

## Preflight de identidad y autorización

- [ ] El proveedor OIDC está seleccionado, contratado y configurado con el
  issuer y audience exactos del servicio.
- [ ] La verificación de firma/JWKS, issuer, audience, nonce, expiración y tipo
  de token ocurre antes de llamar a `validate_verified_identity`.
- [ ] MFA está impuesto por política del IdP y el adaptador produce la señal
  interna `adapter_verified=True` solo después de verificar el token.
- [ ] Los roles se resuelven en `app_users.external_subject`; nunca se aceptan
  desde claims del usuario.
- [ ] Las cookies de sesión son Secure, HttpOnly y SameSite Lax o Strict; no se
  escriben tokens ni datos clínicos en logs.
- [ ] Se ha probado revocación, desactivación de usuario, rotación de claves y
  expiración de sesión.

## Preflight de datos clínicos

- [ ] La migración `db/001_initial_production.sql` se ha aplicado en una base
  privada, cifrada y aprobada para la región de tratamiento.
- [ ] El workflow de staging ha pasado con RLS, aislamiento de ecosistemas,
  negativas cross-paciente y auditoría append-only.
- [ ] El rol de aplicación no es propietario, no tiene BYPASSRLS y no puede
  modificar ni borrar `audit_events`.
- [ ] El almacenamiento de documentos es privado, cifrado, con claves
  gestionadas y URLs temporales; nunca se exponen claves de almacenamiento al
  navegador.
- [ ] Las cargas y descargas están vinculadas a paciente, permiso, propósito y
  evento de auditoría.

## Retención, acceso y borrado

La política versionada debe definir, por categoría de dato, la retención, el
responsable, la base jurídica, la revisión y el destino final. Como mínimo debe
cubrir identidad, historia clínica, consentimientos, documentos, teleconsulta,
pagos, conocimiento y auditoría.

El workflow de borrado debe:

1. autenticar la solicitud y verificar identidad, alcance y posibles bloqueos
   legales o asistenciales;
2. crear una solicitud con responsable y aprobación separada de la ejecución;
3. exportar lo permitido y registrar el resultado sin copiar datos clínicos a
   logs;
4. revocar accesos y borrar o anonimizar cada sistema autorizado, incluido el
   almacenamiento de objetos y copias según la política aprobada;
5. conservar únicamente la evidencia mínima de auditoría exigida, sin payload
   clínico innecesario;
6. cerrar la solicitud con evidencia verificable y revisión humana.

## Backups y recuperación

- [ ] Backups cifrados, privados y separados de las credenciales de producción.
- [ ] Política de RPO/RTO aprobada por la responsable del servicio.
- [ ] Restauración probada en un entorno aislado, con fecha, duración, versión
  de esquema, resultado de smoke tests y verificación de RLS.
- [ ] Se ha comprobado que una restauración no reintroduce datos borrados fuera
  del periodo permitido ni rompe la cadena de auditoría.
- [ ] El acceso a backups queda auditado y limitado al personal autorizado.

## Incidentes y auditoría

El runbook de incidentes versionado debe especificar contactos, severidades,
contención, preservación de evidencias, evaluación de impacto, comunicación al
responsable del tratamiento y decisiones de notificación conforme a la revisión
jurídica aplicable.

Ante un incidente:

1. contener sin destruir evidencias;
2. desactivar credenciales o sesiones comprometidas;
3. preservar logs y auditoría en el sink inmutable;
4. identificar pacientes, ecosistemas y datos afectados con el mínimo acceso;
5. documentar decisiones y aprobaciones;
6. ejecutar las comunicaciones y notificaciones que correspondan;
7. cerrar con acciones correctivas y una nueva prueba de controles.

## Gate de activación

La activación se bloquea si falta cualquiera de estos identificadores:

- versión de política RODO/retención;
- identificador del workflow de borrado;
- versión del runbook de incidentes;
- evidencia de cifrado de almacenamiento y backups;
- evidencia de restauración probada;
- revisión independiente de seguridad y aprobación legal.

Los valores técnicos se suministran mediante variables de producción validadas
por `api/production_config.py`; no se guardan secretos ni valores reales en este
runbook.
