# Onkofizjo · mapa de datos y controles RODO/GDPR

Este documento es una especificación de producto y seguridad, no asesoramiento
jurídico. Antes de tratar datos reales debe revisarlo un abogado en Polonia y la
persona responsable del tratamiento.

## Principios de diseño

- La web de marketing no recibe solicitudes clínicas, historias médicas ni
  reservas. Su CTA operativo dirige a la agenda/CRM acordada o al teléfono.
- El CRM es un entorno privado; ninguna ruta de marketing recibe datos de salud.
- Los datos de salud se almacenan separados de identidad pública y de contenido
  de marketing, con acceso mínimo por rol, paciente, ecosistema y ubicación.
- La IA solo recibe el contexto mínimo necesario para una tarea explícita y
  nunca puede aprobar, firmar ni enviar una recomendación clínica por sí misma.
- La grabación de teleconsultas está desactivada por defecto. Si se habilitara,
  requiere consentimiento y política de retención independientes.
- Todos los accesos, exportaciones, cambios, aprobaciones y entregas generan un
  evento de auditoría; los logs no deben contener el contenido clínico completo.

## Inventario de datos

| Categoría | Ejemplos | Finalidad | Acceso inicial | Retención |
|---|---|---|---|---|
| Identidad y contacto | nombre, teléfono, correo, idioma | identificar y contactar al paciente | Gosia; colaborador asignado según necesidad | plazo por definir con asesoría jurídica |
| Datos clínicos | diagnóstico declarado, síntomas, medidas, observaciones, plan | prestar y documentar atención | Gosia; colaborador asignado; IA solo con contexto acotado | plazo clínico/legal documentado por el responsable |
| Citas y operación | servicio, ecosistema, ubicación, estado, pagos asociados | organizar la atención y la administración | Gosia; colaboradores según asignación | política operativa y fiscal separadas |
| Dietética | restricciones, objetivos, comidas, fuentes, versiones | elaborar y revisar planes individualizados | Gosia; IA solo propuesta; paciente solo documento publicado | vinculado al expediente y a la política clínica |
| Teleconsulta | modo, proveedor, sesión, consentimiento, timestamps | prestar consulta remota | Gosia y proveedor estrictamente necesario | no grabar por defecto; sesión y evidencia según política |
| Documentos | plan, consentimiento, informe, entrega | documentar y comunicar | Gosia; acceso asignado | conservar versión, revocación y entrega |
| Pagos | importe, divisa, método, referencia | facturación y conciliación | Gosia/administración; nunca IA con detalle innecesario | política fiscal y contractual |
| Conocimiento | reglas de Gosia, recetas, protocolos, evidencia | apoyar workflow y Hermes | Gosia; agentes solo fuentes aprobadas | versionado y revisión/expiración |
| Auditoría | actor, rol, acción, recurso, motivo, timestamps, hash | responsabilidad y detección de incidentes | solo Gosia/seguridad autorizada | retención inmutable definida por política |

Los plazos anteriores no son plazos legales inventados. Cada uno debe convertirse
en una configuración aprobada, con responsable, base jurídica, fecha de revisión
y proceso de borrado, anonimización o bloqueo.

## Consentimientos y estados mínimos

Los consentimientos deben ser independientes y versionados:

1. atención y tratamiento;
2. tratamiento de datos de salud y documentación del expediente;
3. teleconsulta;
4. grabación de audio/vídeo, únicamente si se ofrece;
5. comunicaciones no clínicas;
6. entrega de documentos por canal elegido.

Cada registro debe conservar versión del texto, idioma, fecha/hora, método,
prueba de quién lo otorgó, estado (`PENDING`, `GRANTED`, `WITHDRAWN`, `EXPIRED`)
y relación con el documento o sesión correspondiente. Retirar un consentimiento
no debe borrar automáticamente la evidencia que una obligación legítima exija
conservar; debe iniciar el workflow jurídico correspondiente.

## Derechos y workflows que debe soportar el CRM

- localizar todos los datos vinculados a una persona;
- exportar un paquete revisado por Gosia;
- corregir datos con historial de auditoría;
- registrar restricción, oposición o retirada de consentimiento;
- borrar o anonimizar cuando proceda, sin romper registros que deban conservarse;
- registrar solicitudes, responsable, plazo interno, resolución y evidencia;
- gestionar una violación: detección, contención, evaluación, notificación y
  cierre.

Estos workflows no deben implementarse como un botón de borrado directo. Deben
requerir revisión, motivo, alcance y auditoría.

## Proveedores y transferencias

Antes de conectar IdP, base de datos, almacenamiento, vídeo, correo, pagos o IA
se debe registrar: proveedor, finalidad, región, subencargados, cifrado,
retención, mecanismo de eliminación, contrato de tratamiento, soporte de
derechos y mecanismo de transferencia internacional, si aplica.

## Checklist de aprobación jurídica y de seguridad

- [ ] responsable del tratamiento y contactos definidos;
- [ ] registro de actividades de tratamiento aprobado;
- [ ] política de privacidad y avisos de teleconsulta publicados;
- [ ] textos de consentimiento en polaco e inglés revisados;
- [ ] matriz de retención y borrado aprobada;
- [ ] contratos con encargados/subencargados revisados;
- [ ] evaluación de riesgos y, si procede, DPIA para datos de salud/IA;
- [ ] procedimiento de derechos y brechas probado;
- [ ] revisión independiente de RLS, cookies, almacenamiento y auditoría;
- [ ] prueba de restauración y acceso de emergencia documentada.
