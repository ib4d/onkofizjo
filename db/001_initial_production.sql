-- Onkofizjo production persistence contract.
-- PostgreSQL 15+. Execute once in a private EU-hosted managed database.
-- This migration contains no demo records and must be reviewed before deployment.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS onkofizjo;
SET search_path = onkofizjo, public;

CREATE TABLE ecosystems (
    code TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO ecosystems (code, display_name) VALUES
    ('ONCOLOGY_REHAB', 'Oncology rehabilitation'),
    ('LYMPHATIC_THERAPY', 'Lymphatic therapy'),
    ('PHYSIOTHERAPY', 'Physiotherapy'),
    ('DIETETICS', 'Dietetics'),
    ('MASSAGE', 'Massage'),
    ('HOME_VISIT', 'Home visit')
ON CONFLICT (code) DO NOTHING;

CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    address TEXT,
    timezone TEXT NOT NULL DEFAULT 'Europe/Warsaw',
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE app_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_subject TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('GOSIA', 'ASSISTANT', 'COLLABORATOR', 'AI_AGENT')),
    language TEXT NOT NULL DEFAULT 'pl' CHECK (language IN ('pl', 'en')),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ
);

CREATE TABLE user_ecosystems (
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    ecosystem_code TEXT NOT NULL REFERENCES ecosystems(code),
    PRIMARY KEY (user_id, ecosystem_code)
);

CREATE TABLE user_locations (
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    location_id UUID NOT NULL REFERENCES locations(id),
    PRIMARY KEY (user_id, location_id)
);

CREATE TABLE patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    record_code TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    preferred_language TEXT NOT NULL DEFAULT 'pl' CHECK (preferred_language IN ('pl', 'en')),
    phone TEXT,
    email TEXT,
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'PAUSED', 'ARCHIVED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE patient_ecosystems (
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    ecosystem_code TEXT NOT NULL REFERENCES ecosystems(code),
    PRIMARY KEY (patient_id, ecosystem_code)
);

CREATE TABLE patient_access (
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    access_scope TEXT NOT NULL DEFAULT 'ASSIGNED' CHECK (access_scope IN ('ASSIGNED', 'READ_ONLY')),
    granted_by UUID REFERENCES app_users(id),
    granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at TIMESTAMPTZ,
    PRIMARY KEY (patient_id, user_id)
);

CREATE TABLE patient_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    consent_type TEXT NOT NULL CHECK (consent_type IN ('CARE', 'TELECONSULTATION', 'DATA_PROCESSING', 'PATIENT_COMMUNICATION', 'RECORDING')),
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'GRANTED', 'WITHDRAWN', 'EXPIRED')),
    evidence_document_id UUID,
    granted_at TIMESTAMPTZ,
    withdrawn_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id),
    ecosystem_code TEXT NOT NULL REFERENCES ecosystems(code),
    location_id UUID REFERENCES locations(id),
    service_name TEXT NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'CONFIRMED', 'TIME_BLOCKED', 'CANCELLED_BY_PATIENT', 'NO_SHOW', 'COMPLETED', 'VACATION', 'BLOCKED')),
    payment_status TEXT NOT NULL DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'PAID', 'REFUNDED', 'WAIVED')),
    created_by UUID NOT NULL REFERENCES app_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (ends_at > starts_at)
);

CREATE TABLE clinical_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id),
    appointment_id UUID REFERENCES appointments(id),
    author_user_id UUID NOT NULL REFERENCES app_users(id),
    note_type TEXT NOT NULL DEFAULT 'VISIT_NOTE',
    status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SIGNED', 'AMENDED', 'VOID')),
    observation JSONB NOT NULL DEFAULT '{}'::jsonb,
    assessment TEXT,
    plan TEXT,
    human_review_required BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    signed_at TIMESTAMPTZ,
    signed_by UUID REFERENCES app_users(id)
);

CREATE OR REPLACE FUNCTION validate_note_appointment_patient() RETURNS TRIGGER
LANGUAGE plpgsql SET search_path = onkofizjo, pg_catalog AS $$
DECLARE
    appointment_patient UUID;
BEGIN
    IF NEW.appointment_id IS NOT NULL THEN
        SELECT patient_id INTO appointment_patient FROM appointments WHERE id = NEW.appointment_id;
        IF appointment_patient IS NULL OR appointment_patient <> NEW.patient_id THEN
            RAISE EXCEPTION 'clinical note appointment does not belong to patient';
        END IF;
    END IF;
    RETURN NEW;
END
$$;

