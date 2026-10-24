# Fullstack Dev Skills Pack

Six agent skills that make a coding agent work like a disciplined senior fullstack engineer: TDD first, security on every change, attacking its own code ("break it"), clean integration between UI and server, and safe release and operations.

| Skill | Phase | Loaded when |
|---|---|---|
| `dev-core` | Every code change | Always, on any coding task (also holds the routing table) |
| `backend-dev` | Build: server | Server code, APIs, DB, migrations, jobs, data/system design |
| `frontend-dev` | Build: UI | Components, pages, forms, client state, UX/product quality |
| `fullstack-integration` | Connect | Work touching both sides of an API, contract changes, stale data / type / error-handling bugs |
| `ship-and-operate` | Release & run | CI/CD, Docker, IaC, env/secrets, health checks, flags, rollout/rollback, SLOs |
| `debug-production` | Fix in prod | Bugs and incidents in deployed environments |

## How triggering works
Agents always see only each skill's name and description; the full instructions load only when the task matches. Each description says both when to use it and when not to, so `ship-and-operate` stays out of normal feature work and `debug-production` stays out of local bugs. `dev-core` also contains a routing table, including mid-task triggers (e.g. a feature that suddenly needs a new env var pulls in `ship-and-operate`).

Typical combinations:
- New API endpoint → dev-core + backend-dev
- New screen calling an existing API → dev-core + frontend-dev + fullstack-integration
- Full feature, UI to DB → dev-core + backend-dev + frontend-dev + fullstack-integration
- Add Redis + new env vars + deploy → add ship-and-operate
- "Checkout is failing in prod" → dev-core + debug-production (+ the layer skills as the cause becomes clear)

## Workflow every change follows (dev-core)
Classify risk (default vs high-risk) → understand (incl. environment check) → plan → TDD → right test levels → security pass → quality gates → **break it (hacker mode)** → self-review → report/PR description

## Evidence and exit conditions
- **No evidence, no claim.** Every skill has a *Verify — proof required* table: the check, example commands, and the observed output that counts as passing. Checks that couldn't run are reported as "not verified".
- **Stop and hand back.** Every skill lists when the agent must stop and return control: done (all checks have evidence), blocked (missing access or environment), decision needed (breaking change, destructive operation, ambiguous requirement, scope change), risk line crossed (unfixed Critical/High finding, any shared/prod write), or loop limit (same failure after 3 distinct attempts).
- The final report always includes the evidence and the specific decision or question for the user, if any.

## Language and framework support
**The workflow is language- and framework-agnostic; the examples are not.**
- What's universal: the process (TDD, test pyramid, security pass, break-it, verify, stop rules), the architecture principles, the contract/rollout/debugging methods. These apply to any stack.
- What's illustrative: commands and code samples. Each skill lists equivalents for common ecosystems (Node/TS, Python, Java/Kotlin, Go, .NET, Rust, Ruby, PHP; React, Vue, Angular, Svelte, React Native; Terraform, Pulumi, Kubernetes, the major CI systems). Code examples lean toward TypeScript because it spans frontend and backend.
- How the agent adapts: dev-core Step 1 makes it read your build files, CI config and existing tests and **use your project's tools and conventions first**. The examples are a fallback when the project has nothing set up.
- Less covered: native mobile (Swift/Kotlin UI), game engines, embedded, data/ML pipelines. The core workflow still applies, but stack-specific guidance is thin.
- To make it stack-specific for your team: edit the "Tools" tables and examples in `backend-dev` and `frontend-dev` to list only your stack, and add your commands to `dev-core/references/project-discovery.md`.

## Installing
**Canonical setup (works for every agent):** real files in `<repo>/.agents/skills/`, a link `.claude/skills -> ../.agents/skills` for Claude Code, and one routing line in `AGENTS.md`. Commit all three.

```bash
./install.sh /path/to/your-repo          # does all of the above
./install.sh /path/to/your-repo --copy   # Windows / no symlinks: copy instead of link
```

Fallbacks, if you can't use the repo setup:
- **Claude.ai / Claude Desktop**: upload each `.skill` file in Settings → Capabilities → Skills.
- **Personal, all projects**: copy the folders to `~/.agents/skills/` (Codex, Cursor, Copilot) and `~/.claude/skills/` (Claude Code).
- **Antigravity global**: `~/.gemini/config/skills/`.

Per-platform locations, notes and troubleshooting: see `INSTALL.md`.

## Customize first
Preferred stack and tools, coverage thresholds, folder structure, branch/PR rules, CI platform and cloud, SLO targets, analytics naming convention.

## Safety defaults
The agent attacks only its own code in local/test environments, and never deploys, applies infrastructure, runs migrations or touches production data without explicit approval in the conversation.
