# Onkofizjo · autorización de infraestructura clínica

Este documento es un registro de decisión y autorización. No debe contener
contraseñas, tokens, claves privadas, URLs con credenciales ni datos de
pacientes. La autorización no se considera válida hasta que los campos
obligatorios estén completos y el responsable correspondiente haya aprobado
la residencia, el tratamiento de datos y el plan de recuperación.

## Estado

**Pendiente de aprobación.** No se ha autorizado todavía la creación ni la
conexión de un entorno clínico de producción.

## Decisión que debe completar el responsable

- Proveedor y producto: `______________________________________________`
- Organización/cuenta propietaria: `___________________________________`
- Región exacta de alojamiento: `______________________________________`
- Entorno autorizado: `staging sin datos reales / producción` (marcar uno)
- Dominio público de marketing: `_______________________________________`
- Dominio privado del CRM/API: `_______________________________________`
- RPO aprobado: `____________`
- RTO aprobado: `____________`
- Responsable del tratamiento y contacto: `____________________________`
- Responsable de firmar/revisar DPA: `_________________________________`
- Responsable de incidentes y escalado: `_______________________________`

## Evidencia obligatoria antes de conectar datos clínicos

- [ ] Residencia de datos y región aprobadas.
- [ ] DPA, subencargados y condiciones de salida revisados.
- [ ] OIDC, MFA, revocación de sesión y rotación de claves probados.
- [ ] PostgreSQL privado, TLS verificado, roles separados y RLS aplicado.
- [ ] Almacenamiento privado y cifrado con URLs temporales.
- [ ] Backups cifrados, política de retención y restauración probada.
- [ ] Auditoría externa append-only y retención aprobada.
- [ ] Secretos provisionados fuera de Git y fuera del frontend.
- [ ] Revisión jurídica polaca completada.
- [ ] Revisión de seguridad independiente completada.

Para cada casilla, la evidencia debe quedar enlazada en el expediente interno
de operación; no se deben pegar secretos en este repositorio.

## Alcance de la autorización

La persona autorizante debe confirmar explícitamente una de estas opciones:

> Autorizo crear y configurar el entorno de infraestructura clínica de
> Onkofizjo con el proveedor, organización, región, dominios y objetivos
> RPO/RTO indicados arriba, sujeto a la revisión DPA/RODO y a todos los gates
> técnicos de `infra/PROVIDER_DECISION.md`.

> No autorizo todavía la conexión de datos reales; únicamente autorizo la
> preparación de recursos vacíos de staging sin datos clínicos.

Opción elegida: `__________________________________________________________`

- Nombre: `______________________________________________________________`
- Cargo/relación con Gosia: `____________________________________________`
- Fecha: `____________________`
- Firma o confirmación trazable: `_______________________________________`

## Registro posterior a la provisión

Completar únicamente después de la autorización y sin incluir secretos:

- Identificador no sensible del proyecto: `______________________________`
- Evidencia de región/residencia: `______________________________________`
- Evidencia de DPA/RODO: `_______________________________________________`
- Evidencia de prueba de restauración y fecha: `_________________________`
- Resultado del preflight de producción: `pass / fail`
- Commit/release que se desplegó: `______________________________________`
- Revisor técnico: `____________________________________________________`
- Revisor legal/seguridad: `_____________________________________________`

Hasta completar este registro y los gates técnicos, el API debe permanecer en
modo `synthetic-only` y el runtime de producción debe fallar cerrado.
