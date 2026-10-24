---
name: ship-and-operate
description: Release and operations readiness for any stack. Covers CI/CD pipelines and quality gates, Dockerfiles and container hardening, environment and secret configuration, infrastructure-as-code (Terraform, OpenTofu, Pulumi, CloudFormation, Bicep, Kubernetes/Helm), health checks, staging vs production, feature flags, rollout strategies (rolling, blue-green, canary), rollback criteria, database migrations during deploys, SLOs and error budgets. Use this skill ONLY when the task involves deploying, releasing, building or editing a CI/CD pipeline, writing or changing a Dockerfile/compose/Kubernetes/IaC file, adding environment variables or secrets, setting up health checks, monitoring/alerting/SLOs, feature flags, or preparing a production release. Do NOT use for ordinary feature coding, refactoring or local bug fixes that don't change how the app is built, configured or deployed. Always together with dev-core.
---

# Ship and Operate

Code that passes tests is not yet safe in production. This skill makes changes **buildable, configurable, deployable, observable and reversible**. Follow the `dev-core` workflow; this adds release/ops specifics. Use the project's existing CI system, cloud and IaC tool — never introduce a new platform without the user's explicit agreement.

**Safety rules:** never run deploys, `terraform apply`, `kubectl apply/delete`, database migrations or secret changes against shared or production environments unless the user explicitly asks in this conversation. Default to: write the change, run `plan`/`diff`/dry-run/lint locally, and show the result.

## 1. Release readiness questions (answer for every ops-touching change)
1. How is it built? (reproducible, pinned, cached)
2. How is it configured? (env vars documented, validated at startup, secrets external)
3. How is it deployed? (pipeline steps, environments, approvals)
4. How do we know it's healthy? (health checks, metrics, alerts, SLOs)
5. How do we turn it off or roll it back? (feature flag, previous artefact, migration compatibility)

If any answer is unknown, that's a finding to resolve or report.

## 2. CI/CD pipeline
Standard stages (fail fast; cheap checks first):
1. Install with lockfile (`npm ci`, `uv sync --frozen`, `./mvnw -B`, `go mod download`)
2. Format, lint, type-check
3. Unit tests (with coverage report)
4. Integration/contract tests (service containers)
5. Security: SAST, dependency audit, secret scan, IaC scan (Checkov/tfsec/Trivy config)
6. Build artefact/image **once**; tag with commit SHA; scan image; generate SBOM if required
7. Deploy same artefact to staging → smoke + e2e + DAST baseline
8. Promote **the same artefact** to production (manual approval or automated with canary analysis)
9. Post-deploy smoke test; automatic rollback on failure where supported

Pipeline hygiene:
- Pin action/orb/image versions (preferably by SHA for third-party CI actions).
- Least-privilege CI credentials; use OIDC federation to cloud instead of long-lived keys.
- Secrets only from the CI secret store; never echoed; masked in logs.
- Cache dependencies; parallelize independent jobs; keep PR pipelines under ~10–15 minutes.
- Required status checks + branch protection on the main branch.

Templates: `references/ci-cd-and-containers.md`.

## 3. Containers
- Multi-stage builds; small pinned base images (distroless, `-slim`, alpine where compatible); pin by digest for production.
- Run as **non-root**; read-only root filesystem where possible; drop capabilities.
- No secrets in images, build args or layers; `.dockerignore` excludes `.git`, `.env`, `node_modules`, tests.
- One process per container; logs to stdout/stderr as structured JSON.
- Handle SIGTERM: graceful shutdown within the orchestrator's grace period.
- `HEALTHCHECK` or orchestrator probes defined (see section 5).
- Scan images (Trivy/Grype); fail on high/critical with available fixes.

## 4. Configuration and secrets
- Follow 12-factor: config via environment, same artefact for every environment.
- **Validate config at startup** with a schema (Zod, Pydantic Settings, Spring `@ConfigurationProperties` + validation, envconfig); fail fast with a clear message naming the missing variable — never print its value.
- Document every variable in `.env.example` (placeholders only) and/or README: name, purpose, required?, default, example.
- Secrets in a secret manager (AWS Secrets Manager/SSM, GCP Secret Manager, Azure Key Vault, Vault, Doppler, sealed-secrets/External Secrets for Kubernetes). Support rotation without redeploy where feasible.
- Separate config per environment: dev, test, staging, production. Production values never in the repo.
- Frontend: remember build-time public env vars are visible to everyone.

## 5. Health checks
- **Liveness**: is the process alive? Cheap; no dependency checks (otherwise a DB blip restarts every pod).
- **Readiness**: can it serve traffic now? Checks critical dependencies (DB connection, required caches) with short timeouts.
- **Startup** probe for slow-booting apps.
- Expose version/commit SHA (e.g. `/version` or in health payload) to confirm what's deployed.
- Health endpoints don't leak internals and are excluded from auth only if they reveal nothing sensitive.

