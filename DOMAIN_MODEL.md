# onkofizjo domain model

The Stitch screens share these production entities. The demo records are synthetic and must never be replaced with real patient data in the repository.

## Core entities

- `User`: Gosia, assistants and collaborators; role, language, allowed ecosystems and locations.
- `Patient`: identity, contact, language, consents, care ecosystems and clinical modules.
- `Appointment`: patient, ecosystem, location, service, start/end, status, payment and required documents.
- `ClinicalNote`: author, appointment, structured observations, recommendations and audit metadata.
- `DietPlan`: patient, constraints, strategy, meals, nutrition totals, sources, status and versions.
- `Document`: template, patient, language, generated file, consent relation and delivery status.
- `KnowledgeItem`: Gosia rule, recipe, protocol, external evidence or blog content; source and review state.
- `AssistantRun`: agent, input references, output, citations, confidence, approval state and audit events.
- `Payment`: appointment, amount, receipt/invoice, method and settlement period.

## Care ecosystem values

`ONCOLOGY_REHAB`, `LYMPHATIC_THERAPY`, `PHYSIOTHERAPY`, `DIETETICS`, `MASSAGE`, `HOME_VISIT`.

## Appointment status values

`SCHEDULED`, `CONFIRMED`, `TIME_BLOCKED`, `CANCELLED_BY_PATIENT`, `NO_SHOW`, `COMPLETED`, `VACATION`, `BLOCKED`.

## Diet plan status values

`DRAFT`, `ASSISTANT_PROPOSED`, `REVIEWED`, `APPROVED`, `SENT`, `ARCHIVED`.

## Safety boundary

The assistant may create proposals and summaries. It may not approve a diet, change a clinical record, send patient-facing clinical guidance or expose a source-less claim without explicit permission and an auditable human approval step.
