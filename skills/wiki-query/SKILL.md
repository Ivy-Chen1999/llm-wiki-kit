---
name: wiki-query
description: >
  Answer questions by searching the compiled Obsidian wiki. Use this skill when the user asks a question
  about their knowledge base, wants to find information across their wiki, asks "what do I know about X",
  "find everything related to Y", or wants synthesized answers with citations from their wiki pages.
  Also use when the user wants to explore connections between topics in their wiki. Works from any project.
  Includes an index-only fast mode triggered by "quick answer", "just scan", "don't read the pages",
  "fast lookup" — returns answers from page summaries and frontmatter without reading page bodies.
---

# Wiki Query — Knowledge Retrieval

You are answering questions against a compiled Obsidian wiki, not raw source documents. The wiki contains pre-synthesized, cross-referenced knowledge.

## Before You Start

1. Read `~/.obsidian-wiki/config` to get `OBSIDIAN_VAULT_PATH` (works from any project). Fall back to `.env` if you're inside the obsidian-wiki repo.
2. If `$OBSIDIAN_VAULT_PATH/hot.md` exists, read it first — it gives you instant context on recent activity. If the user's question is about something ingested recently, hot.md may answer it before you even open `index.md`.
3. Read `$OBSIDIAN_VAULT_PATH/index.md` to understand the wiki's scope and structure

## Visibility Filter (optional)

By default, **all pages are returned** regardless of visibility tags. This preserves existing behavior — nothing changes unless the user asks for it.

If the user's query includes phrases like **"public only"**, **"user-facing"**, **"no internal content"**, **"as a user would see it"**, or **"exclude internal"**, activate **filtered mode**:

- Build a **blocked tag set**: `{visibility/internal, visibility/pii}`
- In the Index Pass (Step 2), skip any candidate whose frontmatter tags contain a blocked tag
- In Section/Full Read passes (Steps 3–4), do not read or cite any blocked page
- Synthesize the answer **only from allowed pages** — do not mention that excluded pages exist

Pages with no `visibility/` tag, or tagged `visibility/public`, are always included.

In filtered mode, note the filter in the Step 6 log entry: `mode=filtered`.

## Retrieval Protocol

**Follow the Retrieval Primitives table in `llm-wiki/SKILL.md`.** Reading is the dominant cost of this skill — use the cheapest primitive that answers the question and escalate only when it can't. Never jump straight to full-page reads.

### Step 1: Understand the Question

Classify the query type:
- **Factual lookup** — "What is X?" → Find the relevant page(s)
- **Relationship query** — "How does X relate to Y?" → Find both pages and their cross-references
- **Synthesis query** — "What's the current thinking on X?" → Find all pages that touch X, synthesize
- **Gap query** — "What don't I know about X?" → Find what's missing, check open questions sections

Also decide the **mode**:
- **Index-only mode** — triggered by "quick answer", "just scan", "don't read the pages", "fast lookup". Stops at Step 3. Answers from frontmatter + `index.md` only.
- **Normal mode** — the full tiered pipeline below.

## Retrieval Strategy

Two paths, chosen by query type. No sequential escalation — pick the right tool once.

**Context guard**: Read `_system/hot.md` at most ONCE per session.

**Fallback** (if qmd not installed): `Grep "<term>" _system/index.md` max 2 calls, then read candidates.

---

### Step 2: Retrieval

**Path A — Simple/factual** (specific concept, person, tool name):
```bash
qmd search "<2-3 key terms>" -c "$QMD_WIKI_COLLECTION"
```
BM25 keyword match. If top result score ≥ 40% → take top 2 candidates, go to Step 4 (Read).

If score < 40% or zero results → switch to Path B.

**Path B — Conceptual/synthesis** (relationship between ideas, "how does X apply to Y", multi-topic questions):
```bash
qmd query "<full question>" -c "$QMD_WIKI_COLLECTION"
```
Hybrid BM25 + vector + LLM rerank. Take top 3 candidates → go to Step 4 (Read).

