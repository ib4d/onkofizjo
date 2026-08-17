-- Harden functions after the initial production schema was provisioned.
-- No patient data is touched by this migration.
BEGIN;

SET search_path = onkofizjo, public;

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

CREATE OR REPLACE FUNCTION current_subject() RETURNS TEXT
LANGUAGE sql STABLE SET search_path = pg_catalog AS $$
    SELECT COALESCE(
        NULLIF(current_setting('request.jwt.claim.sub', TRUE), ''),
        NULLIF(current_setting('app.user_subject', TRUE), '')
    )
$$;

CREATE OR REPLACE FUNCTION prevent_audit_mutation() RETURNS TRIGGER
LANGUAGE plpgsql SET search_path = onkofizjo, pg_catalog AS $$
BEGIN
    RAISE EXCEPTION 'audit_events is append-only';
END
$$;

COMMIT;
