-- Staging-only RLS and integrity checks.
-- Run with psql as the application database role, not the migration owner:
--
-- psql "$ONKOFIZJO_STAGING_DATABASE_URL" \
--   -v subject_gosia="..." \
--   -v subject_collaborator_a="..." \
--   -v patient_a="..." -v patient_b="..." \
--   -v diet_plan_id="..." \
--   -f db/staging_rls_checks.sql
--
-- All writes happen inside one transaction and are rolled back at the end.
-- Fixtures must be synthetic and must already exist in the staging database.

\set ON_ERROR_STOP on

BEGIN;

SET LOCAL onkofizjo.test_patient_a = :'patient_a';
SET LOCAL onkofizjo.test_patient_b = :'patient_b';
SET LOCAL onkofizjo.test_diet_plan = :'diet_plan_id';

SET LOCAL app.user_subject = :'subject_collaborator_a';

DO $$
DECLARE
    visible_count INTEGER;
BEGIN
    SELECT count(*) INTO visible_count
    FROM onkofizjo.patients
    WHERE id IN (
        current_setting('onkofizjo.test_patient_a')::uuid,
        current_setting('onkofizjo.test_patient_b')::uuid
    );
    IF visible_count <> 1 THEN
        RAISE EXCEPTION 'collaborator should see exactly one assigned patient, saw %', visible_count;
    END IF;
END
$$;

DO $$
DECLARE
    succeeded BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO onkofizjo.clinical_notes (patient_id, author_user_id, observation)
        VALUES (
            current_setting('onkofizjo.test_patient_b')::uuid,
            onkofizjo.current_user_id(),
            '{}'::jsonb
        );
        succeeded := TRUE;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
    IF succeeded THEN
        RAISE EXCEPTION 'cross-patient clinical note insert unexpectedly succeeded';
    END IF;
END
$$;

DO $$
DECLARE
    succeeded BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO onkofizjo.teleconsultations (patient_id, mode, created_by)
        VALUES (
            current_setting('onkofizjo.test_patient_b')::uuid,
            'PHONE',
            onkofizjo.current_user_id()
        );
        succeeded := TRUE;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
    IF succeeded THEN
        RAISE EXCEPTION 'cross-patient teleconsultation insert unexpectedly succeeded';
    END IF;
END
$$;

DO $$
DECLARE
    changed INTEGER;
BEGIN
    UPDATE onkofizjo.diet_plans
    SET status = 'APPROVED'
    WHERE id = current_setting('onkofizjo.test_diet_plan')::uuid;
    GET DIAGNOSTICS changed = ROW_COUNT;
    IF changed <> 0 THEN
        RAISE EXCEPTION 'non-Gosia diet approval unexpectedly changed % row(s)', changed;
    END IF;
END
$$;

SET LOCAL app.user_subject = :'subject_gosia';

DO $$
DECLARE
    visible_count INTEGER;
BEGIN
    SELECT count(*) INTO visible_count
    FROM onkofizjo.patients
    WHERE id IN (
        current_setting('onkofizjo.test_patient_a')::uuid,
        current_setting('onkofizjo.test_patient_b')::uuid
    );
    IF visible_count <> 2 THEN
        RAISE EXCEPTION 'Gosia should see both fixture patients, saw %', visible_count;
    END IF;
END
$$;

INSERT INTO onkofizjo.audit_events (
    actor_user_id, actor_role, action, resource_type, resource_id,
    patient_id, reason, payload
)
VALUES (
    onkofizjo.current_user_id(), onkofizjo.current_role_code(),
    'STAGING_RLS_CHECK', 'TEST', 'rollback-check',
    current_setting('onkofizjo.test_patient_a')::uuid,
    'synthetic staging verification', '{}'::jsonb
)
RETURNING sequence \gset audit_

SELECT set_config('onkofizjo.test_audit_sequence', :'audit_sequence', TRUE);

DO $$
DECLARE
    succeeded BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE onkofizjo.audit_events
        SET reason = 'tamper attempt'
        WHERE sequence = current_setting('onkofizjo.test_audit_sequence')::bigint;
        succeeded := TRUE;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
    IF succeeded THEN
        RAISE EXCEPTION 'audit update unexpectedly succeeded';
    END IF;
END
$$;

DO $$
DECLARE
    succeeded BOOLEAN := FALSE;
BEGIN
    BEGIN
        DELETE FROM onkofizjo.audit_events
        WHERE sequence = current_setting('onkofizjo.test_audit_sequence')::bigint;
        succeeded := TRUE;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
    IF succeeded THEN
        RAISE EXCEPTION 'audit delete unexpectedly succeeded';
    END IF;
END
$$;

SELECT CASE
    WHEN prev_hash IS NOT NULL AND event_hash IS NOT NULL
    THEN 'PASS: audit event was hash chained'
    ELSE 'FAIL: audit event hash missing'
END AS audit_hash_check
FROM onkofizjo.audit_events
WHERE sequence = current_setting('onkofizjo.test_audit_sequence')::bigint;

ROLLBACK;

\echo 'PASS: staging RLS checks completed and synthetic writes were rolled back.'
