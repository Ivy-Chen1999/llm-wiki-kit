---
name: cross-linker
description: >
  Scan the Obsidian wiki and automatically discover missing cross-references between pages.
  Use this skill when the user says "link my pages", "find missing links", "cross-reference",
  "connect my wiki", "add wikilinks", "what pages should be linked", or after any large ingestion
  to ensure new pages are woven into the existing knowledge graph. Also trigger when the user
  mentions "orphan pages" in the context of wanting to connect them, or says things like
  "my wiki feels disconnected" or "pages aren't linked well". This is a write-heavy skill —
  it actually modifies pages to add links, unlike wiki-lint which just reports issues.
---

# Cross-Linker — Automated Wiki Cross-Referencing

You are weaving the wiki's knowledge graph tighter by finding and inserting missing `[[wikilinks]]` between pages that should reference each other but currently don't.

**Follow the Retrieval Primitives table in `llm-wiki/SKILL.md`.** Build the registry in Step 1 by grepping frontmatter only (not full pages). Reserve full `Read` for the unlinked-mention detection pass, and even there, only read pages whose summaries/titles make them plausible link targets. Blind full-vault reads are what this framework exists to avoid.

## Before You Start

1. Resolve the vault path (precedence, highest first): the `OBSIDIAN_VAULT_PATH` environment variable if set, else a `.env` in the current working directory (vault-scoped), else `~/.obsidian-wiki/config` (global default).
2. Read `_system/index.md` to get the full inventory of pages and their one-line descriptions
3. Skim `_system/log.md` to see what was recently ingested (focus linking effort on new pages)

## Step 1: Build the Page Registry

All knowledge notes live flat in `notes/`. Glob every `.md` file under `notes/` (skip `_archives/`, `_visual/`, `_system/`, and `.obsidian/`). For each page, extract:

- **Filename** (without `.md`) — this is the wikilink target, a bare basename
- **Title** from frontmatter
- **Aliases** from frontmatter (if any)
- **Tags** from frontmatter
- **Category** from the frontmatter `category:` field (`concept | entity | reference | insight | synthesis`)
- **One-line summary** — first sentence or `title` field

Build a lookup table:

```
page_name → { path, title, aliases, tags, summary }
```

This is your "vocabulary" — every entry in this table is a valid wikilink target.

## Step 2: Scan for Missing Links

For each page in the vault:

1. **Read the full content**
2. **Extract existing wikilinks** — find all `[[...]]` references already present
3. **Search for unlinked mentions** — check if the page's text contains any of these, without being wrapped in `[[...]]`:
   - Page filenames (e.g., the word "MyProject" appears but `[[my-project]]` is missing)
   - Page titles from frontmatter
   - Aliases from frontmatter
   - Entity names, project names, concept names from the registry

4. **Check for semantic connections** — pages that share multiple tags, or share the same `project:` frontmatter value, but don't link to each other

### Matching Rules

- **Case-insensitive matching** for names (e.g., "my-project" matches page `MyProject`)
- **Diacritic-insensitive matching** — normalize both the page name and the body text with Unicode NFKD (decompose accented characters to base + combining marks, strip combining marks) before comparing. This ensures body text "Muller" matches page `[[müller]]` and vice versa.
- **Skip self-references** — a page shouldn't link to itself
- **Skip common words** — don't link "the", "and", generic terms. Only match on distinctive names
- **Always use bare basenames** — write `[[page-name]]`, never a folder-qualified path. The vault is flat and basenames are unique, so Obsidian resolves them directly. If you encounter a legacy folder-qualified link such as `[[concepts/page-name]]` or `[[entities/page-name]]`, rewrite it in place to bare `[[page-name]]`.
- **Don't link inside code blocks** or frontmatter
- **Don't double-link** — if `[[foo]]` already appears on the page, don't add another

## Step 3: Score and Rank Suggestions

Not every possible link is worth adding. Score each candidate using a composite signal, then tag it with a confidence label.

### Scoring

