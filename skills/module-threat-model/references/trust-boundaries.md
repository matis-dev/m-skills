# Reference: Trust Boundaries — the Plan-Time Artifact

*`module-threat-model` reference — read when the run needs it.*

## 2. Trust Boundaries — the Plan-Time Artifact

Three questions, answered before any step is written:

1. **Where does untrusted data enter?** Every new endpoint, form field, query parameter, route parameter, upload, webhook, import, message-queue payload, third-party API response, and anything read from client storage. **Data from your own database is untrusted if a user put it there.**
2. **Where does privilege change?** Login, role assumption, impersonation, API-key exchange, a background job running as a service account, anything that widens what the current actor may do.
3. **Where does data leave?** Responses, logs, exports, emails, webhooks, error messages, analytics events, and anything rendered into a page.

Then, for each boundary crossed, name the control and where it lives:

| Boundary | Untrusted input | Control | Enforced at |
|---|---|---|---|
| `<e.g. POST /settings/avatar>` | `<file bytes, filename, content-type>` | `<type + size limit; filename never used as a path>` | `<the handler, before storage>` |

**A feature that crosses no boundary states that it crosses none.** That is a valid and common answer, and writing it down is what makes the omission deliberate rather than forgotten.

**Validate at the boundary, encode at the sink.** These are different controls and neither substitutes for the other: validation decides whether to accept the data at all, encoding decides how it is rendered safely *at the place it is used*. A value validated on entry and concatenated into a query at the sink is still an injection.

**Deny by default.** New route gated unless public is a deliberate decision. New field not returned unless it is meant to be. New permission not granted unless it is needed.

---
