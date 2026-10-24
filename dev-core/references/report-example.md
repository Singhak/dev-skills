# Report Examples

## Default change
> Task: "Add an endpoint to update an order's delivery note."

**What changed**: Added `PATCH /v1/orders/{id}/note` so customers can edit the delivery note on their own orders before shipping. Classified **high-risk** (permissions on user data), so high-risk steps were applied.

**Evidence**
| Check | Command | Result |
|---|---|---|
| Baseline | `npm test -- orders` (orders package only; no shared code touched) | 42 passed, 0 failed |
| New tests fail first | `npm test -- order-note` | 5 failed on assertions (404 route) before implementation |
| Lint / types | `npm run lint && npm run typecheck` | exit 0 |
| Tests after change | `npm test -- orders` | 47 passed (+5) |
| Integration | `npm run test:integration -- orders` (Testcontainers Postgres) | 9 passed |
| Diff scan | `bash .agents/skills/dev-core/scripts/diff_risk_scan.sh` | exit 0, no hits |
| Security tooling | `npm audit --audit-level=high` | 0 high/critical; no new dependencies |
| Build | `npm run build` | exit 0 |

**Security pass**
1. Inputs: `id` (path) validated as UUID; `note` (body) validated by Zod schema, max 500 chars — `orders/note.schema.ts:4`.
2. Diff scan: clean. Manual review: note is stored via parameterized ORM update and rendered escaped.
3. Permissions: `orders/note.service.ts:18` scopes the update by `id AND customer_id`; test `returns 404 when updating another customer's order` passes.
4. Secrets/logs: none added; the note text is not logged.
5. Tooling: project audit ran (above). No SAST configured in project → SAST "not verified".

**Break it** (2 rounds): other customer's order ID → 404 ✅; 10k-char note → 422 ✅; note with `<script>` → stored and rendered as text ✅; update after status = SHIPPED → **was allowed** ❌ → fixed (409 + test `rejects note change after shipping`); 20 parallel updates → last write wins, no error, acceptable per requirement (noted).

**Assumptions / open items**: assumed notes are editable only before shipping (confirm with product). Rollout: no flag needed (additive endpoint); no migration.

## Trivial change
> Task: "Fix the typo 'recieve' in the README."

Fixed "recieve" → "receive" in `README.md` (1 line). Check: `npx markdownlint README.md` → exit 0. Diff reviewed: only that line changed.
