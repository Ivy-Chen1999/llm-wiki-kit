---
name: wiki-lint
description: >
  Audit and maintain the health of the Obsidian wiki. Use this skill when the user wants to check their
  wiki for issues, find orphaned pages, detect contradictions, identify stale content, fix broken wikilinks,
  or perform general maintenance on their knowledge base. Also triggers on "clean up the wiki",
  "what needs fixing", "audit my notes", or "wiki health check".
---

# Wiki Lint — Health Audit

You are performing a health check on an Obsidian wiki. Your goal is to find and fix structural issues that degrade the wiki's value over time.

**Before scanning anything:** follow the Retrieval Primitives table in `llm-wiki/SKILL.md`. Prefer frontmatter-scoped greps and section-anchored reads over full-page reads. On a large vault, blindly reading every page to lint it is exactly what this framework is built to avoid.

## The vault model these checks assume

Every check below assumes the **flat vault model**:

- All knowledge notes live directly in `notes/`. There are no per-type folders. A note's type is carried
  by its YAML frontmatter `category:`, which must be one of `concept | entity | reference | insight | synthesis`.
- Bookkeeping files live under `_system/`: `_system/index.md`, `_system/hot.md`, `_system/log.md`, `_system/tags.md`.
- Raw staging lives in `raw/` (honor an optional `OBSIDIAN_RAW_DIR`, default `raw`).

Any note stored outside `notes/`, any missing or invalid `category:`, and any bookkeeping file sitting somewhere
other than `_system/` are themselves lint findings — see check #1.

