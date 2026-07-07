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
├── skills/          22 agent skills
├── vault-template/  an empty vault you can copy and start using
├── evals/           behavioral evals for the skills (+ LangSmith adapter)
├── scripts/         repo-hygiene checks (run in CI)
├── .env.example     config (vault path, sources, search)
├── install.sh       links (or --copy) the skills into your agent's skills directory
├── setup-qmd.sh     optional: installs and indexes local search
└── LICENSE
```

### Skills

| Skill | What it does |
|-------|--------------|
| `llm-wiki` | Explains the pattern and retrieval approach. Start here. |
| `wiki-sourcing` | The sourcing/verification doctrine — when a claim needs a fetched source, when to hedge, when to refuse. Applied by every write skill. |
| `wiki-setup` | Initializes a new vault (structure, system files, config). |
| `wiki-ingest` | Turns a raw source into wiki notes. |
| `ingest-url` | Fetches a URL and ingests it. |
| `data-ingest` | Ingests structured/tabular data. |
| `claude-history-ingest` | Mines Claude conversation history into the wiki. |
| `codex-history-ingest` | Mines Codex CLI session history into the wiki. |
| `wiki-query` | Answers questions from the wiki, with links to source notes. |
| `wiki-research` | Runs web research and files the results into the wiki. |
| `wiki-update` | Revises existing notes as things change. |
| `wiki-synthesize` | Builds notes that connect several existing notes. |
| `cross-linker` | Finds and adds missing `[[wikilinks]]`. |
| `tag-taxonomy` | Keeps tags to a controlled list. |
| `wiki-lint` | Checks for orphans, broken links, contradictions, stale notes. |
| `wiki-status` | Reports what's new and what's ready to ingest. |
| `wiki-dashboard` | Generates a vault overview. |
| `wiki-visual` | Turns a note into a self-contained, shareable HTML one-pager (diagram or card). |
| `wiki-rebuild` | Rebuilds the index and cache from the notes. |
| `wiki-export` | Exports the wiki to other formats. |
| `wiki-capture` | Drops rough notes into the staging area. |
| `graph-colorize` | Colors the Obsidian graph by category. |

## Requirements

- [Obsidian](https://obsidian.md/), to read and edit the vault.
- An agent that loads skills from a directory — Claudian (the Obsidian + Claude plugin), Claude Code, or similar.
- Optional: `qmd`, a local search engine (BM25 + vector). Without it, the skills use `Grep` instead, so it's not required. See `setup-qmd.sh` or run `npm install -g @tobilu/qmd`.

## Setup

Two commands. The installer is interactive and does everything else (links the skills, asks where the vault should live, creates it, writes the config):

```bash
git clone https://github.com/Ivy-Chen1999/llm-wiki-kit.git
cd llm-wiki-kit
./install.sh
```

Then follow the final instructions it prints: open the vault folder in Obsidian, and ask your agent to ingest a source or answer a question.

Notes:
- The installer links skills into `~/.claude/skills`, which Claude (Claude Code and the Claudian Obsidian plugin) reads automatically. For another agent: `./install.sh --skills-dir <that agent's skills dir>`.
- It offers to install local search (`qmd`) at the end. Saying no is fine — the skills fall back to `Grep`. You can run `./setup-qmd.sh` later instead.
- Re-running is safe: existing skills, vault, and config are left untouched.
- Skills are **symlinked** by default (so `git pull` updates them live). Pass `--copy` to copy them
  instead — handy if you plan to move or delete this clone.
- **Windows:** run the installer under WSL or Git Bash (it's a bash script). The skills themselves
  are plain markdown and work with any agent.

### Working with more than one vault

The skills resolve the target vault in this order (highest first):

1. an `OBSIDIAN_VAULT_PATH` environment variable (per-session override),
2. a `.env` at the current working directory / vault root (**vault-scoped**),
3. `~/.obsidian-wiki/config` (the global default).

So to keep a vault self-contained, drop a `.env` at its root pointing `OBSIDIAN_VAULT_PATH` at itself (and give it its own `QMD_WIKI_COLLECTION`). Work from that vault and the skills target only it — the global default and your other vaults are untouched.

## For Obsidian users (sharing it with a colleague)

If you already live in Obsidian, this is built for you — and it needs **no API key**.

1. **Pick how you'll talk to it** (both use *your own* Claude login, no key):
   - the **Claudian** plugin (Claude, inside Obsidian) — the in-app experience, or
   - **Claude Code** (terminal), pointed at your vault folder.
2. **Install the skills** — one terminal step, and it's non-destructive (only *adds* skills; never
   touches your existing skills, `settings.json`, or plugins):
   ```bash
   git clone https://github.com/Ivy-Chen1999/llm-wiki-kit.git && cd llm-wiki-kit && ./install.sh
   ```
