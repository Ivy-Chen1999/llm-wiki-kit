---
name: my-skill
description: >
  One or two sentences on what this does, written so Claude knows when to run it.
  Include the exact phrases you'd say to trigger it, e.g. "do X", "give me Y",
  "/my-skill". Be specific — this is what makes the skill fire at the right time.
---

# My Skill

Briefly: what this skill produces and for whom.

## Before You Start

1. Read `~/.obsidian-wiki/config` (fall back to `.env`) to get `OBSIDIAN_VAULT_PATH`. Don't hardcode a path.
2. Read any context you need (`$OBSIDIAN_VAULT_PATH/_system/index.md`, recent notes, etc.).

## Step 1: <do the first thing>

...

## Step 2: <do the next thing>

...

## Step N: Write to the vault

Write the result to `$OBSIDIAN_VAULT_PATH/<folder>/<name>.md` with proper frontmatter
(`title`, `category`, `tags`, `created`, `updated`). Then update `_system/index.md`
and append a line to `_system/log.md` if your wiki tracks those.

## Notes

- Keep it focused — one skill, one job.
- Reuse the shared core skills where you can instead of re-implementing them.
