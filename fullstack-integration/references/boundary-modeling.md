# Modeling the Client/Server Boundary

## Domain modeling across the boundary
Decide explicitly for each concept:
- **Source of truth**: the server owns business rules and persisted state; the client owns ephemeral UI state (open panels, draft input, selection).
- **Where validation runs**: client validation is for UX speed; server validation is the authority. Share the schema when possible so messages and rules match — but never rely on the client copy for security.
- **Shapes per use case**: API DTOs are designed for consumers (screens/use cases), not mirrors of DB tables. Don't leak internal fields, foreign keys the UI doesn't need, or computed fields the UI recomputes differently.
- **Money, time, IDs**: money as integer minor units or decimal strings with currency; timestamps in UTC ISO-8601, formatted to local time only in the UI; IDs opaque strings.
- **Enums and states**: one definition shared via the contract; the UI handles unknown future enum values gracefully.
- **Permissions**: server returns what the user may do (e.g. `allowedActions: ["edit","delete"]`) so the UI doesn't reimplement authorization rules — and the server still enforces them.

## Real-time and eventual consistency
- When the server processes asynchronously (queues, events), the API returns `202 Accepted` with a status resource; the UI shows a pending state and polls or subscribes (SSE/WebSocket) until done.
- Real-time messages carry entity ID + version; the client ignores messages older than its cached version.
- Reconnect logic: on reconnect, refetch to resync — don't assume no events were missed.
- Tell users when data may be briefly behind ("Updating…") instead of showing contradictory numbers.