After every lint run, verify that `_system/index.md` and `_system/hot.md` are up to date. If notes exist in `notes/`
that are missing from `_system/index.md`, flag them and offer to add them (this overlaps with check #7 below).

**Synthesis Gap behavior (see check #11):**
When check #11 finds synthesis gaps, do NOT list all of them. Instead:
1. Rank gaps by co-occurrence count (highest first)
2. Pick only the **top 1**
3. After the full lint report, ask the user **one question**:

> "[[X]] and [[Y]] co-occur N times but have no synthesis page connecting them — want me to draft one now?"

- If yes → create the note in `notes/` with `category: synthesis` using the template in wiki-query/SKILL.md, then update `_system/index.md` and `_system/hot.md`
- If no → drop it completely, no todo created
- Never offer more than one synthesis at a time

## Before You Start

1. Resolve the vault path (precedence, highest first): the `OBSIDIAN_VAULT_PATH` environment variable if set, else a `.env` in the current working directory (vault-scoped), else `~/.obsidian-wiki/config` (global default).
2. Read `_system/index.md` for the full page inventory
3. Read `_system/log.md` for recent activity context

## Lint Checks

Run these checks in order. Report findings as you go.

### 1. Structural Violations (flat-model compliance)

The flat model is the source of truth. Detect anything that breaks it.

**How to check:**
- **Stray legacy category folders:** Glob for `concepts/`, `entities/`, `references/`, `synthesis/` (and any other per-type folder like `sources/`, `misc/`, `projects/`) at the vault root. Any note living in one of these is a violation — every knowledge note belongs directly in `notes/`.
- **Notes outside `notes/`:** any `.md` file that is a knowledge note but sits somewhere other than `notes/` (excluding `_system/`, `_archives/`, `_visual/`, `raw/`).
- **Misplaced bookkeeping:** `index.md`, `hot.md`, `log.md`, or `tags.md` sitting at the vault root or anywhere other than `_system/`.
- **Invalid category:** Grep the frontmatter `^category:` of each note in `notes/`; flag any note whose value is not one of `concept | entity | reference | insight | synthesis` (a missing `category:` is reported by check #4).

**How to fix:**
- Move notes out of legacy category folders into `notes/`, setting `category:` from the folder they came from (`concepts/` → `concept`, `entities/` → `entity`, `references/`/`sources/` → `reference`, `synthesis/` → `synthesis`), then delete the empty folder.
- Move misplaced bookkeeping files under `_system/`.
- Correct any invalid `category:` value to the closest valid one.
- After moving anything, grep the vault for backlinks and update them; convert any folder-qualified links (e.g. `[[concepts/x]]`) to bare `[[x]]`.

### 2. Orphaned Pages

Find pages with zero incoming wikilinks. These are knowledge islands that nothing connects to.

**How to check:**
- Glob all `.md` files in `notes/`
- For each page, Grep the rest of `notes/` for `[[page-name]]` references
- Pages with zero incoming links are orphans (bookkeeping files under `_system/` are not notes and are exempt)

**How to fix:**
- Identify which existing pages should link to the orphan
- Add wikilinks in appropriate sections

### 3. Broken Wikilinks

Find `[[wikilinks]]` that point to pages that don't exist.

**How to check:**
- Grep for `\[\[.*?\]\]` across all pages in `notes/`
- Extract the link targets (these are bare basenames in the flat model — `[[x]]`, not `[[concepts/x]]`)
- Check if a corresponding `notes/<target>.md` file exists

**How to fix:**
- If the target was renamed, update the link
- If the target should exist, create it in `notes/`
- If the link is wrong, remove or correct it
- If the link is folder-qualified (`[[concepts/x]]`), rewrite it bare (`[[x]]`) — the flat vault resolves by basename

### 4. Missing / Invalid Frontmatter

Every page should have: title, category, tags, sources, created, updated. `category` must be a valid value.

**How to check:**
- Grep frontmatter blocks (scope to `^---` at file heads) instead of reading every page in full
- Flag pages missing required fields
- Flag pages whose `category:` is missing or is not one of `concept | entity | reference | insight | synthesis`

**How to fix:**
- Add missing fields with reasonable defaults
- Set a valid `category:` (infer from content: a person/org/tool → `entity`, a summarized external source → `reference`, a cross-cutting page → `synthesis`, the user's own take → `insight`, otherwise `concept`)

### 4a. Missing Summary (soft warning)

Every page *should* have a `summary:` frontmatter field — 1–2 sentences, ≤200 chars. This is what cheap retrieval (e.g. `wiki-query`'s index-only mode) reads to avoid opening page bodies.

**How to check:**
- Grep frontmatter for `^summary:` across `notes/`
- Flag pages without it, **but as a soft warning, not an error** — older pages predating this field are fine; the check exists to nudge ingest skills into filling it on new writes.
- Also flag pages whose summary exceeds 200 chars.

**How to fix:**
- Re-ingest the page, or manually write a short summary (1–2 sentences of the page's content).

### 5. Stale Content

Pages whose `updated` timestamp is old relative to their sources.

**How to check:**
- Compare page `updated` timestamps to source file modification times
- Flag pages where sources have been modified after the page was last updated

### 6. Contradictions

Claims that conflict across pages.

**How to check:**
- This requires reading related pages and comparing claims
- Focus on pages that share tags or are heavily cross-referenced
- Look for phrases like "however", "in contrast", "despite" that may signal existing acknowledged contradictions vs. unacknowledged ones

**How to fix:**
- Add an "Open Questions" section noting the contradiction
- Reference both sources and their claims

### 7. Index Consistency

Verify `_system/index.md` matches the actual page inventory.

**How to check:**
- Compare pages listed in `_system/index.md` to the actual files in `notes/`
- Check that summaries in `_system/index.md` still match page content
- Flag notes present in `notes/` but missing from `_system/index.md`, and entries in `_system/index.md` with no backing file

### 8. Provenance Drift

Check whether pages are being honest about how much of their content is inferred vs extracted. See the Provenance Markers section in `llm-wiki` for the convention.

**How to check:**
- For each page with a `provenance:` block or any `^[inferred]`/`^[ambiguous]` markers, count sentences/bullets and how many end with each marker
- Compute rough fractions (`extracted`, `inferred`, `ambiguous`)
- Apply these thresholds:
  - **AMBIGUOUS > 15%**: flag as "speculation-heavy" — even 1-in-7 claims being genuinely uncertain is a signal the page needs tighter sourcing or should become a `category: synthesis` note
  - **INFERRED > 40% with no `sources:` in frontmatter**: flag as "unsourced synthesis" — the page is making connections but has nothing to cite
  - **Hub pages** (top 10 by incoming wikilink count) with INFERRED > 20%: flag as "high-traffic page with questionable provenance" — errors on hub pages propagate to every page that links to them
  - **Drift**: if the page has a `provenance:` frontmatter block, flag it when any field is more than 0.20 off from the recomputed value
- **Skip** pages with no `provenance:` frontmatter and no markers — treated as fully extracted by convention

**How to fix:**
- For ambiguous-heavy: re-ingest from sources, resolve the uncertain claims, or relabel the page as `category: synthesis`
- For unsourced synthesis: add `sources:` to frontmatter or set `category: synthesis` to label it as such
- For hub pages with INFERRED > 20%: prioritize for re-ingestion — errors here have the widest blast radius
- For drift: update the `provenance:` frontmatter to match the recomputed values

### 9. Fragmented Tag Clusters

Checks whether pages that share a tag are actually linked to each other. Tags imply a topic cluster; if those pages don't reference each other, the cluster is fragmented — knowledge islands that should be woven together.

**How to check:**
- For each tag that appears on ≥ 5 pages:
  - `n` = count of pages with this tag
  - `actual_links` = count of wikilinks between any two pages in this tag group (check both directions)
  - `cohesion = actual_links / (n × (n−1) / 2)`
- Flag any tag group where cohesion < 0.15 and n ≥ 5

**How to fix:**
- Run the `cross-linker` skill targeted at the fragmented tag — it will surface and insert the missing links
- If a tag group is large (n > 15) and still fragmented, consider splitting it into more specific sub-tags

### 10. Visibility Tag Consistency

Checks that `visibility/` tags are applied correctly and aren't silently missing where they matter.

**How to check:**

- **Untagged PII patterns:** Grep page bodies for patterns that commonly indicate sensitive data — lines containing `password`, `api_key`, `secret`, `token`, `ssn`, `email:`, `phone:` followed by an actual value (not a field description). If a page matches and lacks `visibility/pii` or `visibility/internal`, flag it as a likely mis-classification.
- **`visibility/pii` without `sources:`:** A page tagged `visibility/pii` should always have a `sources:` frontmatter field — if there's no provenance, there's no way to verify the classification. Flag any `visibility/pii` page missing `sources:`.
- **Visibility tags in the tag whitelist:** `visibility/` tags are system tags and must **not** appear in `_system/tags.md`. If found there, flag as misconfigured — they'd be counted toward the tag limit on pages that include them.

**How to fix:**
- For untagged PII patterns: add `visibility/pii` (or `visibility/internal` if it's team-context rather than personal data) to the page's frontmatter tags
- For missing `sources:`: add provenance or escalate to the user — don't auto-fill
- For whitelist contamination: remove the `visibility/` entries from `_system/tags.md`

### 11. Synthesis Gaps

Identify high-value synthesis opportunities the wiki is missing — concept pairs that co-occur across many pages but have no `category: synthesis` note connecting them.

**How to check:**
- List the existing `category: synthesis` notes in `notes/` — collect the concept pairs each one already covers (from its `[[wikilinks]]` or title)
- Pick 10-15 frequently linked notes (`category: concept` and `category: entity`)
- For each pair, run a quick grep to count pages that link to both:
  ```bash
  grep -rl "\[\[ConceptA\]\]" "$OBSIDIAN_VAULT_PATH/notes" --include="*.md" > /tmp/a.txt
  grep -rl "\[\[ConceptB\]\]" "$OBSIDIAN_VAULT_PATH/notes" --include="*.md" > /tmp/b.txt
  comm -12 <(sort /tmp/a.txt) <(sort /tmp/b.txt) | wc -l
  ```
- Flag pairs with co-occurrence ≥ 3 that have no existing synthesis note

**How to fix:**
- Run `/wiki-synthesize` to automatically discover and fill the top gaps

## Output Format

Report findings as a structured list:

```markdown
## Wiki Health Report

### Structural Violations (N found)
- `concepts/foo.md` — note in a legacy category folder; move to `notes/foo.md` with `category: concept`
- `log.md` — bookkeeping file at vault root; move to `_system/log.md`
- `notes/bar.md` — invalid `category: misc` (must be concept|entity|reference|insight|synthesis)

### Orphaned Pages (N found)
- `notes/foo.md` — no incoming links

### Broken Wikilinks (N found)
- `notes/bar.md:15` — links to [[nonexistent-page]]

### Missing / Invalid Frontmatter (N found)
- `notes/baz.md` — missing: tags, sources
- `notes/qux.md` — missing `category:`

### Stale Content (N found)
- `notes/paper-x.md` — source modified 2024-03-10, page last updated 2024-01-05

### Contradictions (N found)
- `notes/scaling.md` claims "X" but `notes/efficiency.md` claims "not X"

### Index Issues (N found)
- `notes/new-page.md` exists on disk but not in `_system/index.md`

### Missing Summary (N found — soft)
- `notes/foo.md` — no `summary:` field
- `notes/bar.md` — summary exceeds 200 chars

### Provenance Issues (N found)
- `notes/scaling.md` — AMBIGUOUS > 15%: 22% of claims are ambiguous (re-source or relabel `category: synthesis`)
- `notes/some-tool.md` — drift: frontmatter says inferred=0.10, recomputed=0.45
- `notes/transformers.md` — hub page (31 incoming links) with INFERRED=28%: errors here propagate widely
- `notes/speculation.md` — unsourced synthesis: no `sources:` field, 55% inferred

### Fragmented Tag Clusters (N found)
- **#systems** — 7 pages, cohesion=0.06 ⚠️ — run cross-linker on this tag
- **#databases** — 5 pages, cohesion=0.10 ⚠️

### Visibility Issues (N found)
- `notes/user-records.md` — contains `email:` value pattern but no `visibility/pii` tag
- `notes/auth-flow.md` — tagged `visibility/pii` but missing `sources:` frontmatter
- `_system/tags.md` — contains `visibility/internal` entry (system tag must not be in the whitelist)

### Synthesis Gaps (N found)
Concept pairs that co-occur frequently but have no synthesis note:

| Pair | Co-occurrence | Suggested Action |
|---|---|---|
| [[Caching]] × [[Consistency]] | 5 pages | Run `/wiki-synthesize` |
| [[Testing]] × [[Observability]] | 3 pages | Run `/wiki-synthesize` |
```

## After Linting

Append to `_system/log.md`:
```
- [TIMESTAMP] LINT issues_found=N structural=T orphans=X broken_links=Y stale=Z contradictions=W prov_issues=P missing_summary=S fragmented_clusters=F visibility_issues=V synthesis_gaps=G
```

Offer to fix issues automatically or let the user decide which to address.
