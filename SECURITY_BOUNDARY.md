# Onkofizjo security boundary

## Current development guarantees

- The API declares `demo: true` and `dataMode: synthetic-only`.
- Clinical reads and writes require a verified development session.
- The effective role comes from the server-side session, never from a client-supplied role alone.
- Patient and appointment references are validated before clinical writes.
- Audit events are stored locally with a chained `prevHash`/`eventHash` integrity signal.
- The local web server sends `no-store`, `nosniff`, `same-origin` referrer, and camera/microphone policy headers.

## Explicit non-production limits

The current session tokens are in-memory demo tokens, the browser bridge contains demo credentials, the audit database is local SQLite, and the clinical seed files are plain JSON. This implementation must not receive real patient data.

## Production gates

Before production deployment, all items below are mandatory:

1. Replace the demo session with an external identity provider or a reviewed authentication service.
2. Use secure, `HttpOnly`, `Secure`, `SameSite` session cookies or an equivalent reviewed token flow; remove browser-embedded credentials.
3. Move clinical data to an encrypted managed database and encrypted object storage.
4. Define backups, restore tests, retention, deletion, and access-review procedures.
5. Replace wildcard CORS with an explicit allowlist and deploy behind HTTPS.
6. Add immutable, access-controlled audit storage and independently verify the hash chain.
7. Complete RODO/GDPR documentation, processor agreements, incident response, and clinical data access reviews.
8. Run an independent security assessment before importing real records.
