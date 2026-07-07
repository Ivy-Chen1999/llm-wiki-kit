---
name: wiki-capture
description: >
  Save the current conversation as a permanent, structured wiki note. Use this skill when the user
  says "save this", "/wiki-capture", "capture this", "file this conversation", "preserve this",
  "add this to my wiki", or wants to turn what was just discussed into lasting knowledge. The skill
  classifies the content, rewrites it as declarative knowledge (not a chat transcript), and places
  it in the correct vault category.
---

# Wiki Capture — Conversation to Wiki Note

You are preserving knowledge from the current conversation as a permanent wiki note. The goal is to extract the *substance* — the knowledge itself — not a summary of what was said.

> **Source discipline (required):** before writing any claim, apply the **`wiki-sourcing`** gate — a falsifiable fact (number / date / price / version / benchmark / named attribution) needs a *fetched* source + an `(as of YYYY-MM, src)` marker; otherwise hedge or mark it `[unverified]`. A digest or search snippet is **not** a source — trace it to the primary. See the `wiki-sourcing` skill for the full doctrine (three states, degradation ≠ refutation, don't cave to pushback).

## Before You Start

1. Resolve the vault path (precedence, highest first): the `OBSIDIAN_VAULT_PATH` environment variable if set, else a `.env` in the current working directory (vault-scoped), else `~/.obsidian-wiki/config` (global default).
2. Read `$OBSIDIAN_VAULT_PATH/_system/index.md` to understand existing wiki content (avoid duplicates)
3. Read `$OBSIDIAN_VAULT_PATH/_system/hot.md` if it exists — it gives context on recent activity

## Step 1: Identify What's Worth Preserving

Scan the conversation. Ask: what knowledge emerged here that would be valuable in 3 months with no memory of this chat?

Worth preserving:
- Decisions made and *why* they were made
- Analysis, frameworks, mental models developed
- Technical findings, patterns, or procedures
- Synthesized understanding of a topic
- Clear explanations of a concept that took effort to arrive at
- Key facts from an external source discussed in the conversation

Skip:
- Logistics, scheduling, pleasantries
- Exploratory back-and-forth where no conclusion was reached
- Content that's already in the wiki

If nothing material emerged, tell the user and stop.

## Step 2: Classify the Content Type

Every note lives flat in `notes/`. What varies by type is the frontmatter `category:` and the body structure below — not the location. Classify the content into one of five types:

| Type | Description | `category:` |
|---|---|---|
| `synthesis` | Multi-step analysis or an answer to a specific question that required reasoning | `synthesis` |
| `concept` | A definition, framework, or mental model (what a thing *is*) | `concept` |
| `source` | Summary of an external document, article, or resource discussed | `reference` |
| `decision` | A strategic, architectural, or design choice and its rationale | `synthesis` |
| `session` | A complete discussion summary when the conversation spans multiple topics | `synthesis` |

Note also `entity` (a person / organization / tool) and `insight` (the user's own take) as valid categories if the content is really one of those.

If the content clearly belongs to a specific project, it still lands in `notes/` like everything else; record the project association with a tag rather than a subfolder.

## Step 3: Rewrite as Declarative Knowledge

Do **not** write a summary of the conversation. Write the knowledge itself, in declarative present tense:

- Not: "The user asked about X and Claude explained that..."
- Yes: "X works by..."
- Not: "We decided to use Y because..."
- Yes: "Y is preferred over Z because [reason]. [^[inferred] if the rationale was implied, not stated explicitly]"

Apply provenance markers per `llm-wiki`:
- *Extracted* — explicitly stated in the conversation (no marker)
- *Inferred* — generalized or synthesized from the conversation → `^[inferred]`
- *Ambiguous* — disputed, uncertain, or contradictory → `^[ambiguous]`

## Step 4: Generate a Slug and Title

Derive a clear, descriptive title from the content. Slugify it:
- Lowercase, words separated by hyphens
- Max 50 characters
- Avoid dates in the slug (the frontmatter has `created`)

## Step 5: Write the Wiki Note

Create the file at the target path with required frontmatter:

```yaml
---
title: >-
  <Title>
category: <concept|entity|reference|insight|synthesis>
tags: [<2-5 domain tags from taxonomy>]
sources:
  - conversation:<ISO-date>
created: <ISO-8601 timestamp>
updated: <ISO-8601 timestamp>
summary: >-
  <1-2 sentences, ≤200 chars, answering "what knowledge does this page hold?">
provenance:
  extracted: 0.X
  inferred: 0.X
  ambiguous: 0.X
---
```

Body structure by type:

**synthesis / decision:**
```markdown
# Title

## Context
<What prompted this — the problem or question being addressed>

## Finding / Decision
<The core knowledge or conclusion>

## Reasoning
<Why this is the case or why this choice was made>

## Implications
<What follows from this — what to watch for, next steps, trade-offs>

## Related
<[[wikilinks]] to connected pages>
```

**concept:**
```markdown
# Title

<Definition in one clear sentence.>

## What It Is
<Explanation of the concept>

## How It Works
<Mechanism or structure>

## When to Use
<Applicability, conditions, trade-offs>

## Related
<[[wikilinks]]>
```

**source:**
```markdown
# Title

> Source: <title or URL>

## What It Covers
<What the source is about>

## Key Points
<Bulleted claims with provenance markers>

## Open Questions
<What it raises but doesn't answer — omit if none>

## Related
<[[wikilinks]]>
```

**session:**
```markdown
# Title

*Session captured: <date>*

## Topics Covered
<Brief list>

## Key Takeaways
<The 3-5 most important things that emerged>

## Decisions Made
<Any explicit decisions, with rationale>

## Open Questions
<What remains unresolved>

## Related
<[[wikilinks]]>
```

Every note must link to at least 2 existing wiki pages. Search `_system/index.md` before writing. If fewer than 2 related pages exist, create minimal stubs for the most important concepts referenced.

## Step 6: Update Tracking Files

**`_system/index.md`** — Add the new page under its category section.

**`_system/log.md`** — Append:
```
- [TIMESTAMP] CAPTURE type=<type> page="notes/<slug>.md" title="<title>"
```

**`_system/hot.md`** — Update **Recent Activity** with what was just captured. Update **Key Takeaways** if the note introduced something worth flagging. Update `updated` timestamp.

## Step 7: Confirm to User

Report the saved path and title:
```
Saved to: notes/<slug>.md
Title: <Title>
Type: synthesis
```

## Quality Checklist

- [ ] Applied the **wiki-sourcing** gate to every falsifiable claim (fetched source + `(as of …)`, else `[unverified]`/hedge)
- [ ] Content rewritten as declarative knowledge (not a chat transcript)
- [ ] Type classified correctly and mapped to the right `category:`; note saved flat in `notes/`
- [ ] Frontmatter complete with title, category, tags, sources, summary, provenance
- [ ] At least 2 wikilinks to existing pages
- [ ] `_system/index.md`, `_system/log.md`, and `_system/hot.md` updated
- [ ] Confirmed save path to user
