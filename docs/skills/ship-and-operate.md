---
title: ship-and-operate
parent: Skills
nav_order: 5
permalink: /skills/ship-and-operate/
---

# ship-and-operate
{: .no_toc }

Release and operations readiness: makes changes buildable, configurable, deployable, observable and reversible.
{: .fs-5 .fw-300 }

[View SKILL.md](https://github.com/Singhak/dev-skills/blob/master/ship-and-operate/SKILL.md){: .btn .btn-outline }

1. TOC
{:toc}

---

## Loads when

**Only** when the task changes how the app is built, configured or deployed: CI/CD files, Dockerfile/compose/Kubernetes/IaC, env vars or secrets, health checks, monitoring/alerting, feature flags, or preparing a release. It's pulled in mid-task when a feature needs new config, a deploy-time migration or a flag. It doesn't load for ordinary feature coding.

{: .warning }
The agent never runs deploys, `terraform apply`, `kubectl apply/delete`, migrations or secret changes against shared or production environments unless you explicitly ask in the conversation. By default it writes the change, runs `plan` / `diff` / dry-run / lint locally, and shows you the result.

## Default vs high-risk

| Level | Adds |
|---|---|
| **Default** (small config, pipeline step or Dockerfile tweak) | Lint/validate the changed files, build the image, check health endpoints, document new env vars |
| **High-risk** (new service, production release, IaC change, migration in deploy, new secrets/permissions) | Release readiness questions, plan review with destroy count, rollback plan with criteria, feature flag, SLO/alert check, ops break-it attacks |

## Release readiness questions

1. How is it built? (reproducible, pinned, cached)
2. How is it configured? (env vars documented, validated at startup, secrets external)
3. How is it deployed? (pipeline steps, environments, approvals)
4. How do we know it's healthy? (health checks, metrics, alerts, SLOs)
5. How do we turn it off or roll it back? (flag, previous artefact, migration compatibility)

## What it covers

- **CI/CD**: cheap checks first, build once, promote the same artefact, pinned actions, OIDC instead of long-lived keys.
- **Containers**: multi-stage, pinned bases, non-root, no secrets in layers, graceful SIGTERM, image scanning.
- **Config and secrets**: 12-factor, schema-validated at startup, documented in `.env.example`, secrets in a secret manager.
- **Health checks**: cheap liveness, dependency-aware readiness, startup probes, exposed version/SHA.
- **IaC**: fmt, validate, lint, security scan and `plan`, with destroys of stateful resources flagged loudly.
- **Deploy-time migrations**: compatible with old and new versions; run as a separate step; backfills throttled.
- **Flags and rollout**: default-off flags with an owner and removal date; rolling, blue-green and canary; deploy decoupled from release.
- **Rollback**: mechanism, automatic criteria, decision owner and time limit defined before deploying.
- **SLOs**: SLIs per user journey, error budgets, multi-window burn-rate alerts with runbooks.

## Verify: proof required

All of these run locally or in a disposable environment.

| Check | Pass evidence |
|---|---|
| Pipeline syntax | `actionlint` or equivalent exit 0 |
| Image builds and is hardened | Build exit 0; user isn't root |
| Image scan | Trivy exit 0, or each finding reported |
| Config fails fast | Missing var → non-zero exit naming the variable, no secret printed |
| Health checks | Ready goes non-200 when the DB is down and recovers |
| Graceful shutdown | In-flight request completes on `docker stop` |
| IaC | `plan` exit 0; destroys/replaces = 0 or each one flagged |
| Kubernetes manifests | `kubeconform` / dry-run exit 0 |
| Rollback ready | Plan with mechanism, criteria, owner, data considerations |

## Stops and hands back when

- Any deploy, apply, migration, secret change, restart or scaling action on a shared, staging or production environment is needed.
- A plan destroys or replaces a stateful resource.
- The change needs paid resources, new credentials or IAM permissions, or a new vendor.
- CI secrets or cloud access needed for verification are unavailable.

## References

`ci-cd-and-containers.md` · `release-and-rollback.md`