**Index-only mode** (triggered by "quick answer", "just scan"): use Path A only, answer from returned snippets without reading pages. Label: **(index-only)**. Skip to Step 5.

### Step 3: Section Grep (optional — skip for compiled wiki notes)

Only use if a candidate note is unusually long (>300 lines). Pull the relevant section:
```
Grep -A 10 -B 2 "<query-term>" <candidate-file>
```
For normal-sized notes, skip this — just Read the full note in Step 4.

### Step 4: Read Candidates

- Path A: Read top **2** notes in full
- Path B: Read top **3** notes in full
- Follow at most **1 hop** of `[[wikilinks]]` if the answer explicitly requires a linked page
- If still empty → broad `Grep` across all notes/. Tell the user: "escalated to full vault scan."
- If the section grep gives a clear answer, go straight to Step 5.

### Step 4: Full Read (expensive — last resort)

Only when Levels 1+2 (Steps 2–3) don't answer the question:

- `Read` the top **3** candidates in full (Level 3)
- Follow at most one hop of `[[wikilinks]]` if cross-references needed
- Check "Open Questions" sections for known gaps
- If still short → Level 4: broad `Grep` across all notes/. Tell the user: "escalated to full vault scan."

### Step 5: Synthesize an Answer

Compose your answer from wiki content:
- Cite specific wiki pages using `[[page-name]]` notation
- Note which step the answer came from ("found in summary" vs "grepped section" vs "full page read") — helps the user understand confidence
- If the wiki has contradictions, present both sides
- If the wiki doesn't cover something, say so explicitly
- Suggest which sources might fill the gap

### Step 6: Insight Offer (optional)

Three variants — trigger at most **one** per query, in priority order:

**6a. Gap offer** — wiki had nothing on the topic (zero candidate pages from Steps 2–4):
> Nothing in the wiki on this yet — want me to create a stub?

- Yes → create `notes/[slug].md` with `category: concept` (or entity/reference as fits), body = short skeleton from query context. Update index + hot.
- No → drop it.

**6b. Synthesis offer** — wiki had content, answer synthesized from 2+ distinct notes, contains a genuinely new angle:
> This synthesis seems worth saving to the wiki — want me to create it now?

**6c. Archive offer** — wiki had partial content but the bulk of the answer came from general knowledge (not wiki pages), answer is substantive (>3 sentences):
> The wiki only partly covers this — want me to save the full answer?

Only trigger when ALL conditions for that variant are met. Never show more than one offer per query.

If the user says yes:
1. Create `notes/[slug].md` with `category: insight` (or `concept`/`reference` for 6a/6c)
2. Use this template:

```markdown
---
title: [descriptive title of the insight]
category: insight
tags: [2-3 tags from _system/tags.md]
sources: []
summary: [≤200 chars, one-line distillation]
created: [today]
updated: [today]
---

# [title]

> [the core insight in one sentence]

## Synthesis

[the synthesized answer, cleaned up]

## Source Pages

- [[notes/page-a]]
- [[notes/page-b]]

## How To Apply

**When to use:**

**How to do it:**

**Pitfalls:**

## Related

- [[notes/page-a]]
- [[notes/page-b]]
```

3. Update `_system/index.md` and `_system/hot.md` per your wiki's index-maintenance rules
4. Tell the user: "Saved as [[notes/slug]]"

If the user says no — drop it completely. No todo, no mention again.

### Step 7: Log the Query

Append to `log.md`:
```
- [TIMESTAMP] QUERY query="the user's question" result_pages=N mode=normal|index_only|filtered escalated=true|false insight_offered=true|false insight_saved=true|false
```

## Answer Format

Structure answers like this:

> **Based on the wiki:**
>
> [Your synthesized answer with [[wikilinks]] to source pages]
>
> **Pages consulted:** [[page-a]], [[page-b]], [[page-c]]
>
> **Gaps:** [What the wiki doesn't cover that might be relevant]
