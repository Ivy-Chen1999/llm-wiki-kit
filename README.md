# llm-wiki-kit

A set of agent skills and a starter Obsidian vault for keeping a personal wiki that an LLM helps maintain. Based on [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

The idea: instead of searching raw documents every time you have a question (RAG), the agent processes a source once and writes it into structured, linked Obsidian notes. Questions are then answered from those notes. You pick the sources and ask the questions; the agent does the summarizing, linking, and filing.

## How it's organized

There are three layers:

1. **Raw sources** — your original material (articles, PDFs, notes, screenshots). Never modified.
2. **The wiki** — markdown notes with YAML frontmatter and `[[wikilinks]]`, kept in the vault.
3. **The skills** — the instruction files in `skills/` that tell the agent how to maintain the wiki.

## What's in this repo

```
llm-wiki-kit/
├── skills/          18 agent skills
├── vault-template/  an empty vault you can copy and start using
├── .env.example     config (vault path, sources, search)
├── install.sh       links the skills into your agent's skills directory
├── setup-qmd.sh     optional: installs and indexes local search
└── LICENSE
```

### Skills

| Skill | What it does |
|-------|--------------|
| `llm-wiki` | Explains the pattern and retrieval approach. Start here. |
| `wiki-setup` | Initializes a new vault (structure, system files, config). |
| `wiki-ingest` | Turns a raw source into wiki notes. |
| `ingest-url` | Fetches a URL and ingests it. |
| `data-ingest` | Ingests structured/tabular data. |
| `wiki-query` | Answers questions from the wiki, with links to source notes. |
| `wiki-research` | Runs web research and files the results into the wiki. |
| `wiki-update` | Revises existing notes as things change. |
| `wiki-synthesize` | Builds notes that connect several existing notes. |
| `cross-linker` | Finds and adds missing `[[wikilinks]]`. |
| `tag-taxonomy` | Keeps tags to a controlled list. |
| `wiki-lint` | Checks for orphans, broken links, contradictions, stale notes. |
| `wiki-status` | Reports what's new and what's ready to ingest. |
| `wiki-dashboard` | Generates a vault overview. |
| `wiki-rebuild` | Rebuilds the index and cache from the notes. |
| `wiki-export` | Exports the wiki to other formats. |
| `wiki-capture` | Drops rough notes into the staging area. |
| `graph-colorize` | Colors the Obsidian graph by category. |

## Requirements

- [Obsidian](https://obsidian.md/), to read and edit the vault.
- An agent that loads skills from a directory — Claudian (the Obsidian + Claude plugin), Claude Code, or similar.
- Optional: `qmd`, a local search engine (BM25 + vector). Without it, the skills use `Grep` instead, so it's not required. See `setup-qmd.sh` or run `npm install -g @tobilu/qmd`.

## Setup

```bash
# 1. Clone
git clone https://github.com/Ivy-Chen1999/llm-wiki-kit.git
cd llm-wiki-kit

# 2. Link the skills (defaults to ~/.agents/skills; pass another dir to change)
./install.sh
# ./install.sh ~/.claude/skills

# 3. Edit ~/.obsidian-wiki/config (created by install.sh) and set
#    OBSIDIAN_VAULT_PATH to where you want the vault.

# 4. Create the vault from the template
cp -R vault-template "$HOME/Documents/my-wiki"

# 5. Optional: install and index local search
./setup-qmd.sh
```

Then open the vault in Obsidian and ask the agent to ingest a source or answer a question.

## Vault layout

The `vault-template/` uses a flat layout: all notes live in `notes/`, and the category is set in frontmatter (`category: concept|entity|reference|insight|synthesis`).

```
my-wiki/
├── notes/        the notes
├── raw/          staging area for unprocessed sources
├── journal/      daily notes
├── Templates/    note and daily-note templates
└── _system/
    ├── index.md  table of contents (maintained by the skills)
    ├── hot.md    short summary of recent activity
    ├── log.md    append-only change log
    └── tags.md   tag list
```

If you prefer one folder per category, `wiki-setup` can generate that layout instead.

## Credits

- The pattern comes from [Andrej Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) (the three-layer structure and the idea of processing a source once instead of re-searching it each time). His original write-up is included in `skills/llm-wiki/references/karpathy-pattern.md`.
- Built for [Obsidian](https://obsidian.md/).
- The skills were taken from a personal vault and generalized: hardcoded paths, personal collection names, and non-English text removed.

## License

MIT — see [LICENSE](LICENSE).
