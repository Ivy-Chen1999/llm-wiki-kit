---
name: wiki-visual
description: >
  Generate a self-contained, single-file HTML visual for a wiki note — a diagram page when the note
  has diagrammable structure, otherwise a clean scannable card page. Output is a derived, regenerable
  artifact that never modifies the note. Use when the user says "make a visual / diagram / one-pager
  for this note", "show me the picture version", or wants a shareable HTML view of a concept.
---

# Wiki Visual — Note → Self-Contained HTML

You turn a wiki note into **one self-contained `.html` file** a person can open in a browser and
understand mostly from diagrams and cards, with minimal reading. It is a **consumer** of the wiki:
read the note, never change it. The markdown stays the single source of truth; the HTML is derived and
regenerable.

Resolve the vault path (precedence, highest first): the `OBSIDIAN_VAULT_PATH` environment variable if
set, else a `.env` in the current working directory (vault-scoped), else `~/.obsidian-wiki/config`
(global default). Set `VAULT` to that path.

## Design principles (do not violate)

1. **Producer/consumer independence** — READ the note; NEVER modify it. The HTML is a derived view.
2. **Self-contained single file** — one `.html`, no backend, no build step to view it. Libraries
   (mermaid) load from CDN; content is embedded at generation time. It must open offline by
   double-click and be shareable as a single file.
3. **Tolerate gracefully** — missing frontmatter, broken `[[wikilinks]]`, or unknown structure must
   not break generation. Degrade, don't fail.
4. **Minimally opinionated** — only the diagrams the note actually earns. No decoration for its own sake.
5. **Derived-artifact hygiene** — write to `$VAULT/_visual/` (OUTSIDE the notes tree) so it never
   pollutes the knowledge graph, the index, or the search collection. Ensure `_visual/` is gitignored.

## Step 1 — Load the content

- Given a note (a `[[wikilink]]` or a slug): read the note file in full.
- Given "this" / content just discussed: use that content.
- Note the `title`, `summary`, `category` from frontmatter if present.

## Step 2 — Pick the tier

Decide what the note earns. Two tiers:

- **Tier A — diagram page**: the note contains one or more of the structures below → build real diagrams.
- **Tier B — clean card page**: the note is prose / a definition / a short stub / a plain link list →
  build a scannable card page (hero summary + key-point bullets + relations). Never staple a
  meaningless flowchart onto a stub; a clean card *is* the visual for these. Mark stubs honestly.

| Structure present in the note | Diagram it maps to |
|---|---|
| Process / pipeline / lifecycle / ordered steps | flowchart (LR/TB) or sequence |
| Hierarchy / decomposition / taxonomy | tree / mindmap |
| Comparison (A vs B, before/after, options) | side-by-side cards |
| Architecture / components + connections | graph / flowchart |
| State transitions | state diagram |
| Quantitative contrasts (N×, %, deltas) | stat cards / bars |
| Timeline / evolution / roadmap | timeline |

Only include diagrams for structures that genuinely exist — a note that earns 2 diagrams gets 2, not 6.
If none qualify → Tier B. The value is **selectivity**: a set of visuals where only the genuinely
visual notes have diagrams is more useful than one forced diagram per note.

## Step 3 — Build the HTML (checklist)

**Palette — clean, high-contrast, print-friendly (grayscale default).**
- White background `#ffffff`, ink `#1a1a1a`, cards `#f7f7f7`, muted `#6b6b6b`, lines `#e2e2e2`.
- Differentiate by shade / weight / border, not hue. Emphasis numbers → bold ink, not red/green.
- (If you prefer a branded accent, pick ONE hue and use it only for links/accents — keep the body neutral.)

**Requirements**
- **Mermaid** for structural diagrams:
  `<script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>` and
  `mermaid.initialize({startOnLoad:true, theme:'neutral'})`. Quote labels containing special
  characters; validate the diagram mentally before writing — a broken diagram is worse than none.
- **Responsive mermaid** — mermaid SVGs have a fixed intrinsic width and won't shrink, so on a narrow
  screen they overflow. Always include `.mermaid svg{max-width:100%!important;height:auto!important}`
  and put each diagram in a container with `overflow-x:auto`.
- **One-line caption per diagram** — say what the diagram shows; it must aid comprehension, not decorate.
- **Hero** — title + one-line summary + the single most important anchor (core equation / definition /
  headline number).
- **Only earned sections** — a section exists only if it maps to a diagram or a small set of cards.
  Prose that doesn't diagram → one-line bullets, or omit with a "full text in the note" pointer. Do
  not transcribe the whole note.
- **Link handling** — for each `[[wikilink]]` in the note: if `$VAULT/_visual/<target>.html` exists,
  link to it; otherwise render the link text plainly. Never hard-fail on a missing target.
- **Accessibility** — semantic headings, high contrast, responsive grid (`@media` fallback to 1 column).
- **Footer** — mark it derived: "Generated from notes/<slug>.md · single file · regenerable".
- **Staleness stamp (required)** — put the note's `updated` value in the head:
  `<meta name="wiki-src-updated" content="YYYY-MM-DD">`. Staleness is judged by comparing this to the
  note's current `updated`, NOT by file mtime (sync tools rewrite mtimes).
- **No secrets / confidential content** in a file meant to be shareable.

### Embedding inside Obsidian (optional)

If the user embeds the HTML inside the note (e.g. via the Local HTML Embed plugin, which renders a
fixed-height `srcdoc` iframe):
- Design for a fixed content width (e.g. `max-width:1040px`) and let the embed fill it.
- **No `position:sticky` / `position:fixed`** — inside the iframe they anchor to the iframe's own
  viewport, so headers get clipped. Use `position:relative`. (Invariant: no sticky/fixed in the output.)
- **No `backdrop-filter`** on the header — it fights the embedded/transformed context.

## Step 4 — Save

- Write to `$VAULT/_visual/<slug>.html` (create `_visual/` if missing; ensure it's gitignored).
- Do NOT register it in the index or the recent-activity file — it's a derived artifact, not knowledge.
- Open it in a browser **only when the user explicitly asked** for a visual. In batch/automatic runs
  (e.g. right after an ingest), just write the file and report.
- Regeneration is cheap and expected — the note changes, re-run, overwrite.

## Step 5 — Report

Two lines: which diagrams you included and why they help, plus the path. Offer to tweak the style or
regenerate.

## Notes

- In-editor alternatives exist (a ```mermaid``` block inside the note, a canvas board, a
  headings→mindmap plugin). `wiki-visual` is specifically the **standalone shareable HTML** path.
- For a whole-vault overview page rather than a per-note visual, use `wiki-dashboard`.
