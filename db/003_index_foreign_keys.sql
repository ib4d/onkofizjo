-- Add covering indexes for clinical foreign keys flagged by the managed
-- database advisor. No patient data is touched by this migration.
BEGIN;

SET search_path = onkofizjo, public;

CREATE INDEX appointments_created_by_idx ON appointments (created_by);
CREATE INDEX appointments_ecosystem_idx ON appointments (ecosystem_code);
CREATE INDEX appointments_location_idx ON appointments (location_id);
CREATE INDEX assistant_runs_human_approved_by_idx ON assistant_runs (human_approved_by);
CREATE INDEX assistant_runs_requested_by_idx ON assistant_runs (requested_by);
CREATE INDEX audit_events_actor_user_idx ON audit_events (actor_user_id);
CREATE INDEX clinical_notes_appointment_idx ON clinical_notes (appointment_id);
CREATE INDEX clinical_notes_author_idx ON clinical_notes (author_user_id);
CREATE INDEX clinical_notes_signed_by_idx ON clinical_notes (signed_by);
CREATE INDEX diet_plan_versions_created_by_idx ON diet_plan_versions (created_by);
CREATE INDEX diet_plans_approved_by_idx ON diet_plans (approved_by);
CREATE INDEX diet_plans_created_by_idx ON diet_plans (created_by);
CREATE INDEX documents_appointment_idx ON documents (appointment_id);
CREATE INDEX documents_created_by_idx ON documents (created_by);
CREATE INDEX knowledge_items_reviewed_by_idx ON knowledge_items (reviewed_by);
CREATE INDEX patient_access_granted_by_idx ON patient_access (granted_by);
CREATE INDEX patient_access_user_idx ON patient_access (user_id);
CREATE INDEX patient_consents_evidence_document_idx ON patient_consents (evidence_document_id);
CREATE INDEX patient_consents_patient_idx ON patient_consents (patient_id);
CREATE INDEX patient_ecosystems_ecosystem_idx ON patient_ecosystems (ecosystem_code);
CREATE INDEX payments_appointment_idx ON payments (appointment_id);
CREATE INDEX payments_created_by_idx ON payments (created_by);
CREATE INDEX teleconsultations_appointment_idx ON teleconsultations (appointment_id);
CREATE INDEX teleconsultations_created_by_idx ON teleconsultations (created_by);
CREATE INDEX user_ecosystems_ecosystem_idx ON user_ecosystems (ecosystem_code);
CREATE INDEX user_locations_location_idx ON user_locations (location_id);

COMMIT;
