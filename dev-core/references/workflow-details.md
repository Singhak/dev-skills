# Workflow Details

Deeper guidance behind the dev-core default flow. Read the section you need.

## Contents
1. Test levels and test rules
2. Design principles
3. Git hygiene and PR description
4. Full Definition of Done

## 1. Test levels and test rules
| Level | What it proves | Speed | Share |
|---|---|---|---|
| Unit | One function/class/component in isolation; logic and edge cases | ms | most (~70%) |
| Integration | Real collaborators: DB, HTTP layer, broker, file system | seconds | some (~20%) |
| Contract | Provider and consumer agree on an API/event shape | seconds | at service boundaries |
| End-to-end | A real user journey through the running stack | slow | few (~10%), critical paths only |

Rules of thumb:
- Test **behaviour through public interfaces**, not private implementation details.
- Mock only what you don't own or what is slow/non-deterministic (network, clock, randomness). Prefer fakes and real local dependencies (containers) over deep mock chains.
- Tests are **deterministic, isolated, order-independent**. No fixed sleeps — wait on conditions. No shared mutable state.
- Cover: happy path, boundaries (empty, zero, max, off-by-one), invalid input, error paths, permission denied, concurrency where relevant.
- Name tests as specifications: `returns_404_when_order_belongs_to_another_user`.
- Structure each test as Arrange / Act / Assert, one behaviour per test.
- Coverage is a signal, not a goal. Aim high on domain logic (≈80%+ lines, meaningful branches); never write assertion-free tests to inflate it.


## 2. Design principles
- **Simple first**: the simplest design that passes the tests. YAGNI. Abstract on the third repetition, not the first.
- **SOLID where it earns its keep** — single responsibility and dependency inversion matter most because they make code testable.
- **Separate pure logic from I/O** ("functional core, imperative shell"): pure logic gets cheap unit tests; I/O gets a few integration tests.
- **Explicit over clever**: intention-revealing names, small functions doing one thing.
- **Make illegal states unrepresentable** with types, enums, and validation at construction.
- **Errors are part of the API**: handle them deliberately; never swallow them.
- **Backwards compatibility**: public APIs, schemas and events change additively; deprecate before removing.


## 3. Git hygiene and PR description
- Small focused commits; each builds and passes tests.
- Conventional commits: `feat(scope):`, `fix(scope):`, `test:`, `refactor:`, `perf:`, `docs:`, `chore:`, `security:`.
- Never commit secrets, `.env` files, build artefacts, or local IDE config.
- Follow the team's branch strategy and PR rules from `CONTRIBUTING.md`/`AGENTS.md`; if none exist, use short-lived branches off main (`feat/…`, `fix/…`).
- **PR description** (when opening or preparing a PR):
  ```
  ## What & why        <1–3 sentences, link issue/ticket>
  ## How               <key design decisions, trade-offs>
  ## Tests             <added by level; how to run>
  ## Security & break-it  <checks done, findings fixed, open risks>
  ## Rollout           <flags, migrations, config/env changes, rollback plan or "standard">
  ## Screenshots       <for UI changes: before/after, mobile + desktop>
  ```
  Keep PRs small and reviewable (aim < ~400 changed lines excluding generated files); split otherwise.


## 4. Full Definition of Done
- [ ] Acceptance criteria written; each covered by at least one test
- [ ] Tests written first (or characterization tests for legacy); all green
- [ ] Right mix of unit / integration / e2e for the risk level
- [ ] Security checklist passed; security-relevant tests exist
- [ ] Break-it phase done: no open Critical/High findings; every finding has a regression test
- [ ] Format, lint, type-check, build pass
- [ ] No secrets, debug code, or unrelated changes in the diff
- [ ] Docs updated if behaviour or interface changed
- [ ] Clear summary delivered, including anything not verified