3. **Point it at a vault:**
   - **New vault** — let the installer create one (flat layout, ready to go).
   - **Your existing Obsidian vault** — drop a `.env` at its root with
     `OBSIDIAN_VAULT_PATH="/path/to/your/vault"`, then tell the agent *"set up my wiki"*. `wiki-setup`
     only creates the bits that are **missing** (`_system/`, templates) — it never overwrites your
     notes, index, or config. The kit then maintains a `notes/` + `_system/` layer **alongside** your
     existing files.
4. **Use it** — open the vault and talk normally: *"add this to my wiki"*, *"what do I know about X?"*.

Good to know: the kit organizes knowledge **flat** (`notes/` + a frontmatter `category`), so it builds
its own tidy layer rather than reorganizing folders you already have. Your originals are never moved.

## How to use it — just say what you want

You don't memorize skill names. Skills trigger automatically from what you say — Claude matches your message to the right one. Open your vault in Claude and talk normally:

| You want to… | Just say something like… |
|---|---|
| Add an article / file / folder | "add this to my wiki", "ingest these docs" |
| Add a web page | "save this link to my wiki", paste a URL + "add this" |
| Ask what you know | "what do I know about X?", "find everything on Y" |
| Quick answer (no deep read) | "quick answer: …", "just scan for …" |
| Save the current chat | "save this conversation to my wiki" |
| Connect related notes | "find missing links", "my wiki feels disconnected" |
| Find cross-cutting themes | "what concepts keep coming up together?" |
| Check health / fix issues | "audit my wiki", "what needs fixing?" |
| See what's been ingested | "what's the status of my wiki?" |
| Research a topic from the web | "research X and file it", "deep dive on Y" |
| Tidy up tags | "clean up my tags", "normalize tags" |
| Color the graph | "color my graph by category" |
| Start fresh | "archive and rebuild the wiki" |

If a phrasing doesn't trigger the right skill, just name it ("use wiki-ingest") — but normal language usually works.

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

Every note is a file in `notes/`; its type is the frontmatter `category:`, not its folder. This keeps links, search, and cross-referencing folder-independent — the whole kit assumes this one layout.

## Make it your own

The 22 skills above are the shared core. The skills that pay off most are usually personal — shaped around how *you* work. You're encouraged to add your own:

- a **retro** skill that writes a project post-mortem into the vault,
- a **digest** skill that pulls your todos + field news into a dated entry,
- your own **ingest house-style**, or a **dispatcher** that routes "/wiki do X".

[`personal-skills/`](personal-skills/) has a blank template and two worked examples (retro, digest) to copy and adapt. Personal skills live in `~/.claude/skills/`, not in this repo — so updating the shared core (`git pull`) never touches them.

## Development

- `bash scripts/check.sh` — deterministic hygiene gate (frontmatter, no personal info, flat-model
  invariants, README/skills parity). Runs in CI on every push/PR.
- `evals/` — behavioral evals: give a cold agent a task + the skills, then assert on the files it
  produces. `evals/run_all.sh 3` runs every case ×3 and reports a pass-rate. **No API key** — it
  drives your logged-in Claude Code (`claude -p`) and loads the skills project-scoped, so it's
  self-contained. See [`evals/README.md`](evals/README.md) (includes a LangSmith adapter).
- Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) and [CHANGELOG.md](CHANGELOG.md).

## Credits

- The pattern comes from [Andrej Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) (the three-layer structure and the idea of processing a source once instead of re-searching it each time). His original write-up is included in `skills/llm-wiki/references/karpathy-pattern.md`.
- Built for [Obsidian](https://obsidian.md/).
- The skills were taken from a personal vault and generalized: hardcoded paths, personal collection names, and non-English text removed.

## License

MIT — see [LICENSE](LICENSE).
