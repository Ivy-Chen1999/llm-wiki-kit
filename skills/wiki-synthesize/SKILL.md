---
name: wiki-synthesize
description: >
  Systematically discover synthesis opportunities across the Obsidian wiki — pairs or clusters of
  concepts that co-occur frequently across pages but have no synthesis page connecting them. Creates
  new synthesis notes (category: synthesis) that draw explicit cross-cutting conclusions. Use when the user says "synthesize
  my wiki", "find connections", "what concepts keep coming up together", "/wiki-synthesize", or after
  a large ingest when the vault has grown significantly.
---

# Wiki Synthesize — First-Class Synthesis Discovery

You are scanning the wiki for concepts that co-occur across many pages but have no dedicated synthesis page connecting them. Your job is to surface these gaps and fill the most valuable ones with cross-cutting synthesis pages.

## Before You Start

1. Resolve the vault path (precedence, highest first): the `OBSIDIAN_VAULT_PATH` environment variable if set, else a `.env` in the current working directory (vault-scoped), else `~/.obsidian-wiki/config` (global default)..
2. Read `_system/index.md` to get the full page inventory.
3. Read `_system/hot.md` if it exists — it surfaces recent activity and active threads that may already point to synthesis opportunities.
4. Read `_system/tags.md` to understand the tag vocabulary.

## Step 1: Build the Co-occurrence Map

Scan every knowledge note in `notes/` (skip bookkeeping and staging: `_system/*`, `_archives/*`, `raw/*`).

For each page, collect:
- All `[[wikilinks]]` it contains (outgoing links)
- Its `tags` frontmatter
- Its `category` frontmatter

Build a co-occurrence matrix: for every pair of concept/entity pages (A, B), count how many other pages link to **both** A and B. This is their co-occurrence score.

You don't need to be exhaustive — aim for the top 20-30 pairs by co-occurrence score. Use Grep to find backlinks efficiently:

```bash
grep -rl "\[\[ConceptA\]\]" "$OBSIDIAN_VAULT_PATH" --include="*.md"
```

Run this for your top candidate concepts and intersect the result sets.

## Step 2: Filter Out Already-Synthesized Pairs

Find the existing synthesis pages — notes carrying `category: synthesis` in their frontmatter. For each one:
- Read its `sources` frontmatter or its body for `[[wikilinks]]`
- Mark those concept pairs as already covered

Remove covered pairs from your candidate list.

## Step 3: Score and Rank Candidates

For each remaining candidate pair (or cluster of 3+), assign a synthesis value score:

| Signal | Points |
|---|---|
| Co-occurrence count ≥ 5 | +3 |
| Co-occurrence count 3-4 | +2 |
| Co-occurrence count 1-2 | +1 |
| Concepts are in different categories (cross-domain) | +2 |
| Concepts share tags but carry different `category:` values | +1 |
| One or both concepts are tagged as hubs in `_system/_insights.md` | +1 |
| A synthesis would resolve a flagged contradiction | +2 |

Pick the top 5 candidates. If the user asked for a specific topic ("synthesize everything about observability"), filter candidates to that domain first.

## Step 4: Draft Synthesis Pages

For each top candidate, create a note at `notes/<slug>.md` (with `category: synthesis`) using this template:

```markdown
---
title: <Concept A> × <Concept B>
category: synthesis
tags: [<shared tags>, <domain tags>]
sources: [<all pages that link to both>]
created: TIMESTAMP
updated: TIMESTAMP
summary: "Cross-cutting synthesis of how <A> and <B> interact, with implications for <domain>."
provenance:
  extracted: 0.2
  inferred: 0.7
  ambiguous: 0.1
---

# <Concept A> × <Concept B>

## The Connection

*What makes these two concepts worth synthesizing together — the non-obvious relationship that pages about each individually don't capture.*

## Where They Co-occur

*The pages and contexts where both appear. What situations bring them together.*

## Cross-cutting Insight

*The conclusion that only becomes visible when you look at both together. This is the point of the page — the thing you couldn't see from either concept page alone.*

## Tensions and Trade-offs

*Where the two concepts pull in opposite directions. Unresolved contradictions. Cases where applying one undermines the other.*

## Open Questions

*What this synthesis surfaces that the wiki doesn't yet have an answer for. Good candidates for future research.*

## Related

- [[<Concept A>]]
- [[<Concept B>]]
- [[<other related pages>]]
```

**Synthesis pages are mostly `^[inferred]`.** You are drawing connections across sources — that's synthesis by definition. Apply `^[inferred]` to cross-cutting conclusions and `^[ambiguous]` where sources disagree.

**The title format is `A × B`** — this signals to readers that it's a synthesis page, not a page about either concept alone.

## Step 5: Back-link from Source Pages

For each synthesis page you created, add a link to it from the two (or more) concept pages it synthesizes. In the concept page, add to its `## Related` section:

```markdown
- [[Concept A × Concept B]] — synthesis
```

If the concept page has no `## Related` section, add one at the bottom.

## Step 6: Report Synthesis Opportunities Not Taken

After creating pages for the top 5, list the next 10 candidates in your output — pairs that scored well but you didn't write pages for. This gives the user visibility into what the wiki thinks is worth exploring without forcing every synthesis in one run.

Format:
```
Skipped (consider next time):
- [[Caching]] × [[Consistency]] — co-occurs in 4 pages, cross-domain
- [[Testing]] × [[Observability]] — co-occurs in 3 pages, shares tags
...
```

## Step 7: Update Special Files

**`_system/index.md`** — Add entries for all new synthesis pages.

**`_system/log.md`** — Append:
```
- [TIMESTAMP] WIKI_SYNTHESIZE pages_scanned=N synthesis_created=M candidates_skipped=K
```

**`_system/hot.md`** — Read `$OBSIDIAN_VAULT_PATH/_system/hot.md` (create from the template in `wiki-ingest` if missing). Update **Recent Activity** with what was synthesized — e.g. "Synthesized 5 cross-cutting pages: Caching × Consistency, Testing × Observability, …". Update **Active Threads** with any open questions the synthesis surfaced. Update `updated` timestamp.

## Quality Checklist

- [ ] Every synthesis page has a `summary:` field (≤200 chars)
- [ ] Every synthesis page links back to its source concepts
- [ ] Source concept pages link forward to the synthesis page
- [ ] No synthesis page just restates what's already on the source pages — it must add a cross-cutting insight
- [ ] `_system/index.md` and `_system/log.md` updated
- [ ] `hot.md` updated

## Tips

- **A synthesis page that only summarizes its sources is useless.** The value is the connection — the thing neither source page says explicitly.
- **Don't synthesize for synthesis's sake.** If two concepts just happen to appear together a lot without a real conceptual link, skip them.
- **Three-way syntheses are powerful but rare.** Only create them when three concepts form a genuine triangle of mutual influence — not just because all three appear in the same project page.
- **Check `_system/_insights.md` first.** The wiki-status skill may have already flagged synthesis candidates there — start with those before running the co-occurrence scan from scratch.
