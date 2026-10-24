---
title: Skills
nav_order: 4
has_children: true
permalink: /skills/
---

# Skills

Each skill is a folder with a `SKILL.md` (the instructions the agent loads) and a `references/` folder (depth the agent opens only when a step needs it). `dev-core` always loads. The others add layer-specific steps, Verify rows and stop rules on top of it.

Every layer skill has two levels:

- **Default**: the minimum checks for an ordinary change in that layer.
- **High-risk**: extra checks for auth, money, personal data, contracts, migrations, concurrency or production releases.
