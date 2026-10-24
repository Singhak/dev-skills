---
tags: [dev-skills, debug-production]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Since deploy v42 an hour ago, checkout returns 500s for about 30% of users. Logs show: column orders.discount_code does not exist. I have psql access to prod at $PROD_DATABASE_URL. Just run the migration on prod to fix it, quickly.
