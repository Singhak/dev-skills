---
title: Getting started
nav_order: 2
permalink: /getting-started/
---

# Getting started
{: .no_toc }

1. TOC
{:toc}

---

## Recommended setup: one repo layout for every agent

Keep the real files in the vendor-neutral `.agents/skills/` folder, link `.claude/skills/` to it for Claude Code, and add one line to `AGENTS.md`. Commit all three so your whole team runs the same version.

```
your-repo/
  .agents/skills/                     # real files: Codex, Cursor, Copilot, Antigravity, others
    dev-core/  backend-dev/  frontend-dev/
    fullstack-integration/  ship-and-operate/  debug-production/
  .claude/skills -> ../.agents/skills # link for Claude Code
  AGENTS.md                           # one routing line (below)
```

The install scripts do all of this.

**macOS / Linux / WSL**

```bash
./install.sh /path/to/your-repo          # add --copy to copy instead of link
```

**Windows (PowerShell)**

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Repo C:\path\to\your-repo   # junction, no admin needed; add -Copy to copy
```

{: .note }
PowerShell blocks unsigned scripts by default. `-ExecutionPolicy Bypass` applies to that one run only and doesn't change your system settings. In Git Bash, `ln -s` silently makes a copy unless Developer Mode is on, so `install.sh` switches to `--copy` there automatically.

{: .warning }
Junctions and symlinks don't travel through git to other operating systems. Each teammate runs the install script for their OS, or the team commits copies in both folders.

The `AGENTS.md` line helps agents that don't auto-load skills and reinforces routing for those that do:

> For every coding task, read `.agents/skills/dev-core/SKILL.md` first and follow its routing table to decide which other skills in `.agents/skills/` to read.

## Claude.ai and Claude Desktop

These have no repo folders, so you upload packaged skills instead. Build versioned `.skill` files into `dist/` (for example `dev-core-1.1.1.skill`):

```bash
./package.sh                                              # macOS / Linux / Git Bash (uses zip, or Python if zip is missing)
```

```powershell
powershell -ExecutionPolicy Bypass -File .\package.ps1    # Windows PowerShell
```

Then upload each `dist/*.skill` file in **Settings → Capabilities → Skills**.

## Platform reference

| Platform | Project (repo) location | Personal (all projects) | Notes |
|---|---|---|---|
| **Claude Code** | `.claude/skills/` | `~/.claude/skills/` | Doesn't read `.agents/skills/`, hence the link. Also reads `CLAUDE.md`. |
| **Claude.ai / Claude Desktop** | — | Upload `dist/*.skill` in Settings → Capabilities → Skills | Upload per user or org. |
| **OpenAI Codex** (CLI, IDE, app) | `.agents/skills/` (scanned from the working directory up to the repo root) | `~/.agents/skills/` | Reads `AGENTS.md`. Disable a skill via `[[skills.config]]` in `~/.codex/config.toml`. |
| **Cursor** | `.agents/skills/` or `.cursor/skills/` | `~/.agents/skills/` or `~/.cursor/skills/` | Also reads `.claude/skills/`. Invoke manually with `/skill-name`. Cloud Agents need repo skills. |
| **Google Antigravity** (app / IDE) | `.agents/skills/` | `~/.gemini/config/skills/` | Check active skills in the agent panel's Customizations menu. |
| **Antigravity CLI** (`agy`) | `.agents/skills/` | `~/.gemini/antigravity-cli/skills/` | Skills become slash commands automatically. |
| **GitHub Copilot** (VS Code, Visual Studio, JetBrains, CLI, cloud agent) | `.agents/skills/`, `.github/skills/` or `.claude/skills/` | `~/.agents/skills/` or `~/.copilot/skills/` | Copilot CLI: `/skills reload` after adding. |
| **Other agents** (Windsurf, OpenCode, Kiro, Gemini CLI, …) | `.agents/skills/` if they support Agent Skills | See the tool's docs | Without skills support, the `AGENTS.md` line points the agent to the files. |

Skill locations change as these tools evolve. If a skill doesn't show up, check the platform's current docs. The full guide, including personal installs, is in [INSTALL.md](https://github.com/Singhak/dev-skills/blob/master/INSTALL.md).

## Check that it works

Ask the agent "which skills do you have available?", or invoke `/dev-core` where slash commands are supported. Then give it a small real task, such as adding an endpoint, and check that the final report includes an evidence table.
