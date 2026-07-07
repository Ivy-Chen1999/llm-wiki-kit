# Contributing

Thanks for helping improve llm-wiki-kit. It's a set of agent **skills** (instruction files) plus a
starter vault — most contributions are prose edits to `skills/*/SKILL.md`, not code.

## Ground rules

- **One vault model.** Notes are flat in `notes/`; a note's type is frontmatter `category:`
  (`concept | entity | reference | insight | synthesis`). Bookkeeping lives in `_system/`, staging in
  `raw/`. Don't reintroduce per-category folders (`concepts/`, `entities/`, …).
- **Clone-and-go.** No hardcoded absolute paths, no personal names, no non-English text in shipped
  files. Skills resolve the vault via `OBSIDIAN_VAULT_PATH` → `.env` → `~/.obsidian-wiki/config`.
- **Source discipline.** Any skill that writes claims must reference the `wiki-sourcing` doctrine.
- **Non-destructive install.** `install.sh` only adds skills and writes `~/.obsidian-wiki/config`;
  it must never touch a user's existing skills, `settings.json`, `CLAUDE.md`, or plugins.

## Before you open a PR

```bash
bash scripts/check.sh          # deterministic hygiene gate (also runs in CI)
```

If you changed skill behavior, add or update an eval case and run it:

```bash
./install.sh                                   # so the agent-under-test loads the skills
evals/run_all.sh 3                             # every case × 3 runs, reports pass-rate
# or a single case: evals/run_case.sh <case>
```

See [`evals/README.md`](evals/README.md) for how cases work and how to add one.

## Adding or changing a skill

1. Keep the `name`/`description` frontmatter; make the `description` triggers specific to that skill's
   lane so it doesn't collide with siblings (see the three `*-ingest` skills for the pattern).
2. If the skill writes notes, wire in the `wiki-sourcing` pointer + a Quality-Checklist line.
3. Update the skill table in `README.md` (CI checks the count matches `skills/`).
4. Add a line to `CHANGELOG.md` under **Unreleased**.

## Commit style

Conventional commits (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `ci:`). Keep PRs focused.
