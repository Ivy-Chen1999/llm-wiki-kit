# llm-wiki-kit

**A clone-and-go kit for running an AI-maintained personal wiki in Obsidian.**
Based on [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

Your LLM agent doesn't *retrieve* knowledge at query time (RAG). It **compiles** knowledge once — at ingest time — into a structured, cross-referenced Obsidian vault, then keeps it current. You read, ask, and decide what matters; the agent summarizes, cross-links, files, and keeps things consistent.

> "The tedious part of maintaining a knowledge base is not the reading or the thinking — it's the bookkeeping." — Karpathy

---

## The idea in one diagram

```
  Layer 1: RAW SOURCES        Layer 2: THE WIKI           Layer 3: THE SCHEMA
  (immutable input)           (LLM-maintained output)     (the rules — this kit)
  ┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
  │ articles, PDFs  │  ───▶   │ notes/*.md       │  ◀───   │ skills/*        │
  │ chats, images   │ ingest  │ [[wikilinks]]    │ governs │ .env config     │
  │ bookmarks       │         │ YAML frontmatter │         │ templates       │
  └─────────────────┘         │ _system/index.md │         └─────────────────┘
                              └─────────────────┘
```

- **Layer 1 — Raw sources**: your original material. Never modified.
- **Layer 2 — The wiki**: compiled markdown notes, interlinked, with provenance.
- **Layer 3 — The schema**: the skills + config in this repo that tell the agent *how* to maintain Layer 2.

**Division of labor:** the human owns choosing sources, asking questions, judging significance. The LLM owns summarizing, cross-referencing, filing, and consistency.

---

## What's inside

```
llm-wiki-kit/
├── skills/            18 generic agent skills (the "how")
├── vault-template/    a ready-to-use empty vault (flat notes/ structure)
├── .env.example       config template (vault path, sources, search)
├── install.sh         symlinks skills into your agent skills dir
├── README.md          this file
└── LICENSE            MIT
```

### Skills

| Skill | What it does |
|-------|--------------|
| `llm-wiki` | The theory — three-layer architecture, retrieval primitives. Read this first. |
| `wiki-setup` | Initialize a new vault (structure, special files, config). |
| `wiki-ingest` | Turn a raw source (article, PDF, image, chat) into compiled wiki pages. |
| `ingest-url` | Fetch a URL and ingest it. |
| `data-ingest` | Ingest structured/tabular data. |
| `wiki-query` | Answer questions against the wiki with citations (RAG-free). |
| `wiki-research` | Autonomous multi-round web research filed straight into the wiki. |
| `wiki-update` | Revise existing pages as knowledge changes. |
| `wiki-synthesize` | Build cross-cutting insight pages spanning multiple notes. |
| `cross-linker` | Discover and add missing `[[wikilinks]]`. |
| `tag-taxonomy` | Maintain a controlled tag whitelist; prevent tag sprawl. |
| `wiki-lint` | Health audit — orphans, broken links, contradictions, stale content. |
| `wiki-status` | Report what's new/changed and what's ready to ingest. |
| `wiki-dashboard` | Generate an at-a-glance vault dashboard. |
| `wiki-rebuild` | Rebuild derived artifacts (index, hot cache) from notes. |
| `wiki-export` | Export the wiki to other formats. |
| `wiki-capture` | Quick-capture rough notes into the staging area. |
| `graph-colorize` | Color the Obsidian graph by category. |

---

## Requirements

- **[Obsidian](https://obsidian.md/)** — to browse and edit the vault.
- **An agent that reads skills** — these are markdown `SKILL.md` instruction files. Works with **Claudian** (the Obsidian + Claude plugin), Claude Code, or any harness that loads a skills directory.
- **Optional: a local search engine (qmd)** — BM25 + vector search over the vault. Skills fall back to `Grep` automatically if it's absent, so this is not required. Install + index in one step with [`./setup-qmd.sh`](setup-qmd.sh), or manually: `npm install -g @tobilu/qmd` then `qmd collection add "$OBSIDIAN_VAULT_PATH" --name wiki && qmd embed`.

---

## Quickstart

```bash
# 1. Clone
git clone https://github.com/Ivy-Chen1999/llm-wiki-kit.git
cd llm-wiki-kit

# 2. Install the skills (symlinks into ~/.agents/skills by default)
./install.sh
#   ...or into a different skills dir:
#   ./install.sh ~/.claude/skills

# 3. Point the kit at a vault
#    install.sh created ~/.obsidian-wiki/config — edit it:
#    set OBSIDIAN_VAULT_PATH to where you want the vault.

# 4. Create the vault from the template
cp -R vault-template "$HOME/Documents/my-wiki"

# 5. (Optional) Install + index local search for faster, semantic queries
./setup-qmd.sh

# 6. Open it in Obsidian, then talk to your agent:
#    "ingest this article into my wiki"   → wiki-ingest
#    "what do I know about X?"             → wiki-query
#    "audit my wiki"                       → wiki-lint
```

That's it — clone, install, point at a vault, start ingesting. Step 5 is optional; skip it and the skills use `Grep` instead.

---

## Vault layout (the starter template)

The bundled `vault-template/` uses a **flat structure**: all pages live in `notes/`, with the category set in frontmatter (`category: concept|entity|reference|insight|synthesis`). This is the battle-tested layout.

```
my-wiki/
├── notes/          all compiled pages
├── raw/            staging area for unprocessed sources
├── journal/        timestamped daily notes
├── Templates/      note + daily-note templates
└── _system/
    ├── index.md    auto-maintained table of contents
    ├── hot.md      ~500-word recent-activity cache (read first)
    ├── log.md      append-only audit trail
    └── tags.md     the tag whitelist
```

> Prefer one folder per category instead? `wiki-setup` can generate a
> `concepts/ entities/ references/ ...` folder layout — both are supported.

---

## Credits & acknowledgements

- **The pattern** — [Andrej Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): treat the wiki as a compiled, compounding artifact maintained by an LLM, with Obsidian as the IDE. The three-layer architecture (raw → wiki → schema) and the "compile, don't re-derive" philosophy come from there. The original write-up is reproduced for reference in [`skills/llm-wiki/references/karpathy-pattern.md`](skills/llm-wiki/references/karpathy-pattern.md).
- **Obsidian** — the [Obsidian](https://obsidian.md/) markdown knowledge base this kit targets (wikilinks, frontmatter, graph view, Dataview).
- **The skills** — distilled from a personal Obsidian vault built on the pattern above, then genericized for this kit: hardcoded paths, personal collection names, and non-English strings removed so any vault can use it unchanged.

## License

MIT — see [LICENSE](LICENSE). Free to clone, fork, and adapt.
