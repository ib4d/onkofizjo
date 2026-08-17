-- Protect reference tables in the private application schema as well.
-- No patient data is touched by this migration.
BEGIN;

SET search_path = onkofizjo, public;

ALTER TABLE ecosystems ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

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

COMMIT;
