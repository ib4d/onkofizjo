-- Require the same MFA assurance in PostgreSQL that the API requires.
-- The staging harness may set app.mfa_aal; production must provide the
-- verified request.jwt.claim.aal claim from the identity adapter.
BEGIN;

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

CREATE OR REPLACE FUNCTION can_access_patient(target_patient UUID) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = onkofizjo, pg_catalog AS $$
    SELECT onkofizjo.clinical_mfa_satisfied() AND (is_gosia() OR EXISTS (
        SELECT 1 FROM patient_access
        WHERE patient_id = target_patient
          AND user_id = current_user_id()
          AND revoked_at IS NULL
    ))
$$;

COMMIT;
