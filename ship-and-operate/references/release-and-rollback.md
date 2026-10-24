# Release Checklist, Rollback Plan, SLO Examples

## Pre-release checklist
- [ ] All CI gates green on the exact artefact (SHA) being released
- [ ] Staging deploy + smoke/e2e passed with production-like config
- [ ] Migrations reviewed: backward compatible, tested from current prod schema
- [ ] New env vars/secrets present in target environment (verified by name, not value)
- [ ] Feature flags configured (default off in prod for risky features)
- [ ] Dashboards and alerts exist for the changed paths
- [ ] Rollback plan written (below) and owner on hand
- [ ] Release notes / changelog updated; support informed of user-visible changes

## Rollback plan template
```
Release: <service> <version/SHA>      Owner: <name>      Window: <time>
Change summary: <1–2 lines>
Risk level: low / medium / high      Flag(s): <names, default state>

Health signals to watch (first 30 min):
  - Error rate (5xx) baseline <x%>; rollback if > <2× baseline> for 5 min
  - p95 latency baseline <y ms>; rollback if > <SLO threshold> for 10 min
  - Business metric <checkouts/min> baseline <z>; rollback if drops > <20%>
  - Frontend JS error rate tagged with this release

Rollback mechanism: <redeploy SHA abc123 | blue-green switch | flag off | helm rollback>
Expected time to roll back: <minutes>
Data considerations: <writes by new version compatible with old? cleanup needed?>
Decision rule: if not clearly healthy within <N> minutes → roll back, then investigate.
```

## SLO examples
| Journey | SLI | SLO (28 days) |
|---|---|---|
| Login | successful logins / attempts (excl. wrong password) | 99.9% |
| Checkout API | non-5xx responses / total | 99.95% |
| Checkout API latency | requests under 400 ms | 95% |
| Search page | LCP under 2.5 s (RUM, p75) | 90% of page views |
| Order events pipeline | events processed within 60 s | 99% |

Error budget for 99.9% over 28 days ≈ 40 minutes of failure.

Burn-rate alerting (Google SRE workbook pattern):
- Page: 2% of budget in 1 h (burn rate 14.4) confirmed over 5 min window
- Page: 5% in 6 h (burn rate 6) confirmed over 30 min window
- Ticket: 10% in 3 days (burn rate 1)

## Error budget policy (example)
- Budget healthy → normal release cadence
- Budget < 25% remaining → only low-risk releases, extra review
- Budget exhausted → feature freeze except reliability fixes until budget recovers
