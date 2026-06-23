---
name: my-digest
description: >
  Build a daily digest: collect open todos from across the vault, search for the latest news in
  the user's field, and save a dated report to the journal folder. Use when the user says
  "give me today's digest", "daily digest", "/my-digest", or "what's new + my todos".
  EXAMPLE skill — copy to ~/.claude/skills/<name> and adapt the topics and format.
---

# Daily Digest

Generate a dated digest combining the user's open todos and the latest news in their field, saved to the wiki's journal.

## Before You Start

1. Read `~/.obsidian-wiki/config` (fall back to `.env`) to get `OBSIDIAN_VAULT_PATH`.
2. Output goes to `$OBSIDIAN_VAULT_PATH/journal/<YYYY-MM-DD>-digest.md`.

## Step 1: Collect open todos

Grep the vault for unchecked todos (`- [ ]`) across notes and any `todo.md`. Group them by area (e.g. work / learning / life) however suits the user.

## Step 2: Search for the latest news

Run web searches for the user's chosen topics (edit this list to your field). Apply a consistent lens: what's genuinely new, what matters, what to act on.

## Step 3: Verify before including

For each item you'd report, confirm it against a real source (fetch the page). Drop anything you can't verify — a smaller, correct digest beats a large, wrong one. Note how many items you dropped.

## Step 4: Compile and save

Write `$OBSIDIAN_VAULT_PATH/journal/<YYYY-MM-DD>-digest.md`:

```markdown
---
title: Digest <YYYY-MM-DD>
category: journal
tags: [journal, digest]
created: <YYYY-MM-DD>
---

# Digest <YYYY-MM-DD>

## Open todos

- ...

## What's new in <your field>

### <item title>
- summary + why it matters + source link

## Worth a deeper look

- ...
```

## Step 5: Report to the user

Tell them where it saved (`[[journal/<YYYY-MM-DD>-digest]]`), how many news items passed verification, and how many were dropped.

## Notes

- Edit the topic list in Step 2 to your field — that's the main thing to personalize.
- Keep the verification gate in Step 3; it's what keeps the digest trustworthy.
