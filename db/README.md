# Persistencia de producción

`001_initial_production.sql` es el primer contrato de persistencia PostgreSQL
para Onkofizjo. No contiene datos demo y no se ejecuta automáticamente desde el
API local.

Incluye:

- identidad interna separada del proveedor de autenticación mediante
  `external_subject`;
- usuarios, roles, ecosistemas, ubicaciones y asignaciones por paciente;
- pacientes, consentimientos, citas, notas, dietas versionadas, documentos,
  teleconsultas, pagos y ejecuciones de asistentes;
- Row Level Security para que el acceso clínico dependa del usuario verificado y
  de la asignación del paciente;
- auditoría append-only con cadena hash y bloqueo de `UPDATE`/`DELETE`.

## Condiciones antes de usarlo

Este esquema es un contrato técnico, no una certificación legal ni de seguridad.
Antes de ejecutarlo con datos reales hay que:

1. elegir y revisar el proveedor de identidad, MFA y el mecanismo que fija
   `request.jwt.claim.sub` o `app.user_subject` dentro de una transacción;
2. ejecutar la migración en una base gestionada cifrada, privada y alojada en la
   región aprobada por el responsable del tratamiento;
3. crear roles de base de datos con mínimo privilegio y comprobar que el rol de
   la aplicación no puede desactivar RLS ni modificar auditoría;
4. configurar almacenamiento de documentos cifrado separado de PostgreSQL;
5. probar backups, restauración, retención, borrado y respuesta a incidentes;
6. realizar revisión independiente de RLS, funciones `SECURITY DEFINER`,
   aislamiento multi-ecosistema y obligaciones RODO/GDPR.

La cadena hash es una señal de integridad dentro de la base. Para producción
también se necesita una copia de auditoría externa, inmutable y con acceso
restringido.

## Validación local del contrato

```powershell
python db/validate_schema.py
```

Esta comprobación es estática. La validación real requiere aplicar la migración
en staging y ejecutar pruebas negativas de RLS con cada rol y ecosistema.

El guion [`staging_rls_checks.sql`](C:\dev\mis-apps\reha-app\db\staging_rls_checks.sql)
contiene esas comprobaciones. Requiere fixtures sintéticos ya creados, el rol
de aplicación (no el propietario de la migración), y hace rollback de todos sus
cambios al finalizar.
