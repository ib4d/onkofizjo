-- These authorization helpers are used by RLS, not exposed as public RPCs.
BEGIN;

REVOKE EXECUTE ON FUNCTION public.current_user_id() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.can_access_patient(UUID) FROM PUBLIC, anon, authenticated;

COMMIT;
