---
name: dev-core
description: Core engineering workflow for any software change, backend or frontend, in any language. Covers understanding the task, planning, test-driven development (red-green-refactor), the test pyramid (unit, integration, e2e), security checks, an adversarial "break it" phase where the agent attacks its own feature like a hacker and fixes what it finds, code quality, and a definition of done. Use this skill whenever you are asked to write, change, fix, refactor or review code, add a feature, fix a bug, add tests, or harden security, even if the user doesn't mention testing or TDD. For server/API/database work also load backend-dev; for UI/browser work also load frontend-dev.
---

# Dev Core — Universal Engineering Workflow

This skill defines *how* to make any code change safely. It is stack-agnostic and is the only skill used on every coding task. Load the others only when the task matches:

| Load | When the task… | Don't load when… |
|---|---|---|
| `backend-dev` | touches server code, APIs, DB, migrations, jobs, queues, CLIs | change is UI-only |
| `frontend-dev` | touches UI components, pages, forms, styling, client state, browser behaviour | change is server-only |
| `fullstack-integration` | touches **both** sides of an API, consumes a new/changed endpoint, changes a contract, or fixes stale data / type mismatch / unhandled API error bugs | one side only and contract unchanged |
| `ship-and-operate` | changes CI/CD, Dockerfiles, compose/K8s/IaC, env vars/secrets, health checks, monitoring/alerts, feature flags, or prepares a release/deploy | ordinary feature work that doesn't change how the app is built, configured or deployed |
| `debug-production` | investigates something broken/slow in a **deployed** environment (error reports, alerts, traces, customer complaints) | bug found while coding locally — dev-core's bug-fix rule covers it |

Every skill ends with a **Verify** table (commands plus the evidence that counts as passing) and a **Stop and hand back** list. Before reporting done, run the Verify rows of every loaded skill and check its stop conditions.

Mid-task triggers: if a feature turns out to need a new env var, migration-in-deploy, or feature flag, pull in `ship-and-operate` at that point; if a UI task turns out to need an API change, pull in `backend-dev` and `fullstack-integration`.

The goal: every change is **understood, tested first, attacked by its own author, secure, small, and verifiable**. Working code nobody can trust is not done.

---

## 1. The workflow (follow in order)

### Step 1 — Understand before touching code
1. Restate the task in one or two sentences. If acceptance criteria are missing, write them as testable statements ("Given / When / Then").
2. Explore the repo: README, build files (`package.json`, `pyproject.toml`, `pom.xml`, `build.gradle`, `go.mod`, `Cargo.toml`, `*.csproj`), existing tests, CI config, lint config. **Match existing conventions** — framework, folder layout, naming, test runner. Don't introduce a new tool when one already exists.
3. Find the commands for install, build, lint, type-check, unit, integration and e2e tests (see `references/project-discovery.md`).
4. Run the existing test suite once *before* changing anything to learn the baseline. Pre-existing failures are not yours — note them, don't silently "fix" them.
5. Ask the user only when a decision is genuinely ambiguous and expensive to reverse (data model, public API shape, deleting behaviour). Otherwise state your assumption and proceed.

### Step 2 — Plan small
- Break work into slices that each end in a green test run. Prefer thin vertical slices over horizontal layers.
- For each slice list: behaviour to add, test(s) that prove it, files likely touched.
- Identify the **risk surface**: auth, money, personal data, file/OS access, external input, concurrency, migrations. These get extra tests and the full security pass.
- **Feature-flag check**: if the change is risky, user-visible and incomplete, or hard to roll back, recommend putting it behind a feature flag (details in `ship-and-operate`).
- For non-trivial design (new domain area, schema, events, caching), write a short design note first (template in `backend-dev/references/data-design.md`).

### Step 3 — Test-Driven Development loop
For every behaviour, run **Red → Green → Refactor** (details: `references/tdd.md`):

