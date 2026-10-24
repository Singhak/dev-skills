# Dev Skills Pack — dev-core · backend-dev · frontend-dev

Three agent skills that make any coding agent work like a disciplined senior engineer: TDD first, the right test pyramid, security checks on every change, and a clear definition of done.

| Skill | Role | Load when |
|---|---|---|
| `dev-core` | Universal workflow: understand → plan → TDD → security → quality gates → **break it (hacker mode)** → self-review → report | Every coding task |
| `backend-dev` | Architecture, API design, unit/integration/contract/API e2e tests, migrations, OWASP API Top 10, observability | Server, API, DB, jobs, CLIs |
| `frontend-dev` | Component architecture, Testing Library + MSW, Playwright e2e, a11y (WCAG 2.2), XSS/CSP/token security, Core Web Vitals | UI, components, browser |

Full-stack task → load all three.

## Structure
```
dev-core/      SKILL.md, references/{tdd,security-checklist,code-review,project-discovery}.md, scripts/security_scan.sh
backend-dev/   SKILL.md, references/{backend-testing,backend-security}.md
frontend-dev/  SKILL.md, references/{frontend-testing,frontend-security}.md
```

## Installing

**Claude Code** — copy folders into `~/.claude/skills/` (personal) or `<repo>/.claude/skills/` (shared with the team).

**Claude.ai / Claude Desktop** — upload each `.skill` file (or zip each folder) under Settings → Capabilities → Skills.

**Claude API / Agent SDK** — upload via the Skills API, or place in the agent's skills directory.

**Other agents (Cursor, Codex, Copilot, Windsurf, Aider, Gemini CLI, etc.)** — the files are plain Markdown:
- Put the folders in `docs/agent-skills/` in your repo, and
- Add to `AGENTS.md` / `.cursor/rules/*.mdc` / `.github/copilot-instructions.md` / `CLAUDE.md`:
  > Before any code change, read `docs/agent-skills/dev-core/SKILL.md`. For backend work also read `backend-dev/SKILL.md`; for frontend work, `frontend-dev/SKILL.md`. Open the referenced files under `references/` when relevant.

## Customizing for your team
Edit these first so the agent follows *your* conventions:
- Preferred stack and test runners (sections "Tools" in backend/frontend skills)
- Coverage thresholds and required gates (dev-core Step 6)
- Folder structure (Architecture sections)
- Commit message convention (dev-core §3)
Keep each SKILL.md under ~500 lines; push detail into `references/`.
