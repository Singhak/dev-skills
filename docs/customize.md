---
title: Customize
nav_order: 6
permalink: /customize/
---

# Customize for your team
{: .no_toc }

1. TOC
{:toc}

---

## Language and framework support

**The workflow is language- and framework-agnostic; the examples are not.**

- **Universal**: the process (TDD, test pyramid, security pass, break-it, verify, stop rules), the architecture principles and the contract, rollout and debugging methods. These apply to any stack.
- **Illustrative**: commands and code samples. Each skill lists equivalents for common ecosystems: Node/TS, Python, Java/Kotlin, Go, .NET, Rust, Ruby, PHP; React, Vue, Angular, Svelte, React Native; Terraform, Pulumi, Kubernetes and the major CI systems. Code examples lean toward TypeScript because it spans frontend and backend.
- **How the agent adapts**: dev-core Step 1 makes it read your build files, CI config and existing tests and **use your project's tools and conventions first**. The examples are only a fallback when the project has nothing set up.
- **Less covered**: native mobile (Swift/Kotlin UI), game engines, embedded, data/ML pipelines. The core workflow still applies, but stack-specific guidance is thin.

## Make it stack-specific

1. Edit the "Tools" tables and examples in `backend-dev/SKILL.md` and `frontend-dev/SKILL.md` to list only your stack.
2. Add your build, test and lint commands to `dev-core/references/project-discovery.md`.
3. Re-run the [trigger evals]({{ '/testing/' | relative_url }}) if you change any skill's `description`.

## Settings worth deciding up front

| Setting | Where it shows up |
|---|---|
| Preferred stack and tools | backend-dev and frontend-dev Tools tables |
| Coverage thresholds | `dev-core/references/workflow-details.md` |
| Folder structure | backend-dev and frontend-dev Architecture sections |
| Branch and PR rules | `dev-core/references/workflow-details.md` |
| CI platform and cloud | ship-and-operate CI/CD and IaC sections |
| SLO targets | `ship-and-operate/references/release-and-rollback.md` |
| Analytics naming convention | `frontend-dev/references/product-quality.md` |

## Versioning and releases

The version is the first `## x.y.z` heading in [CHANGELOG.md](https://github.com/Singhak/dev-skills/blob/master/CHANGELOG.md). The package scripts stamp it into the `.skill` filenames. When releasing, update the changelog, then tag the commit to match:

```bash
git tag v1.1.1 && git push --tags
```
