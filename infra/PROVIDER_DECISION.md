# Onkofizjo · decisión de infraestructura clínica

Estado: **pendiente de selección y autorización del responsable del servicio**.

Este documento evita conectar por accidente el prototipo a un proveedor no
aprobado. No contiene credenciales, datos de pacientes ni una decisión de
compra.

El registro formal de autorización, responsables y evidencia de provisión está
en `infra/PROVIDER_AUTHORIZATION.md`. Su existencia no implica que la
autorización haya sido concedida.

## Baseline recomendado

La primera implementación real debe ser un stack gestionado en una región
aprobada por el responsable del tratamiento, con:

1. proveedor OIDC con MFA, rotación JWKS, sesiones revocables y DPA/contratos
   adecuados;
2. PostgreSQL privado con TLS verificado, RLS, roles separados, migraciones
   reproducibles y backups cifrados;
3. almacenamiento de objetos privado y cifrado para documentos, con claves
   gestionadas y URLs temporales emitidas por el backend;
4. servicio de aplicación separado del frontend público, con secretos en un
   secret manager y sin datos clínicos en variables de cliente;
5. sink de auditoría externo, inmutable y restringido, además de la cadena hash
   interna de PostgreSQL;
6. monitorización, alertas, exportación y procedimiento de salida que permitan
   cambiar de proveedor sin perder pacientes, documentos ni auditoría.

El stack exacto queda deliberadamente abierto hasta revisar residencia de
datos, subencargados, DPA, controles de acceso, retención y capacidad de
restauración del proveedor elegido.

## Criterios de aceptación obligatorios

No se autoriza staging con datos reales ni producción hasta disponer de
evidencia de cada punto:

- [ ] región y residencia de datos aprobadas;
- [ ] DPA, subencargados y condiciones de salida revisados;
- [ ] OIDC, MFA, revocación y rotación de claves probados;
- [ ] PostgreSQL cifrado, privado y con el esquema/RLS de este repositorio;
- [ ] almacenamiento cifrado, privado y con URLs temporales;
- [ ] backups cifrados y restauración probada con fecha, RPO/RTO y resultado;
- [ ] sink de auditoría externo probado y con retención aprobada;
- [ ] alertas, respuesta a incidentes y contactos de escalado definidos;
- [ ] revisión jurídica polaca y revisión de seguridad independiente aprobadas;
- [ ] secretos provisionados fuera de Git y fuera del frontend.

## Información necesaria para ejecutar la conexión

El responsable debe proporcionar o autorizar:

- proveedor o shortlist aprobada;
- región de alojamiento;
- dominio de producción y dominio del CRM;
- objetivos RPO/RTO;
- responsable de firmar DPA y revisar retención/borrado;
- método de gestión de secretos y contactos de incidentes.

Hasta que esos datos existan, la configuración de producción debe seguir
fallando cerrada y el API local debe seguir declarando `synthetic-only`.
