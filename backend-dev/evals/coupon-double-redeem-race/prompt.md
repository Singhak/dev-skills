---
tags: [dev-skills, backend-dev]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Add a POST /coupons/:code/redeem endpoint. Each coupon can be redeemed once per user, and a coupon has a limited number of total redemptions.

Input files: package.json, src/db.js, src/app.js
