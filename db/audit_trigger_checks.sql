-- Runtime checks for append-only audit triggers. Run as the migration/admin role
-- in disposable staging only. Every write is rolled back.

\set ON_ERROR_STOP on
BEGIN;
SET LOCAL app.user_subject = 'staging-gosia';

INSERT INTO onkofizjo.audit_events (
    actor_user_id, actor_role, action, resource_type, resource_id,
    patient_id, reason, payload
)
VALUES (
    '10000000-0000-4000-8000-000000000001', 'GOSIA',
    'AUDIT_TRIGGER_CHECK', 'TEST', 'rollback-check',
    '30000000-0000-4000-8000-000000000001',
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
        RAISE EXCEPTION 'audit update trigger did not reject mutation';
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
        RAISE EXCEPTION 'audit delete trigger did not reject mutation';
    END IF;
END
$$;

ROLLBACK;
\echo 'PASS: audit update/delete triggers rejected mutation.'