1. **Red** — write one failing test describing the behaviour. Run it. Confirm it fails *for the right reason* (assertion failure, not a typo or import error).
2. **Green** — write the minimum code to pass. No speculative features.
3. **Refactor** — improve names, remove duplication, simplify, keeping everything green. Run the relevant suite.
4. Repeat.

**Bug fixes: first write a test that reproduces the bug**, watch it fail, then fix. This proves the fix and prevents regressions.

When TDD is impractical (spikes, exploratory layout work, legacy code with no seams), say so explicitly, then add characterization tests around the code before changing it.

### Step 4 — Choose the right test level (test pyramid)
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

### Step 5 — Security pass (every change)
Run through `references/security-checklist.md`. Short version:
- **Input**: validate all external input at the boundary (type, length, format, range) with allow-lists. Never trust the client.
- **Injection**: parameterized queries; no string-built SQL, shell commands, or HTML; no `eval` on input.
- **AuthN/AuthZ**: every endpoint/action checks *who* the caller is and *whether they may act on this specific resource* (object-level authorization).
- **Secrets**: never hard-code or log secrets, tokens, passwords, or PII. Use env vars / a secret manager. Scan the diff for leaked keys.
- **Dependencies**: add only when needed; prefer maintained, widely used, pinned versions; run the ecosystem's audit tool.
- **Errors**: fail closed; generic messages to clients, detailed (secret-free) logs internally.
- **Data**: least privilege, TLS in transit, minimize stored PII.

Write tests for security behaviour ("user B cannot read user A's invoice", "a script tag in a name renders as text"). Run `scripts/security_scan.sh` to use whatever scanners exist locally.

### Step 6 — Quality gates
Before declaring done, run and pass in order: formatter → linter → type checker → unit → integration/contract → e2e for touched critical journeys → dependency/security audit → build.

If a gate can't run in this environment, say which and why — **never claim it passed**. Pass evidence for each gate is listed in section 5 (Verify).

### Step 7 — Break it: attack your own feature like a hacker
Once the feature works and the gates are green, switch roles. You are no longer the author — you are an attacker and a hostile tester whose only goal is to make this feature fail, leak data, or misbehave. Authors test what they expect; attackers test what nobody expected. This step finds the bugs the happy-path tests missed.

**Scope (non-negotiable):** attack only the code you just wrote, running locally or in a test environment you control. Never target production, third-party services, or systems you don't own, and never run destructive commands against real data.

The loop:
1. **Map the attack surface** of the new feature: every input (fields, params, headers, files, events, URL, storage), every trust boundary, every state change, every permission check.
2. **Write a threat list** — for each surface, ask "how could this be abused?" Use STRIDE as prompts: Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege.
3. **Attack** using the playbook in `references/break-it.md`: malicious and malformed input, boundary values, auth bypass and other-user access, race conditions and double-submits, replay, oversized payloads, broken dependencies, and abuse of business logic (negative quantities, skipped steps, reused coupons).
4. **Turn every successful attack into a failing test first**, then fix the code, then confirm the test passes. A fix without a regression test will come back.
5. **Repeat** until a full round of attacks finds nothing new (minimum one full round; for high-risk features — auth, payments, PII, file upload — at least two rounds).
6. **Record a short Break-It Report**: attacks tried, issues found, fixes and tests added, and anything you couldn't test.

Severity guide: **Critical** (auth bypass, data leak, injection, remote code execution) and **High** (privilege escalation, data corruption, crash from a single request) must be fixed before done. **Medium/Low** — fix if cheap; otherwise report to the user with a recommendation.

### Step 8 — Review your own diff
Read the full diff as a strict reviewer would (`references/code-review.md`). Remove debug prints, commented-out code, unrelated changes, and TODOs without a ticket. Update docs/README/changelog when public behaviour changes.