## 6. Infrastructure as code
- All infra changes through code (Terraform/OpenTofu, Pulumi, CDK, CloudFormation, Bicep, Helm/Kustomize); no click-ops drift.
- Remote state with locking; state never committed; separate state per environment.
- Modules versioned; providers pinned.
- Always run `fmt`, `validate`, lint (tflint), security scan (Checkov/tfsec/Trivy), and **`plan`** — show the plan; flag any destroy/replace of stateful resources (databases, buckets, volumes) loudly.
- Tag resources (owner, environment, cost center); least-privilege IAM; encryption at rest and in transit; no public buckets/DBs unless explicitly intended.

## 7. Database changes during deploys
- Migrations must be compatible with **both the old and new app version** during rollout (expand → migrate → contract; see backend-dev).
- Run migrations as a separate, idempotent pipeline step or job before the new version takes traffic — not on every pod start in multi-replica deploys.
- Large backfills run as throttled background jobs, not in the deploy migration.
- Rollback plan: app rollback must work with the migrated schema (that's what expand/contract guarantees). Destructive migrations only in a later release once rollback is no longer needed.

## 8. Feature flags and rollout
- Put risky or incomplete features behind a **feature flag** (LaunchDarkly, Unleash, Flagsmith, OpenFeature, ConfigCat, or a simple config table). Default **off** in production.
- Flags are evaluated server-side for anything security- or data-relevant.
- Every flag has an owner and a removal date; remove flags (and dead code paths) after full rollout. Test both flag states.
- Rollout strategies: rolling (default), blue-green (instant switch/rollback), canary (1% → 10% → 50% → 100% with metric gates), percentage/cohort flags for product rollouts.
- Decouple **deploy** (code in production, dark) from **release** (users see it).

## 9. Rollback strategy and criteria
Define before deploying (template in `references/release-and-rollback.md`):
- **Mechanism**: redeploy previous artefact (by SHA/tag), flip blue-green, turn off flag, `helm rollback`.
- **Automatic criteria** (examples): error rate > 2× baseline for 5 min; p95 latency > SLO threshold; health checks failing; crash loops; key business metric (checkouts/min) drops > X%.
- **Decision owner** and **time limit**: if not clearly healthy within N minutes, roll back first, investigate second.
- Data: what happens to data written by the new version if we roll back?
- Practise rollback in staging for high-risk releases.

## 10. Observability, SLOs and error budgets
- Every service emits structured logs, RED metrics and traces (OpenTelemetry) with correlation IDs propagated from the frontend through backends and queues.
- **SLIs** for user journeys: availability (successful requests / total), latency (p95/p99 under threshold), freshness for async pipelines, frontend Core Web Vitals and JS error rate.
- **SLOs**, e.g. 99.9% of checkout requests succeed over 28 days; p95 < 300 ms.
- **Error budget** = 1 − SLO. Burning fast → freeze risky releases, prioritize reliability work. Alert on **burn rate** (multi-window, e.g. 14.4× over 1h and 6× over 6h) rather than raw thresholds.
- Alerts are actionable and link to a runbook; dashboards per service and per user journey.
- Frontend: real-user monitoring and error tracking (Sentry, Datadog RUM, OpenTelemetry web) tagged with release version.

## 11. Staging vs production
- Staging mirrors production topology, config shape and data shape (anonymized/synthetic data — never raw production PII).
- Same artefact, different config.
- Production access is least-privilege and audited; changes go through the pipeline, not manual edits.

## 12. Break-it attacks for ops (dev-core Step 7)
Run against local/staging only:
- Start the app with a missing or malformed env var → fails fast with a clear message, no secret printed?
- Kill the DB/cache/broker → readiness fails, liveness doesn't restart-loop, app recovers when it returns?
- Send SIGTERM during in-flight requests → graceful drain, no lost jobs?
- Deploy the new version alongside the old against the migrated schema → both work?
- Roll back to the previous artefact after migration → still works?
- Inspect the image (`docker history`, `dive`) and CI logs for secrets; run as non-root confirmed?
- `terraform plan` shows no unintended destroy; IaC scan clean?
- Flag off → old behaviour intact; flag on → new behaviour; flag service unreachable → safe default?

## 13. Definition of Done (ops-touching changes)
- [ ] Pipeline runs all gates; artefact built once and promoted
- [ ] Dockerfile hardened (non-root, pinned, multi-stage, scanned, no secrets)
- [ ] New config documented, validated at startup; secrets in a secret manager
- [ ] Liveness/readiness probes correct; version exposed
- [ ] IaC formatted, validated, scanned; plan reviewed; no unintended destroys
- [ ] Migration compatible with old and new versions; rollback works
- [ ] Risky change behind a flag (default off) with owner and removal date
- [ ] Rollback mechanism and criteria written down
- [ ] Metrics/logs/traces, SLO impact and alerts considered; runbook updated
- [ ] Nothing deployed or applied to shared/prod environments without explicit user approval

## Reference files
- `references/ci-cd-and-containers.md` — pipeline and Dockerfile templates
- `references/release-and-rollback.md` — release checklist, rollback plan template, SLO examples
