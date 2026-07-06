---
name: wiki-setup
description: >
  Initialize a new Obsidian wiki vault with the correct structure, special files, and configuration.
  Use this skill when the user wants to set up a new wiki from scratch, initialize the vault structure,
  create the .env file, or says things like "set up my wiki", "initialize obsidian", "create a new vault",
  "get started with the wiki". Also use when the user needs to reconfigure their existing vault or
  fix a broken setup.
---

# Obsidian Setup — Vault Initialization

You are setting up a new Obsidian wiki vault (or repairing an existing one).

## Step 1: Create .env

If `.env` doesn't exist, create it from `.env.example`. Ask the user for:

1. **Where should the vault live?** → `OBSIDIAN_VAULT_PATH`
   - Default: `~/Documents/obsidian-wiki-vault`
   - Must be an absolute path (after expansion)

2. **Where are your source documents?** → `OBSIDIAN_SOURCES_DIR`
   - Can be multiple paths, comma-separated
   - Default: `~/Documents`

3. **Want to import Claude history?** → `CLAUDE_HISTORY_PATH`
   - Default: auto-discovers from `~/.claude`
   - Set explicitly if Claude data is elsewhere

4. **Have QMD installed?** → `QMD_WIKI_COLLECTION` / `QMD_PAPERS_COLLECTION`
   - Optional. Enables semantic search in `wiki-query` and source discovery in `wiki-ingest`.
   - If unsure, skip for now — both skills fall back to `Grep` automatically.
   - Install instructions: see `.env.example` (QMD section).

## Step 2: Create Vault Directory Structure

This vault is **flat**: every knowledge note lives directly in `notes/`, and a note's type is set by its YAML frontmatter `category:` (`concept | entity | reference | insight | synthesis`) — never by which folder it sits in. Create exactly these directories:

```bash
mkdir -p "$OBSIDIAN_VAULT_PATH"/{notes,raw,journal,Templates,_system,_archives,.obsidian}
```

- `notes/` — Every knowledge note lives here, flat. Type comes from frontmatter `category:`, not from a subfolder. Do NOT create per-type folders like `concepts/` or `entities/`.
- `raw/` — Staging area for unprocessed drafts. Drop rough notes here; `wiki-ingest` will promote them into `notes/` (with the right `category:`) and delete the originals. Honors `OBSIDIAN_RAW_DIR` if set (default `raw`).
- `journal/` — Daily notes and dated entries.
- `Templates/` — Note templates used when creating new pages.
- `_system/` — Bookkeeping lives here: `index.md`, `hot.md`, `log.md`, `tags.md`.
- `_archives/` — Stores wiki snapshots for rebuild/restore operations.
- `.obsidian/` — Obsidian's own config. Creates vault recognition.

## Step 3: Create Special Files

All bookkeeping files live under `_system/`, never at the vault root.

### _system/index.md

The index groups notes by their frontmatter `category:` — these are heading sections in one file, not folders on disk.

```markdown
---
title: Wiki Index
---

# Wiki Index

*This index is automatically maintained. Last updated: TIMESTAMP*

## Concepts

*No pages yet. Use `wiki-ingest` to add your first source.*

## Entities

## References

## Insights

## Synthesis

## Journal
```

### _system/log.md

```markdown
---
title: Wiki Log
---

# Wiki Log

- [TIMESTAMP] INIT vault_path="OBSIDIAN_VAULT_PATH" layout=flat categories=concept,entity,reference,insight,synthesis
```

### _system/hot.md

```markdown
---
title: Hot Cache
updated: TIMESTAMP
---

# Hot Cache

*A ~500-word semantic snapshot of recent activity. Updated after every major write operation.*

## Recent Activity

- [TIMESTAMP] INIT — vault created at OBSIDIAN_VAULT_PATH

## Active Threads

*None yet — start ingesting sources to populate.*

## Key Takeaways

*None yet.*

## Flagged Contradictions

*None yet.*
```

### _system/tags.md

The tag whitelist. New notes may only use tags listed here — add a tag to this file before using it.

```markdown
---
title: Tag Whitelist
---

# Tag Whitelist

Only tags listed below may be used on new notes. Add a tag here before applying it.

## Tags

*No tags yet. Add tags as your vault grows.*
```

## Step 4: Create .obsidian Configuration

Create minimal Obsidian config for a good out-of-box experience:

### .obsidian/app.json
```json
{
  "strictLineBreaks": false,
  "showFrontmatter": false,
  "defaultViewMode": "preview",
  "livePreview": true
}
```

### .obsidian/appearance.json
```json
{
  "baseFontSize": 16
}
```

## Step 5: Recommend Obsidian Plugins

Tell the user about these recommended community plugins (they install manually):

1. **Dataview** — Query page metadata, create dynamic tables. Essential for a wiki.
2. **Graph Analysis** — Enhanced graph view for exploring connections.
3. **Templater** — If they want to create pages manually using templates.
4. **Obsidian Git** — Auto-backup the vault to a git repo.

## Step 6: Verify Setup

Run a quick sanity check:
- [ ] Vault directory exists with: `notes/`, `raw/`, `journal/`, `Templates/`, `_system/`, `_archives/`, `.obsidian/`
- [ ] `_system/index.md` exists
- [ ] `_system/log.md` exists
- [ ] `_system/hot.md` exists
- [ ] `_system/tags.md` exists
- [ ] `.env` has `OBSIDIAN_VAULT_PATH` set
- [ ] `.obsidian/` directory exists
- [ ] Source directories (if configured) exist and are readable

Report the results and tell the user they can now:
1. Open the vault in Obsidian (File → Open Vault → select the directory)
2. Run `wiki-status` to see what's available to ingest
3. Run `wiki-ingest` to add their first sources
4. Run `claude-history-ingest` to mine their Claude conversations
5. Run `codex-history-ingest` to mine their Codex sessions (if they use Codex)
6. Run `wiki-status` again anytime to check the delta
