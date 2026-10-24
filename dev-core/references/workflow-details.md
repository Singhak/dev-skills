# Workflow Details

Deeper guidance behind the dev-core default flow. Read the section you need.

## Contents
1. Test levels and test rules
2. Design principles
3. Git hygiene and PR description
4. Full Definition of Done
5. Special task types

## 1. Test levels and test rules
| Level | What it proves | Speed | Share |
|---|---|---|---|
| Unit | One function/class/component in isolation; logic and edge cases | ms | most |
| Integration | Real collaborators: DB, HTTP layer, broker, file system | seconds | some |
| Contract | Provider and consumer agree on an API/event shape | seconds | at service boundaries |
| End-to-end | A real user journey through the running stack | slow | few, critical paths only |

The shares are a **heuristic, not a quota**. A common starting point for backend code is roughly 70/20/10 (unit/integration/e2e). Frontend code often follows the "testing trophy" instead, with most tests at the component/integration level (see `frontend-dev`). Pick the level where a test gives the most confidence per second of runtime, and follow the project's existing balance.

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


## 5. Special task types

**Dependency upgrade**
1. Read the changelog/release notes between the current and target version for breaking changes and deprecations.
2. Baseline the relevant tests first; upgrade one dependency (or one coupled group) per change.
3. Update the lockfile with the project's package manager; don't hand-edit it.
4. Fix breakages; run relevant tests, type-check, build, and the dependency audit.
5. Major versions or framework upgrades are high-risk: check runtime behaviour, not just compile success, and note anything untestable.

**Refactor-only (no behaviour change)**
1. Make sure tests cover the behaviour you're touching; if not, add characterization tests first (`references/tdd.md` §6) and see them pass on the old code.
2. Refactor in small steps, running those tests after each step. Don't mix refactoring with behaviour changes in the same commit.
3. Evidence: the same tests pass before and after; the public interface is unchanged (or each change is listed).

**Merge / rebase conflict**
1. Understand both sides: read each branch's intent (commit messages, PR descriptions), not just the conflicting lines.
2. Resolve to preserve **both** intents; never pick a side wholesale without checking what the other side changed.
3. Regenerate lockfiles and generated code rather than merging them by hand.
4. Run the relevant tests for both changes. If the intents genuinely conflict, stop and ask.

**Performance work**
1. Measure first: reproduce with a benchmark, profiler or load test, and record the baseline number.
2. Find the bottleneck from the measurement (profiler flame graph, slow query log, trace), not from intuition.
3. Change one thing; measure again; keep it only if the gain is real and repeatable.
4. Add a guard where practical (benchmark threshold, query-count assertion, bundle-size limit).
5. Evidence: before/after numbers with how they were measured.

**Release notes / changelog**
Group by Added / Changed / Fixed / Deprecated / Removed / Security. Write for users: what changed for them and any action they must take. Call out breaking changes and migrations first. Derive entries from merged PRs/commits; don't invent changes.