CREATE TRIGGER clinical_notes_patient_match
BEFORE INSERT OR UPDATE ON clinical_notes
FOR EACH ROW EXECUTE FUNCTION validate_note_appointment_patient();

CREATE TABLE diet_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id),
    language TEXT NOT NULL DEFAULT 'pl' CHECK (language IN ('pl', 'en')),
    status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'ASSISTANT_PROPOSED', 'REVIEWED', 'APPROVED', 'SENT', 'ARCHIVED')),
    created_by UUID NOT NULL REFERENCES app_users(id),
    approved_by UUID REFERENCES app_users(id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE diet_plan_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    diet_plan_id UUID NOT NULL REFERENCES diet_plans(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL CHECK (version_number > 0),
    constraints JSONB NOT NULL DEFAULT '{}'::jsonb,
    strategy JSONB NOT NULL DEFAULT '{}'::jsonb,
    meals JSONB NOT NULL DEFAULT '[]'::jsonb,
    nutrition_totals JSONB NOT NULL DEFAULT '{}'::jsonb,
    sources JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_by UUID NOT NULL REFERENCES app_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (diet_plan_id, version_number)
);

CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id),
    appointment_id UUID REFERENCES appointments(id),
    document_type TEXT NOT NULL,
    language TEXT NOT NULL DEFAULT 'pl' CHECK (language IN ('pl', 'en')),
    storage_key TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'REVIEW', 'APPROVED', 'DELIVERED', 'REVOKED')),
    created_by UUID NOT NULL REFERENCES app_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    delivered_at TIMESTAMPTZ
);

ALTER TABLE patient_consents
    ADD CONSTRAINT patient_consents_evidence_document_fk
    FOREIGN KEY (evidence_document_id) REFERENCES documents(id);

