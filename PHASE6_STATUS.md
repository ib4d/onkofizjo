# Onkofizjo · Fase 6

## Alcance actual

Fase 6 se ejecuta con datos sintéticos y sin llamadas a un LLM externo. Hermes
solo puede producir un borrador cuando encuentra una fuente interna aprobada;
si la fuente falta o requiere revisión, devuelve `REVIEW_REQUIRED` y no genera
conclusiones clínicas.

## Subfases

- **6.1 Grounding y fuentes:** implementada en `api/assistant_engine.py` con
  registro de fuentes, filtrado por `APPROVED_INTERNAL` y `sourceTrace`.
- **6.2 Guardrails de evidencia:** implementada; cada ejecución conserva
  `noInferenceWithoutEvidence`, confianza acotada y revisión humana obligatoria.
- **6.3 Trazabilidad:** implementada; cada ejecución se audita mediante
  `CREATE_ASSISTANT_RUN` y devuelve las fuentes encontradas y solicitadas.
- **6.4 Permisos y producción:** pendiente; requiere políticas productivas de
  identidad, proveedor LLM autorizado, RAG con fuentes científicas verificadas,
  retención y revisión jurídica de Fase 4.

## Frontera honesta

Esto es un motor grounded determinista para validar el workflow. No es todavía
un LLM conectado ni una autorización para usar datos clínicos reales.
