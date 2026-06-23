---
name: my-retro
description: >
  Generate a project retrospective from the current project directory and save it into the
  wiki's project folder. Use when the user says "write a retro", "project retrospective",
  "retro this project", "/my-retro", or wants a structured post-mortem of a codebase.
  EXAMPLE skill — copy to ~/.claude/skills/<name> and adapt the format to your taste.
---

# Project Retro

Read the code and docs in the current project directory, then write a structured retrospective into the wiki's `project/` folder.

## Before You Start

1. Read `~/.obsidian-wiki/config` (fall back to `.env`) to get `OBSIDIAN_VAULT_PATH`. Don't hardcode a path.
2. Output goes to `$OBSIDIAN_VAULT_PATH/project/<project-name>.md`.

## Step 1: Gather project basics

Infer the project name from the directory name or the first line of `README` / `package.json` / `pyproject.toml`.

Read what exists (skip what doesn't):
- `README.md`
- `package.json` / `pyproject.toml` / `Cargo.toml` (for the stack)
- main docs under `docs/`
- `git log --oneline -20` (for the development arc)
- the main entry files (`src/main.py`, `src/index.ts`, `app.py`, …)

Goal: understand what the project does, what it's built with, and its main modules.

## Step 2: Analyze

From what you read, work out:
- One sentence: what problem does this project solve?
- Stack: main languages, frameworks, tools.
- What went well: architecture/engineering choices worth keeping.
- What went badly: tech debt, design mistakes, traps hit.
- Key decisions: important choices, why, and the trade-off.
- Submodules: if there are several, analyze each.
- Reusable bits: patterns/tools/designs you could lift next time.

## Step 3: Write to the vault

Write `$OBSIDIAN_VAULT_PATH/project/<project-name>.md`:

```markdown
---
project: <name>
started: <YYYY-MM, inferred from git log>
ended: <YYYY-MM or blank>
stack: [main technologies]
tags: [project]
status: done
type: own
summary: <one line, <= 100 chars>
---

# <name> — Retrospective

## In one sentence

> 

## What went well

> 

## What went badly / traps

> 

## Stack & key decisions

| Tech / tool | Why chosen | Trade-off | Reuse next time |
|---|---|---|---|
|  |  |  | yes / no |

## Submodules

<delete this section if there's only one module>

## Reusable bits

<concrete patterns, not generalities>

## Resources

- Repo: <path or URL>
```

## Step 4: Tell the user

Tell them where the file landed (`[[project/<name>]]`), and suggest running `wiki-ingest` on the "Reusable bits" section so those patterns get distilled into `notes/`.

## Notes

- No emoji.
- Adapt the output format freely — this is a starting point, not a fixed schema.
