# Fase 4 · acciones externas para desbloquear producción

Esta guía es para la persona propietaria de las cuentas y para el responsable
legal. No introducir datos reales de pacientes hasta completar todos los pasos.
El proyecto actual `xhemiwewdbnnnlsoulvz` seguirá siendo staging vacío.

## Orden obligatorio

### 1. Aprobar el proveedor y el contrato

1. Decidir si Supabase será el proveedor clínico definitivo o solo staging.
2. Si será definitivo, revisar el plan de pago adecuado y confirmar por escrito:
   región UE, cifrado, backups, restauración, retención, soporte, subencargados
   y DPA.
3. Si no cumple los requisitos legales o contractuales, seleccionar otro
   proveedor UE y conservar el mismo contrato de adaptadores fail-closed.

**Evidencia:** proveedor/plan aprobado, DPA firmado, región y políticas de
retención documentadas.

### 2. Configurar identidad y MFA

1. Activar Supabase Auth u otro IdP aprobado.
2. Crear únicamente las cuentas de prueba de Gosia y un asistente autorizado.
3. Activar TOTP obligatorio para roles clínicos.
4. Probar: login `aal1` rechazado, login `aal2` aceptado, logout/revocación,
   expiración de sesión y rotación de JWKS.
5. Registrar issuer, audience y JWKS en el gestor de secretos; nunca en Git.

**Evidencia:** dos resultados de prueba, configuración MFA exportada sin
secretos, y registro de revocación/rotación.

### 3. Crear Storage clínico privado

1. Crear un bucket privado en región UE, con nombre acordado como
   `onkofizjo-clinical`.
2. Limitar tipos y tamaño de archivo.
3. Aplicar políticas por usuario, ecosistema y paciente.
4. Probar upload, download autorizado, download no autorizado, URL firmada
   con expiración, borrado mediante workflow RODO y auditoría de cada acción.
5. Usar únicamente la API de Storage soportada; no escribir directamente en
   tablas internas `storage.objects`.

**Evidencia:** bucket privado, políticas revisadas, prueba negativa y URL
temporal expirada.

### 4. Configurar backups y restore

1. Activar backups cifrados y una política de retención aprobada.
2. Definir RPO y RTO con Gosia/operaciones.
3. Ejecutar un backup de datos sintéticos.
4. Restaurarlo en un entorno aislado y verificar esquema, RLS, auditoría y
   ausencia de datos fuera de la región autorizada.
5. Limitar y auditar quién puede restaurar o descargar un backup.

**Evidencia:** ID del backup, fecha, RPO, RTO, resultado del restore y operador.

### 5. Conectar auditoría externa inmutable

1. Seleccionar un destino UE con append-only/WORM, retención y cifrado.
2. Configurar el adaptador `ExternalAuditSink` con credenciales en un gestor
   de secretos.
3. Enviar eventos de login, lectura, escritura, descarga, borrado, cambios de
   permisos y acciones de Hermes.
4. Probar reintentos, duplicados, caída del sink, recuperación e integridad de
   la cadena hash.

**Evidencia:** destino aprobado, evento recibido, prueba de inmutabilidad y
procedimiento de recuperación.

### 6. Cerrar legal y seguridad

1. Revisar DPA/RODO con asesoría polaca.
2. Aprobar retención, borrado, exportación y respuesta a incidentes.
3. Ejecutar revisión independiente de seguridad y threat model.
4. Firmar el acta de autorización de datos clínicos.

**Evidencia:** documentos firmados y lista de hallazgos cerrada o aceptada.

## Qué debe entregarse para reanudar aquí

- Nombre/ref del proveedor definitivo y plan aprobado.
- Evidencia de MFA `aal2` y revocación.
- Nombre del bucket privado y resultados de sus pruebas.
- Evidencia de backup/restore con RPO/RTO.
- Endpoint/tipo del sink externo, sin secretos.
- DPA y revisión de seguridad aprobados.

Cuando esos seis paquetes de evidencia estén disponibles, se ejecutarán los
validadores, las pruebas negativas contra staging y el arranque fail-closed.
Solo entonces se podrá cerrar la Fase 4 y abrir la Fase 5.
