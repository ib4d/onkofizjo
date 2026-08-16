-- Synthetic-only fixtures for local staging. Never use these identifiers for care.

SET search_path = onkofizjo, public;

INSERT INTO app_users (id, external_subject, display_name, role, language)
VALUES
    ('10000000-0000-4000-8000-000000000001', 'staging-gosia', 'Gosia staging', 'GOSIA', 'pl'),
    ('10000000-0000-4000-8000-000000000002', 'staging-collaborator-a', 'Collaborator A staging', 'COLLABORATOR', 'pl'),
    ('10000000-0000-4000-8000-000000000003', 'staging-collaborator-b', 'Collaborator B staging', 'COLLABORATOR', 'pl')
ON CONFLICT (id) DO UPDATE SET external_subject = EXCLUDED.external_subject, role = EXCLUDED.role, active = TRUE;

INSERT INTO locations (id, code, display_name)
VALUES ('20000000-0000-4000-8000-000000000001', 'STAGING_CLINIC', 'Synthetic staging clinic')
ON CONFLICT (id) DO NOTHING;

INSERT INTO patients (id, record_code, full_name, preferred_language)
VALUES
    ('30000000-0000-4000-8000-000000000001', 'STAGING-PATIENT-A', 'Patient A staging', 'pl'),
    ('30000000-0000-4000-8000-000000000002', 'STAGING-PATIENT-B', 'Patient B staging', 'en')
ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, status = 'ACTIVE';

INSERT INTO patient_ecosystems (patient_id, ecosystem_code)
VALUES
    ('30000000-0000-4000-8000-000000000001', 'PHYSIOTHERAPY'),
    ('30000000-0000-4000-8000-000000000002', 'DIETETICS')
ON CONFLICT DO NOTHING;

INSERT INTO patient_access (patient_id, user_id, access_scope, granted_by)
VALUES
    ('30000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'ASSIGNED', '10000000-0000-4000-8000-000000000001'),
    ('30000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000003', 'ASSIGNED', '10000000-0000-4000-8000-000000000001')
ON CONFLICT (patient_id, user_id) DO UPDATE SET revoked_at = NULL, access_scope = EXCLUDED.access_scope;

INSERT INTO appointments (id, patient_id, ecosystem_code, location_id, service_name, starts_at, ends_at, created_by)
VALUES (
    '40000000-0000-4000-8000-000000000001',
    '30000000-0000-4000-8000-000000000001',
    'PHYSIOTHERAPY',
    '20000000-0000-4000-8000-000000000001',
    'Synthetic staging appointment',
    '2030-01-01T10:00:00+01:00',
    '2030-01-01T10:45:00+01:00',
    '10000000-0000-4000-8000-000000000001'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO diet_plans (id, patient_id, language, status, created_by)
VALUES (
    '50000000-0000-4000-8000-000000000001',
    '30000000-0000-4000-8000-000000000001',
    'pl', 'DRAFT', '10000000-0000-4000-8000-000000000001'
)
ON CONFLICT (id) DO UPDATE SET status = 'DRAFT';
