# Installing the Skills Pack — Full Platform Guide

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

The install scripts do all of this:
```bash
./install.sh /path/to/your-repo          # macOS / Linux / WSL (add --copy to copy instead of link)
```
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Repo C:\path\to\your-repo  # Windows: junction (no admin); add -Copy to copy
```
Windows notes: PowerShell blocks unsigned scripts by default, hence `-ExecutionPolicy Bypass` (this run only). In Git Bash, `ln -s` silently makes a copy unless Developer Mode is enabled, so `install.sh` switches to `--copy` automatically there. Junctions and symlinks don't travel through git to other operating systems; each teammate runs the install script for their OS, or the team commits copies in both folders.

`AGENTS.md` line (helps agents that don't auto-load skills, and reinforces routing for those that do):
> For every coding task, read `.agents/skills/dev-core/SKILL.md` first and follow its routing table to decide which other skills in `.agents/skills/` to read.

### Platform reference
| Platform | Project (repo) location | Personal (all projects) | Notes |
|---|---|---|---|
| **Claude Code** | `.claude/skills/` | `~/.claude/skills/` | Does not read `.agents/skills/`, hence the link. Also reads `CLAUDE.md`. |
| **Claude.ai / Claude Desktop** | — | Build with `./package.sh` or `powershell -ExecutionPolicy Bypass -File .\package.ps1`, then upload each `dist/*.skill` in Settings → Capabilities → Skills | No repo folders; upload per user/org. |
| **OpenAI Codex** (CLI, IDE extension, app) | `.agents/skills/` (scanned from the working directory up to the repo root) | `~/.agents/skills/` | Reads `AGENTS.md`. Disable a skill via `[[skills.config]]` in `~/.codex/config.toml`. |
| **Cursor** | `.agents/skills/` or `.cursor/skills/` | `~/.agents/skills/` or `~/.cursor/skills/` | Also reads `.claude/skills/`. Invoke manually with `/skill-name`. For Cloud Agents, use repo skills (personal `~/.agents/skills/` isn't copied there). |
| **Google Antigravity** (app / IDE) | `.agents/skills/` | `~/.gemini/config/skills/` (legacy `~/.gemini/antigravity/skills/`) | Check active skills in the agent panel's Customizations menu; invoke with `/skill-name`. |
| **Antigravity CLI** (`agy`) | `.agents/skills/` | `~/.gemini/antigravity-cli/skills/` | Skills become slash commands automatically. |
| **GitHub Copilot** (VS Code, Visual Studio, JetBrains agent mode, Copilot CLI, cloud agent) | `.agents/skills/`, `.github/skills/` or `.claude/skills/` | `~/.agents/skills/` or `~/.copilot/skills/` | Copilot CLI: `/skills reload` after adding. Recent Copilot CLI versions no longer load `~/.claude/skills/`. |
| **Other agents** (Windsurf, OpenCode, Kiro, Gemini CLI, etc.) | `.agents/skills/` if they support the Agent Skills standard | see the tool's docs | If the tool has no skills support, the `AGENTS.md` line (or its own rules file) points it to the files. |

Skill locations change as these tools evolve, so check the platform's current docs if a skill doesn't show up. Quick test after installing: ask the agent "which skills do you have available?" or invoke `/dev-core` where slash commands are supported.

### Personal install (all your projects, no repo changes)
Copy the six folders to your platform's personal location from the table, e.g. `~/.agents/skills/` (Codex, Cursor, Copilot) plus `~/.claude/skills/` (Claude Code) and `~/.gemini/config/skills/` (Antigravity). Prefer the repo setup for teams so everyone runs the same version.

