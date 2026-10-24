---
title: Home
layout: home
nav_order: 1
permalink: /
---

# Fullstack Dev Skills Pack
{: .fs-9 }

Six agent skills that make a coding agent work like a disciplined senior fullstack engineer: tests first, security on every change, attacking its own code, clean integration between UI and server, and safe release and operations.
{: .fs-6 .fw-300 }

[Get started]({{ '/getting-started/' | relative_url }}){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/Singhak/dev-skills){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## What's in the pack

| Skill | Phase | Loaded when |
|---|---|---|
| [`dev-core`]({{ '/skills/dev-core/' | relative_url }}) | Every code change | Always, on any coding task (also holds the routing table) |
| [`backend-dev`]({{ '/skills/backend-dev/' | relative_url }}) | Build: server | Server code, APIs, DB, migrations, jobs, data/system design |
| [`frontend-dev`]({{ '/skills/frontend-dev/' | relative_url }}) | Build: UI | Components, pages, forms, client state, UX/product quality |
| [`fullstack-integration`]({{ '/skills/fullstack-integration/' | relative_url }}) | Connect | Work touching both sides of an API, contract changes, stale data / type / error-handling bugs |
| [`ship-and-operate`]({{ '/skills/ship-and-operate/' | relative_url }}) | Release & run | CI/CD, Docker, IaC, env/secrets, health checks, flags, rollout/rollback, SLOs |
| [`debug-production`]({{ '/skills/debug-production/' | relative_url }}) | Fix in prod | Bugs and incidents in deployed environments |

The skills use the open **Agent Skills** format (a folder with a `SKILL.md`), so the same files work in Claude Code, Claude.ai, OpenAI Codex, Cursor, GitHub Copilot, Google Antigravity and other agents that support the standard.

## Principles

- **Tests first.** Red, green, refactor. A bug fix starts with a failing test that reproduces it.
- **Security on every change.** A five-action security pass on the diff, plus a full checklist for high-risk work.
- **Break it.** After building, the agent switches roles and attacks its own feature (only locally or in test environments it controls), then turns every successful attack into a test and a fix.
- **No evidence, no claim.** Every check is reported with its command and observed result. Anything that didn't run is reported as "not verified".
- **Stop and hand back.** The agent returns control when it's done, blocked, needs a decision, would cross a risk line, or has failed three times on the same problem.
- **Production is read-only.** No deploys, infrastructure applies, migrations or production data changes without explicit approval in the conversation.

## Quick start

```bash
git clone https://github.com/Singhak/dev-skills.git
cd dev-skills
./install.sh /path/to/your-repo          # macOS / Linux / WSL
```

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Repo C:\path\to\your-repo   # Windows
```

Then ask your agent "which skills do you have available?" to confirm. Full platform details are in [Getting started]({{ '/getting-started/' | relative_url }}).