| Signal | Points | Example |
|---|---|---|
| **Exact name match in text** | +4 | "MyProject" appears in body text → link to my-project.md |
| **Shared tags (2+)** | +2 | Both tagged `#ai #agent` but no link between them |
| **Same project, no link** | +2 | Both carry the same `project:` frontmatter value but don't reference each other |
| **Mentioned entity/concept** | +2 | Page mentions "knowledge graphs" → link to `[[knowledge-graphs]]` |
| **Cross-category connection** | +2 | Source has `category: concept`, target has `category: entity` (or `insight` ↔ `synthesis`) — different knowledge layers make this link more architecturally valuable |
| **Peripheral→hub reach** | +2 | Source page has ≤ 2 total links (peripheral) but target has ≥ 8 (hub) — connecting a loose page to a load-bearing concept |
| **Partial name match** | +1 | "graph" appears but page is `knowledge-graphs` — plausible but ambiguous |

### Confidence labels

Tag each candidate with a confidence label based on its score:

| Score | Label | Action |
|---|---|---|
| ≥ 6 | **EXTRACTED** | Link is effectively certain — exact mention or very strong match. Apply inline. |
| 3–5 | **INFERRED** | Link is a reasonable inference — shared context, cross-category, peripheral→hub. Apply inline or as Related section. |
| 1–2 | **AMBIGUOUS** | Weak or partial match. Skip unless user specifically asks to connect loose pages. |

Only act on **EXTRACTED** and **INFERRED** candidates. Include the confidence label in the Cross-Link Report so the user can review INFERRED links before trusting them.

## Step 4: Apply Links

For each page with missing links:

### 4a: Inline linking (preferred)

Find the first natural mention of the term in the body text and wrap it in wikilinks:

**Before:**
```markdown
This project uses knowledge graphs to connect entities.
```

**After:**
```markdown
This project uses [[knowledge-graphs|knowledge graphs]] to connect entities.
```

Use the `[[basename|display text]]` format when the target basename differs from the display text.

### 4b: Related section (fallback)

If the term isn't mentioned naturally in the body but the pages are semantically related (shared tags, same project), add a `## Related` section at the bottom of the page:

```markdown
## Related

- [[my-project]] — Also uses AI agents for research automation
- [[knowledge-graphs]] — Core technique used in this project
```

If a `## Related` section already exists, append to it. Don't duplicate existing entries.

## Step 5: Report

Present a summary:

```markdown
## Cross-Link Report

### Links Added: 23 across 12 pages

| Page | Links Added | Confidence | Type |
|---|---|---|---|
| `notes/my-project.md` | 3 | EXTRACTED | 2 inline, 1 related |
| `notes/jane-doe.md` | 5 | INFERRED | 3 inline, 2 related |
| ... | | | |

### Orphan Pages Remaining: 2
- `notes/foo.md` — no incoming or outgoing links found
- `notes/bar.md` — could not find related pages

### Pages Skipped: 3
- `_system/index.md`, `_system/log.md` — bookkeeping files
- `_archives/*` — archived content
```

## Step 6: Update Log and Hot Cache

Append to `_system/log.md`:
```
- [TIMESTAMP] CROSS_LINK pages_scanned=N links_added=M pages_modified=P orphans_remaining=Q
```

**`_system/hot.md`** — Read `$OBSIDIAN_VAULT_PATH/_system/hot.md` (create from the template in `wiki-ingest` if missing). Update **Recent Activity** with a one-line summary of what was linked — e.g. "Cross-linked 23 mentions across 12 pages; 2 orphans remain." Keep the last 3 operations. Update `updated` timestamp.

## Tips

- **Run after every ingest.** New pages are almost always poorly connected. This is the fix.
- **Be conservative with inline links.** Only link the first natural mention, not every occurrence.
- **Don't touch pages in `_archives/`.** Those are frozen snapshots.
- **Respect existing structure.** If a page carefully curates its links in a `## Key Concepts` section, add to that section rather than creating a separate `## Related`.
- **Entity pages are link magnets.** An entity like `jane-doe` should be linked from almost every project page. Prioritize these.
