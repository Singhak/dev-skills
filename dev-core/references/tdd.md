# TDD in Depth

## Contents
1. The cycle, precisely
2. Picking the next test
3. Test doubles — which one when
4. Test data patterns
5. Outside-in vs inside-out
6. Working with legacy code
7. Anti-patterns

## 1. The cycle, precisely
1. Write the smallest test that expresses the next piece of behaviour.
2. Run it and **see it fail**. A test you never saw fail might be testing nothing.
3. Make it pass with the simplest code — even hard-coding is fine; the next test will force generalization ("triangulation").
4. Refactor production *and* test code while green. Refactoring changes structure, never behaviour.
5. Commit when green if the slice is meaningful.

Keep cycles short (minutes). If you've been red for long, revert to green and take a smaller step.

## 2. Picking the next test
Order tests from simple to complex, using a test list written up front:
- Degenerate cases (null/empty/zero) → single item → many items
- Happy path → boundaries → invalid input → error/exception paths
- Then cross-cutting concerns: authorization, concurrency, idempotency, timeouts

Example test list for `applyDiscount(cart, code)`:
- empty cart returns total 0
- unknown code raises InvalidCode
- 10% code on 100 returns 90
- expired code raises ExpiredCode (use injected clock)
- discount never makes total negative
- code usable once per user

## 3. Test doubles — which one when
| Double | Use for | Example |
|---|---|---|
| Dummy | Fill a parameter you don't use | `null` logger |
| Stub | Return canned answers | rate service returns 1.2 |
| Fake | Working lightweight implementation | in-memory repository |
| Spy | Record calls for later assertion | email sender records messages |
| Mock | Pre-programmed expectations on interactions | verify `publish(event)` called once |

Guidance:
- Prefer **state verification** (check results) over interaction verification (check calls). Interaction checks couple tests to implementation.
- Use mocks at **architectural boundaries** you own an interface for (payment gateway port, email port). Don't mock types you don't own — wrap them first.
- Inject time, randomness, IDs and environment so tests are deterministic.

## 4. Test data patterns
- **Builders / factories** with sensible defaults: `aUser().withRole("admin").build()`. Each test sets only fields it cares about.
- Avoid giant shared fixtures; they hide intent and cause coupling.
- Use realistic but fake data; never real customer data or production dumps.
- Property-based testing (Hypothesis, fast-check, jqwik, QuickCheck) for parsers, serializers, math, and invariants ("encode then decode returns the input").

## 5. Outside-in vs inside-out
- **Outside-in (London/mockist)**: start with a failing acceptance or e2e test for the feature, then drive inner units with mocks of collaborators. Good for feature work and API design.
- **Inside-out (Chicago/classicist)**: start with the core domain units, compose upward. Good for algorithmic/domain-heavy work.
- A practical default is the **double loop**: an outer failing acceptance test stays red while you complete several inner unit TDD cycles; the feature is done when the outer test goes green.

## 6. Working with legacy code
1. Identify the change point.
2. Find a seam (a place to alter behaviour without editing in place: parameter, interface, subclass, config).
3. Write **characterization tests** capturing current behaviour — even if it looks wrong. Approval/snapshot tests help here.
4. Break dependencies minimally (extract method, introduce parameter, wrap static calls).
5. Now TDD the change.

## 7. Anti-patterns
- Testing private methods directly → test via public behaviour instead
- Tests that mirror the implementation line by line → brittle
- Multiple unrelated behaviours in one test → unclear failures
- Fixed sleeps / real network / real clock → flaky
- Asserting on log strings or exact error message text when a type/code exists
- Overusing snapshots for logic — snapshots are for stable output, reviewed on change
- Ignoring or skipping a failing test instead of fixing or deleting it with a reason
