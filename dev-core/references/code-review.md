# Self-Review Checklist

Read the whole diff top to bottom before reporting done.

## Correctness
- Does the code do what the acceptance criteria say — and nothing extra?
- Edge cases: null/empty, boundaries, large inputs, unicode, time zones, concurrency, retries
- Errors handled deliberately; resources closed/released; transactions scoped correctly

## Tests
- Each behaviour has a test that would fail if the behaviour broke
- Tests readable as specs; no flaky waits; no real network/clock
- Bug fix includes a regression test

## Design & readability
- Names reveal intent; functions small and single-purpose
- No duplication that will drift; no premature abstraction
- Matches project conventions and architecture boundaries
- Public interface changes are intentional and documented

## Security
- Security checklist items relevant to this diff verified
- No secrets, tokens, PII in code, tests, or logs

## Performance
- No N+1 queries, unbounded loops over remote calls, or loading whole tables into memory
- Expensive work cached or batched where justified by evidence

## Hygiene
- No debug prints, commented-out code, stray files, unrelated formatting churn
- Lockfile updated consistently with manifest
- Migration/rollout/rollback considered for schema or config changes
