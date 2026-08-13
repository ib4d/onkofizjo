# onkofizjo access and security model

## Roles

| Capability | Gosia | Assistant | Collaborator | AI agent |
|---|---:|---:|---:|---:|
| View assigned calendar | yes | yes | yes | scoped read |
| View patient contact | yes | assigned only | assigned only | task scoped |
| View clinical record | yes | no by default | assigned ecosystem | only approved context |
| Edit clinical notes | yes | no | assigned patients | draft only |
| Create diet draft | yes | no | if authorized | proposal only |
| Approve diet | yes | no | no by default | never |
| Generate documents | yes | administrative only | assigned patients | draft only |
| View payments | yes | operational only | no by default | aggregate only |
| Change permissions | yes | no | no | never |
| Export patient record | yes | no | no by default | never |

## Production controls

- MFA for every human CRM user.
- Server-side authorization for every patient, document and assistant action.
- Audit event for access, creation, edit, export, approval and delivery.
- No clinical data in public marketing routes.
- No production patient data in frontend bundles or demo JSON.
- Agents receive least-privilege, task-scoped context with explicit expiry.
- Human approval required for clinical recommendations and patient-facing documents.
