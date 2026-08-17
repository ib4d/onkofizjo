# Onkofizjo · checklist de publicación pública

## Antes de publicar

- [ ] Confirmar el dominio definitivo y sustituir `reha.mp` en canonical,
      hreflang, sitemap y robots.
- [ ] Verificar HTTPS, redirección única y certificado renovable.
- [ ] Revisar el copy PL y EN con Gosia y validar que no hace promesas clínicas
      no demostradas.
- [ ] Confirmar que CRM, API, pacientes y documentos siguen bloqueados para
      robots y no aparecen en sitemap.
- [ ] Configurar Search Console/Bing Webmaster con el dominio definitivo.
- [ ] Activar analítica únicamente después de consentimiento válido; no enviar
      nombres, IDs, notas ni datos de salud a herramientas de marketing.
- [ ] Ejecutar `phase8-smoke.ps1` y `web-smoke.ps1` contra el artefacto de
      release, no contra archivos de desarrollo.

## Criterio de salida

La publicación pública solo se considera lista cuando existe evidencia fechada
para cada casilla y el dominio canónico definitivo coincide en la web, sitemap,
robots y Search Console. Esta checklist no autoriza datos clínicos ni sustituye
las puertas de Fase 4.

La puerta automatizada `release-gate.ps1` debe pasar después de sustituir el
dominio provisional; mientras tanto, su fallo es intencional y seguro.
