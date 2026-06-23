# Personal skills — make it your own

The 20 skills in [`../skills/`](../skills/) are the **shared core**: ingesting, querying, linting, linking. They're meant to work the same for everyone.

But the most useful skills are usually the ones shaped around *your* workflow — and those are personal. This folder holds templates and examples so you can add your own without starting from scratch.

Two common ones people build:

- **A retro skill** — point it at a project and have it write a structured retrospective into your vault. See [`retro.example/SKILL.md`](retro.example/SKILL.md).
- **A digest skill** — pull your open todos + the latest news in your field into a dated journal entry. See [`digest.example/SKILL.md`](digest.example/SKILL.md).

You might also want a personal **ingest house-style** (how *you* like sources distilled — tone, length, what to always capture) or a **dispatcher** that routes "/wiki do X" to the right skill.

## How to add one

A skill is just a folder with a `SKILL.md` file. Claude discovers it from the frontmatter `name` + `description`.

```bash
# 1. Copy a template or example into your skills directory
cp -R personal-skills/retro.example ~/.claude/skills/my-retro

# 2. Edit it — change the name, the steps, the output format to taste
$EDITOR ~/.claude/skills/my-retro/SKILL.md

# 3. That's it. Next Claude session, it's available.
```

Start from [`SKILL.template.md`](SKILL.template.md) for a blank one, or copy an example and tweak.

## Tips

- **Keep personal skills out of this repo.** They live in `~/.claude/skills/`, not here — so a `git pull` to update the shared core never touches your custom ones.
- **`description` is what triggers it.** List the phrases you'd actually say ("write a retro", "give me today's digest").
- **Reuse the core.** A personal skill can call the shared skills — e.g. a retro skill can end by telling you to run `wiki-ingest` on the result.
- **Resolve the vault path the same way** as the core skills: read `~/.obsidian-wiki/config` (fall back to `.env`) to get `OBSIDIAN_VAULT_PATH`. Don't hardcode a path.