### Step 9 — Report
Tell the user:
- What changed and why (1–3 sentences)
- **Evidence**: each check run, the command, and the observed result (exit code, test counts, findings); unrun checks marked "not verified"
- Tests added (by level) and the final test result
- Security considerations checked and anything flagged
- Break-It Report: attacks tried, issues found and fixed (with their tests), open risks
- Gates that couldn't run, assumptions made, follow-ups

---

## 2. Design principles
- **Simple first**: the simplest design that passes the tests. YAGNI. Abstract on the third repetition, not the first.
- **SOLID where it earns its keep** — single responsibility and dependency inversion matter most because they make code testable.
- **Separate pure logic from I/O** ("functional core, imperative shell"): pure logic gets cheap unit tests; I/O gets a few integration tests.
- **Explicit over clever**: intention-revealing names, small functions doing one thing.
- **Make illegal states unrepresentable** with types, enums, and validation at construction.
- **Errors are part of the API**: handle them deliberately; never swallow them.
- **Backwards compatibility**: public APIs, schemas and events change additively; deprecate before removing.

## 3. Git hygiene
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

## 4. Definition of Done
- [ ] Acceptance criteria written; each covered by at least one test
- [ ] Tests written first (or characterization tests for legacy); all green
- [ ] Right mix of unit / integration / e2e for the risk level
- [ ] Security checklist passed; security-relevant tests exist
- [ ] Break-it phase done: no open Critical/High findings; every finding has a regression test
- [ ] Format, lint, type-check, build pass
- [ ] No secrets, debug code, or unrelated changes in the diff
- [ ] Docs updated if behaviour or interface changed
- [ ] Clear summary delivered, including anything not verified

## 5. Verify — proof required
**Rule: no evidence, no claim.** Report a check as passed only if you ran it and saw the pass evidence. Otherwise write "not verified" and why. Use the project's own scripts first; the commands below are examples.

| Check | Example commands | Pass evidence |
|---|---|---|
| Baseline before changes | project test command (`npm test`, `pytest`, `./gradlew test`, `go test ./...`) | Result recorded; pre-existing failures listed |
| New test fails first | run the single new test | Fails on an assertion (not an import or syntax error) |
| Format / lint / types | `prettier --check`, `ruff check`, `eslint`, `tsc --noEmit`, `mypy`, `golangci-lint run` | Exit code 0 |
| Full relevant suite | unit + integration commands | Exit code 0; test count went up by the tests you added |
| Security scan | `bash scripts/security_scan.sh` | No new high/critical findings, or each one reported |
| Diff hygiene | `git diff --stat`; `git diff \| grep -nEi "(api[_-]?key\|secret\|password\|token)\s*[:=]"` | Only intended files; no secrets; no debug prints |
| Build | project build command | Exit code 0 |

## 6. Stop and hand back to the user
Stop working and report when any of these is true:
- **Done**: every Definition of Done item has evidence. Don't keep polishing or add unrequested features.
- **Blocked**: missing access, credentials, environment, or a dependency (e.g. Docker unavailable for integration tests). Report what you couldn't verify; don't substitute a weaker setup silently.
- **Decision needed**: ambiguous requirement, breaking public API or schema change, deleting behaviour or data, adding a major dependency or new platform, or a change well outside the requested scope.
- **Risk line crossed**: an unfixed Critical/High break-it finding, or any step that would write to a shared or production environment.
- **Loop limit**: the same test or error still fails after **3** distinct fix attempts. Stop, summarize what you tried and what you learned, and propose next options instead of continuing to guess.

When handing back, say what's done, the evidence, what's open, and the specific question or decision you need.

## Reference files (read when relevant)
- `references/tdd.md` — TDD in depth, test doubles, test data, legacy code
- `references/security-checklist.md` — full OWASP-aligned checklist
- `references/break-it.md` — hacker-mode attack playbook and Break-It Report template
- `references/code-review.md` — self-review checklist
- `references/project-discovery.md` — commands and conventions per ecosystem
- `scripts/security_scan.sh` — runs whichever audit / secret-scan tools are installed
