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
Understand → plan (risk, flag check, design note) → TDD → right test levels → security pass → quality gates → **break it (hacker mode)** → self-review → report/PR description

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
All six skills use the open **Agent Skills** format (a folder with a `SKILL.md`), so the same files work on every platform below. Only the folder location differs.

### Recommended: one repo setup for every agent
Keep the real files in the vendor-neutral `.agents/skills/` folder, link `.claude/skills/` to it for Claude Code, and commit both:

```
your-repo/
  .agents/skills/                     # real files: Codex, Cursor, Copilot, Antigravity, others
    dev-core/  backend-dev/  frontend-dev/
    fullstack-integration/  ship-and-operate/  debug-production/
  .claude/skills -> ../.agents/skills # link for Claude Code
  AGENTS.md                           # one routing line (below)
```

The included script does all of this:
```bash
./install.sh /path/to/your-repo          # copies skills, creates the link, updates AGENTS.md
./install.sh /path/to/your-repo --copy   # use a real copy instead of a link
```
Windows: symlinks need Developer Mode or admin rights; otherwise use `--copy` (in Git Bash/WSL) or copy the folders into both locations manually.

`AGENTS.md` line (helps agents that don't auto-load skills, and reinforces routing for those that do):
> For every coding task, read `.agents/skills/dev-core/SKILL.md` first and follow its routing table to decide which other skills in `.agents/skills/` to read.

### Platform reference
| Platform | Project (repo) location | Personal (all projects) | Notes |
|---|---|---|---|
| **Claude Code** | `.claude/skills/` | `~/.claude/skills/` | Does not read `.agents/skills/`, hence the link. Also reads `CLAUDE.md`. |
| **Claude.ai / Claude Desktop** | — | Upload each `.skill` file: Settings → Capabilities → Skills | No repo folders; upload per user/org. |
| **OpenAI Codex** (CLI, IDE extension, app) | `.agents/skills/` (scanned from the working directory up to the repo root) | `~/.agents/skills/` | Reads `AGENTS.md`. Disable a skill via `[[skills.config]]` in `~/.codex/config.toml`. |
| **Cursor** | `.agents/skills/` or `.cursor/skills/` | `~/.agents/skills/` or `~/.cursor/skills/` | Also reads `.claude/skills/`. Invoke manually with `/skill-name`. For Cloud Agents, use repo skills (personal `~/.agents/skills/` isn't copied there). |
| **Google Antigravity** (app / IDE) | `.agents/skills/` | `~/.gemini/config/skills/` (legacy `~/.gemini/antigravity/skills/`) | Check active skills in the agent panel's Customizations menu; invoke with `/skill-name`. |
| **Antigravity CLI** (`agy`) | `.agents/skills/` | `~/.gemini/antigravity-cli/skills/` | Skills become slash commands automatically. |
| **GitHub Copilot** (VS Code, Visual Studio, JetBrains agent mode, Copilot CLI, cloud agent) | `.agents/skills/`, `.github/skills/` or `.claude/skills/` | `~/.agents/skills/` or `~/.copilot/skills/` | Copilot CLI: `/skills reload` after adding. Recent Copilot CLI versions no longer load `~/.claude/skills/`. |
| **Other agents** (Windsurf, OpenCode, Kiro, Gemini CLI, etc.) | `.agents/skills/` if they support the Agent Skills standard | see the tool's docs | If the tool has no skills support, the `AGENTS.md` line (or its own rules file) points it to the files. |

Skill locations change as these tools evolve, so check the platform's current docs if a skill doesn't show up. Quick test after installing: ask the agent "which skills do you have available?" or invoke `/dev-core` where slash commands are supported.

### Personal install (all your projects, no repo changes)
Copy the six folders to your platform's personal location from the table, e.g. `~/.agents/skills/` (Codex, Cursor, Copilot) plus `~/.claude/skills/` (Claude Code) and `~/.gemini/config/skills/` (Antigravity). Prefer the repo setup for teams so everyone runs the same version.

## Customize first
Preferred stack and tools, coverage thresholds, folder structure, branch/PR rules, CI platform and cloud, SLO targets, analytics naming convention.

## Safety defaults
The agent attacks only its own code in local/test environments, and never deploys, applies infrastructure, runs migrations or touches production data without explicit approval in the conversation.