CREATE TABLE teleconsultations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id),
    appointment_id UUID REFERENCES appointments(id),
    mode TEXT NOT NULL CHECK (mode IN ('VIDEO', 'PHONE')),
    provider TEXT,
    external_session_id TEXT,
    status TEXT NOT NULL DEFAULT 'CREATED' CHECK (status IN ('CREATED', 'READY', 'INITIATED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'FAILED')),
    consent_required BOOLEAN NOT NULL DEFAULT TRUE,
    recording_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    created_by UUID NOT NULL REFERENCES app_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL REFERENCES appointments(id),
    amount_minor INTEGER NOT NULL CHECK (amount_minor >= 0),
    currency TEXT NOT NULL DEFAULT 'PLN' CHECK (currency = 'PLN'),
    method TEXT,
    external_reference TEXT,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PAID', 'REFUNDED', 'VOID')),
    settled_at TIMESTAMPTZ,
    created_by UUID NOT NULL REFERENCES app_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE knowledge_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kind TEXT NOT NULL CHECK (kind IN ('GOSIA_RULE', 'RECIPE', 'PROTOCOL', 'EXTERNAL_EVIDENCE', 'BLOG_CONTENT')),
    title TEXT NOT NULL,
    area TEXT NOT NULL,
    content TEXT NOT NULL,
    source_url TEXT,
    source_title TEXT,
    source_published_at DATE,
    review_status TEXT NOT NULL DEFAULT 'PENDING' CHECK (review_status IN ('PENDING', 'APPROVED_INTERNAL', 'REJECTED', 'EXPIRED')),
    reviewed_by UUID REFERENCES app_users(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE assistant_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID REFERENCES patients(id),
    requested_by UUID NOT NULL REFERENCES app_users(id),
    agent_name TEXT NOT NULL,
    task TEXT NOT NULL,
    input_references JSONB NOT NULL DEFAULT '[]'::jsonb,
    output JSONB NOT NULL DEFAULT '{}'::jsonb,
    citations JSONB NOT NULL DEFAULT '[]'::jsonb,
    confidence NUMERIC(4,3) CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 1)),
    status TEXT NOT NULL DEFAULT 'NEEDS_REVIEW' CHECK (status IN ('RUNNING', 'NEEDS_REVIEW', 'APPROVED', 'REJECTED', 'FAILED')),
    human_approved_by UUID REFERENCES app_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE audit_events (
    sequence BIGSERIAL PRIMARY KEY,
    actor_user_id UUID REFERENCES app_users(id),
    actor_role TEXT NOT NULL,
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id TEXT,
    patient_id UUID REFERENCES patients(id),
    correlation_id UUID,
    reason TEXT,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    prev_hash TEXT NOT NULL,
    event_hash TEXT NOT NULL UNIQUE
);

CREATE INDEX patients_name_idx ON patients (lower(full_name));
CREATE INDEX appointments_schedule_idx ON appointments (starts_at, status);
CREATE INDEX appointments_patient_idx ON appointments (patient_id, starts_at DESC);
CREATE INDEX appointments_created_by_idx ON appointments (created_by);
CREATE INDEX appointments_ecosystem_idx ON appointments (ecosystem_code);
CREATE INDEX appointments_location_idx ON appointments (location_id);
CREATE INDEX clinical_notes_patient_idx ON clinical_notes (patient_id, created_at DESC);
CREATE INDEX clinical_notes_appointment_idx ON clinical_notes (appointment_id);
CREATE INDEX clinical_notes_author_idx ON clinical_notes (author_user_id);
CREATE INDEX clinical_notes_signed_by_idx ON clinical_notes (signed_by);
CREATE INDEX diet_plans_patient_idx ON diet_plans (patient_id, updated_at DESC);
CREATE INDEX diet_plans_created_by_idx ON diet_plans (created_by);
CREATE INDEX diet_plans_approved_by_idx ON diet_plans (approved_by);
CREATE INDEX diet_plan_versions_created_by_idx ON diet_plan_versions (created_by);
CREATE INDEX documents_patient_idx ON documents (patient_id, created_at DESC);
CREATE INDEX documents_appointment_idx ON documents (appointment_id);
CREATE INDEX documents_created_by_idx ON documents (created_by);
CREATE INDEX teleconsultations_patient_idx ON teleconsultations (patient_id, created_at DESC);
CREATE INDEX teleconsultations_appointment_idx ON teleconsultations (appointment_id);
CREATE INDEX teleconsultations_created_by_idx ON teleconsultations (created_by);
CREATE INDEX assistant_runs_patient_idx ON assistant_runs (patient_id, created_at DESC);
CREATE INDEX assistant_runs_requested_by_idx ON assistant_runs (requested_by);
CREATE INDEX assistant_runs_human_approved_by_idx ON assistant_runs (human_approved_by);
CREATE INDEX audit_patient_idx ON audit_events (patient_id, sequence DESC);
CREATE INDEX audit_events_actor_user_idx ON audit_events (actor_user_id);
CREATE INDEX patient_access_user_idx ON patient_access (user_id);
CREATE INDEX patient_access_granted_by_idx ON patient_access (granted_by);
CREATE INDEX patient_consents_patient_idx ON patient_consents (patient_id);
CREATE INDEX patient_consents_evidence_document_idx ON patient_consents (evidence_document_id);
CREATE INDEX patient_ecosystems_ecosystem_idx ON patient_ecosystems (ecosystem_code);
CREATE INDEX payments_appointment_idx ON payments (appointment_id);
CREATE INDEX payments_created_by_idx ON payments (created_by);
CREATE INDEX knowledge_items_reviewed_by_idx ON knowledge_items (reviewed_by);
CREATE INDEX user_ecosystems_ecosystem_idx ON user_ecosystems (ecosystem_code);
CREATE INDEX user_locations_location_idx ON user_locations (location_id);

CREATE OR REPLACE FUNCTION current_subject() RETURNS TEXT
LANGUAGE sql STABLE SET search_path = pg_catalog AS $$
    SELECT COALESCE(
        NULLIF(current_setting('request.jwt.claim.sub', TRUE), ''),
        NULLIF(current_setting('app.user_subject', TRUE), '')
    )
$$;

CREATE OR REPLACE FUNCTION onkofizjo.clinical_mfa_satisfied() RETURNS BOOLEAN
LANGUAGE sql STABLE SET search_path = pg_catalog AS $$
    SELECT COALESCE(
        NULLIF(current_setting('request.jwt.claim.aal', TRUE), ''),
        NULLIF(current_setting('app.mfa_aal', TRUE), '')
    ) = 'aal2'
$$;

CREATE OR REPLACE FUNCTION current_user_id() RETURNS UUID
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = onkofizjo, pg_catalog AS $$
    SELECT id FROM app_users
    WHERE onkofizjo.clinical_mfa_satisfied()
      AND external_subject = current_subject()
      AND active = TRUE
    LIMIT 1
$$;

CREATE OR REPLACE FUNCTION current_role_code() RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = onkofizjo, pg_catalog AS $$
    SELECT role FROM app_users WHERE id = current_user_id() AND active = TRUE LIMIT 1
$$;

CREATE OR REPLACE FUNCTION is_gosia() RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = onkofizjo, pg_catalog AS $$
    SELECT onkofizjo.current_role_code() = 'GOSIA'
$$;

CREATE OR REPLACE FUNCTION can_access_patient(target_patient UUID) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = onkofizjo, pg_catalog AS $$
    SELECT onkofizjo.clinical_mfa_satisfied() AND (is_gosia() OR EXISTS (
        SELECT 1 FROM patient_access
        WHERE patient_id = target_patient
          AND user_id = current_user_id()
          AND revoked_at IS NULL
    ))
$$;

REVOKE EXECUTE ON FUNCTION current_user_id() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION can_access_patient(UUID) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION set_audit_hash() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = onkofizjo, public AS $$
DECLARE
    previous_hash TEXT;
BEGIN
    PERFORM pg_advisory_xact_lock(744912);
    SELECT event_hash INTO previous_hash FROM audit_events ORDER BY sequence DESC LIMIT 1;
    NEW.prev_hash := COALESCE(previous_hash, 'GENESIS');
    NEW.event_hash := encode(digest(
        concat_ws('|', NEW.prev_hash, NEW.created_at::TEXT, NEW.actor_user_id::TEXT,
                  NEW.actor_role, NEW.action, NEW.resource_type, NEW.resource_id,
                  NEW.patient_id::TEXT, NEW.correlation_id::TEXT, NEW.reason,
                  NEW.payload::TEXT), 'sha256'), 'hex');
    RETURN NEW;
END
$$;

CREATE TRIGGER audit_events_hash_before_insert
BEFORE INSERT ON audit_events
FOR EACH ROW EXECUTE FUNCTION set_audit_hash();

CREATE OR REPLACE FUNCTION prevent_audit_mutation() RETURNS TRIGGER
LANGUAGE plpgsql SET search_path = onkofizjo, pg_catalog AS $$
BEGIN
    RAISE EXCEPTION 'audit_events is append-only';
END
$$;

CREATE TRIGGER audit_events_no_update
BEFORE UPDATE ON audit_events
FOR EACH ROW EXECUTE FUNCTION prevent_audit_mutation();

CREATE TRIGGER audit_events_no_delete
BEFORE DELETE ON audit_events
FOR EACH ROW EXECUTE FUNCTION prevent_audit_mutation();

ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecosystems ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_ecosystems ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ecosystems ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE diet_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE diet_plan_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE teleconsultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE assistant_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY patients_select ON patients FOR SELECT USING (can_access_patient(id));
CREATE POLICY patients_gosia_insert ON patients FOR INSERT WITH CHECK (is_gosia());
CREATE POLICY patients_gosia_update ON patients FOR UPDATE USING (is_gosia()) WITH CHECK (is_gosia());

CREATE POLICY ecosystems_read ON ecosystems FOR SELECT USING (
    current_role_code() IN ('GOSIA', 'ASSISTANT', 'COLLABORATOR', 'AI_AGENT')
);
CREATE POLICY locations_read ON locations FOR SELECT USING (
    is_gosia() OR EXISTS (
        SELECT 1 FROM user_locations
        WHERE user_locations.location_id = locations.id
          AND user_locations.user_id = current_user_id()
    )
);

CREATE POLICY app_users_self_or_gosia ON app_users FOR SELECT USING (id = current_user_id() OR is_gosia());
CREATE POLICY user_ecosystems_self_or_gosia ON user_ecosystems FOR SELECT USING (user_id = current_user_id() OR is_gosia());
CREATE POLICY user_locations_self_or_gosia ON user_locations FOR SELECT USING (user_id = current_user_id() OR is_gosia());

CREATE POLICY patient_ecosystems_access ON patient_ecosystems FOR SELECT USING (can_access_patient(patient_id));
CREATE POLICY patient_ecosystems_gosia_insert ON patient_ecosystems FOR INSERT WITH CHECK (is_gosia());
CREATE POLICY patient_ecosystems_gosia_update ON patient_ecosystems FOR UPDATE USING (is_gosia()) WITH CHECK (is_gosia());

CREATE POLICY patient_access_gosia_insert ON patient_access FOR INSERT WITH CHECK (is_gosia());
CREATE POLICY patient_access_gosia_update ON patient_access FOR UPDATE USING (is_gosia()) WITH CHECK (is_gosia());
CREATE POLICY patient_access_self_read ON patient_access FOR SELECT USING (user_id = current_user_id());

CREATE POLICY patient_consents_access ON patient_consents FOR SELECT USING (can_access_patient(patient_id));
CREATE POLICY patient_consents_gosia_insert ON patient_consents FOR INSERT WITH CHECK (is_gosia());
CREATE POLICY patient_consents_gosia_update ON patient_consents FOR UPDATE USING (is_gosia()) WITH CHECK (is_gosia());

CREATE POLICY appointments_access ON appointments FOR SELECT USING (can_access_patient(patient_id));
CREATE POLICY appointments_gosia_write ON appointments FOR INSERT WITH CHECK (is_gosia() AND created_by = current_user_id());
CREATE POLICY appointments_gosia_update ON appointments FOR UPDATE USING (is_gosia()) WITH CHECK (is_gosia());

CREATE POLICY clinical_notes_access ON clinical_notes FOR SELECT USING (can_access_patient(patient_id));
CREATE POLICY clinical_notes_create ON clinical_notes FOR INSERT WITH CHECK (can_access_patient(patient_id) AND author_user_id = current_user_id());
CREATE POLICY clinical_notes_gosia_update ON clinical_notes FOR UPDATE USING (is_gosia()) WITH CHECK (is_gosia());

CREATE POLICY diet_plans_access ON diet_plans FOR SELECT USING (can_access_patient(patient_id));
CREATE POLICY diet_plans_create ON diet_plans FOR INSERT WITH CHECK (can_access_patient(patient_id) AND created_by = current_user_id());
CREATE POLICY diet_plans_gosia_update ON diet_plans FOR UPDATE USING (is_gosia()) WITH CHECK (is_gosia());
CREATE POLICY diet_versions_access ON diet_plan_versions FOR SELECT USING (EXISTS (SELECT 1 FROM diet_plans WHERE diet_plans.id = diet_plan_id AND can_access_patient(diet_plans.patient_id)));
CREATE POLICY diet_versions_create ON diet_plan_versions FOR INSERT WITH CHECK (created_by = current_user_id() AND EXISTS (SELECT 1 FROM diet_plans WHERE diet_plans.id = diet_plan_id AND can_access_patient(diet_plans.patient_id)));

CREATE POLICY documents_access ON documents FOR SELECT USING (can_access_patient(patient_id));
CREATE POLICY documents_gosia_insert ON documents FOR INSERT WITH CHECK (is_gosia() AND created_by = current_user_id());
CREATE POLICY documents_gosia_update ON documents FOR UPDATE USING (is_gosia()) WITH CHECK (is_gosia());

CREATE POLICY teleconsultations_access ON teleconsultations FOR SELECT USING (can_access_patient(patient_id));
CREATE POLICY teleconsultations_create ON teleconsultations FOR INSERT WITH CHECK (can_access_patient(patient_id) AND created_by = current_user_id());
CREATE POLICY teleconsultations_gosia_update ON teleconsultations FOR UPDATE USING (is_gosia()) WITH CHECK (is_gosia());

CREATE POLICY payments_access ON payments FOR SELECT USING (can_access_patient((SELECT patient_id FROM appointments WHERE appointments.id = appointment_id)));
CREATE POLICY payments_gosia_insert ON payments FOR INSERT WITH CHECK (is_gosia() AND created_by = current_user_id());
CREATE POLICY payments_gosia_update ON payments FOR UPDATE USING (is_gosia()) WITH CHECK (is_gosia());

CREATE POLICY knowledge_items_read ON knowledge_items FOR SELECT USING (
    current_role_code() IN ('GOSIA', 'ASSISTANT', 'COLLABORATOR', 'AI_AGENT')
    AND (review_status = 'APPROVED_INTERNAL' OR current_role_code() = 'GOSIA')
);
CREATE POLICY knowledge_items_gosia_insert ON knowledge_items FOR INSERT WITH CHECK (is_gosia());
CREATE POLICY knowledge_items_gosia_update ON knowledge_items FOR UPDATE USING (is_gosia()) WITH CHECK (is_gosia());

CREATE POLICY assistant_runs_access ON assistant_runs FOR SELECT USING (patient_id IS NULL OR can_access_patient(patient_id));
CREATE POLICY assistant_runs_create ON assistant_runs FOR INSERT WITH CHECK (requested_by = current_user_id() AND (patient_id IS NULL OR can_access_patient(patient_id)));
CREATE POLICY assistant_runs_gosia_review ON assistant_runs FOR UPDATE USING (is_gosia()) WITH CHECK (is_gosia());

CREATE POLICY audit_events_gosia_read ON audit_events FOR SELECT USING (is_gosia());
CREATE POLICY audit_events_insert ON audit_events FOR INSERT WITH CHECK (actor_user_id = current_user_id() AND actor_role = current_role_code());

COMMIT;
