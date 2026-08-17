# Onkofizjo · proyecto clínico UE provisionado

Este registro contiene únicamente metadatos no sensibles. No añadir aquí
claves publicables, `service_role`, secretos, contraseñas ni datos clínicos.

## Proyecto

- Proveedor: Supabase
- Organización: `ib4d's Org`
- Nombre: `Onkofizjo Clinical EU`
- Referencia: `xhemiwewdbnnnlsoulvz`
- Región: `eu-central-1`
- URL del proyecto: <https://xhemiwewdbnnnlsoulvz.supabase.co>
- Estado verificado: `ACTIVE_HEALTHY`
- Plan de organización verificado: `free` — no aprobado para datos clínicos reales.
- Uso autorizado: staging vacío, sin datos clínicos reales

## Migraciones aplicadas

1. `001_initial_production` — esquema clínico, RLS, políticas y auditoría
   append-only.
2. `002_harden_function_search_paths` — endurecimiento de funciones clínicas
   y de auditoría frente a `search_path` mutable.
3. `003_index_foreign_keys` — índices de cobertura para claves foráneas.
4. `004_enable_reference_rls` — RLS también en `ecosystems` y `locations`.
5. `005_require_aal2_in_rls` — las funciones de autorización rechazan sesiones
   sin assurance `aal2` antes de resolver el usuario clínico.
6. `006_revoke_public_security_definers` — los helpers de autorización no son
   invocables como RPC por `anon` ni `authenticated`.

## Verificación posterior

- PostgreSQL: `17.6`.
- Tablas en `onkofizjo`: `19`.
- Tablas con RLS activo: `19/19`.
- Ecosistemas de referencia: `6`.
- Pacientes: `0`.
- Eventos de auditoría: `0`.
- Asesores de seguridad Supabase: `0 lints`.
- Security Advisor revalidado después de las migraciones 005–006: `0 lints`.
- Migraciones registradas en el proyecto: `4/4`, en el orden documentado arriba.
- Servicio Auth verificado en logs de inicialización; no hay usuarios clínicos
  creados. Supabase informa una advertencia interna de deprecación sobre
  `GOTRUE_JWT_*_GROUP_NAME`; debe eliminarse o confirmarse con el proveedor
  antes del go-live, aunque no afecta al staging vacío.
- Advertencias de rendimiento: únicamente índices aún no usados en una base
  vacía; deben reevaluarse después de tráfico sintético representativo.
- El plan actual debe revisarse antes del go-live para confirmar soporte,
  retención, backups, restauración y condiciones contractuales adecuadas para
  datos de salud.

## Pendiente antes de datos reales

- IdP/OIDC con MFA, revocación y rotación de claves.
- Storage privado cifrado con URLs temporales.
- Sink externo de auditoría inmutable.
- Backups cifrados y restauración con RPO/RTO aprobados.
- Revisión DPA/RODO, retención, borrado y seguridad independiente.

El API local y el runtime de producción siguen protegidos por el contrato
`synthetic-only`/fail-closed hasta completar esos puntos.
