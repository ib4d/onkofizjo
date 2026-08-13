# Stitch to production implementation map

This file turns the approved Stitch prototype into buildable product slices.

| Stitch screen | Production route | First implementation requirement |
|---|---|---|
| marketing_home_desktop | `/` | CMS-backed Polish/English marketing home with telephone CTA |
| nasze_us_ugi_onkofizjo | `/uslugi` | Service catalogue grouped by care ecosystem |
| lokalizacje_i_kontakt | `/lokalizacje` | Location cards, phone links and directions |
| logowanie_do_systemu | `/login` | Authenticated CRM entry with MFA-ready session model |
| crm_dashboard_desktop | `/crm` | Today view, next appointment, tasks and Hermes suggestions |
| crm_mobile_home | `/crm` mobile | Bottom navigation and one-handed quick actions |
| patient_profile_desktop | `/crm/patients/:id` | Modular patient record with role-aware clinical sections |
| dokumentacja_mobilna | `/crm/patients/:id/notes` | Fast visit note, status, documents and voice-note placeholder |
| generador_de_dietas_desktop | `/crm/diet-plans/new` | Guided builder with warnings, sources and approval state |
| generator_pdf_plan_ywieniowy | `/crm/diet-plans/:id/preview` | Versioned patient-facing plan preview/export |
| przestrze_ai_hermes | `/crm/ai` | Source-backed assistant workspace with review gates |
| centrum_dokumentacji | `/crm/documents` | Templates, consent status, generated files and audit trail |
| baza_wiedzy_i_blog | `/crm/knowledge` and `/blog` | Separate Gosia knowledge from external evidence |

## Implementation order

1. Shared shell, routing and responsive navigation.
2. Auth boundary and demo-safe seeded data.
3. Today dashboard and calendar ecosystem filters.
4. Patient profile and visit documentation.
5. Diet-plan builder and version states.
6. Documents and PDF preview.
7. Hermes workspace with read-only mocked evidence cards.
8. Persistence, permissions, audit events and real integrations.

## Non-negotiable production boundaries

- Marketing never writes clinical data.
- Demo data is visibly marked and never mixed with production records.
- AI suggestions are drafts until Gosia approves them.
- Every clinical suggestion exposes its source and uncertainty.
- Public pages do not collect booking requests or medical intake data.
