# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/); this project aims for
[Semantic Versioning](https://semver.org/) once it cuts its first tagged release.

## [Unreleased]

### Added
- `wiki-sourcing` skill — the sourcing & verification doctrine (claim-type gate, three verification
  states, degradation ≠ refutation, anti-sycophancy). Referenced by every write-path skill.
- `wiki-visual` skill — turn a note into a self-contained, shareable HTML one-pager (diagram or card).
- `evals/` — behavioral eval suite: 7 cases (sourcing, anti-sycophancy, flat-model conformance,
  retrieval, dedup/update-bias, prompt-injection defense) with a CI-ready assertion scorer, a
  k-repeat pass-rate runner, and a LangSmith adapter.
- `scripts/check.sh` + `.github/workflows/ci.yml` — deterministic, keyless repo-hygiene gate.
- `.github/workflows/eval.yml` — manual behavioral-eval workflow (gated on `ANTHROPIC_API_KEY`).
- `install.sh --copy` — copy skills instead of symlinking (survives moving/deleting the repo).

### Changed
- **Evals run key-free on your local Claude Code.** `run_case.sh` drives `claude -p` (your logged-in
  session — no `ANTHROPIC_API_KEY`) and loads the skills project-scoped into each throwaway vault, so
  the suite is self-contained (no `install.sh` needed). The LangSmith adapter needs only
  `LANGSMITH_API_KEY`; the CI eval workflow documents a keyless self-hosted-runner path.
- **All skills migrated to one flat vault model**: notes live in `notes/` with a frontmatter
  `category:`; bookkeeping standardized under `_system/`; staging standardized to `raw/`. Previously
  19/20 skills assumed per-category folders while the template shipped the flat layout.
- Disambiguated the three ingest skills (`wiki-ingest`, `ingest-url`, `data-ingest`) so their triggers
  are mutually exclusive and each defers to the right sibling.
- `install.sh` now reports skill-name collisions instead of silently skipping, and documents that it
  never modifies an existing `~/.claude` setup.

### Fixed
- Folder-qualified wikilinks (`[[concepts/x]]`) normalized to bare `[[x]]`.
- Removed the documentation's now-defunct "one folder per category" alternative.
- **`wiki-setup` is now non-destructive on an existing vault** — it creates only *missing*
  scaffolding and never overwrites existing notes, `index.md`, `log.md`, `tags.md`, `.env`, or
  Obsidian config. Makes it safe to point at a colleague's existing vault. Covered by the new
  `setup1` eval case.

### Added (this round)
- README **"For Obsidian users"** section — key-free setup via the Claudian plugin or Claude Code,
  and how to adopt a new vs. existing vault safely.
- `setup1` eval case — proves non-destructive setup (existing index/notes preserved).
- **Adversarial LLM-judge** (`evals/judge.sh`, opt-in `JUDGE=1`) — a strict semantic second layer on
  top of the structural assertions, run key-free on local Claude Code. Validated: passes correct
  results, fails a deliberately-broken one.
- **Eval coverage now spans every actionable skill — 22 cases**, all validated green on cold agents.
  Round 1 added `visual1`, `crosslink1`, `tags1`, `synth1`, `rebuild1`, `capture1`; round 2 added
  `data1` (data-ingest), `url1` (ingest-url), `export1` (wiki-export), `dash1` (wiki-dashboard),
  `color1` (graph-colorize), `status1` (wiki-status), and `claudehist1`/`codexhist1`
  (history-ingest, run hermetically against `CLAUDE_HISTORY_PATH`/`CODEX_HISTORY_PATH` fixtures —
  never the real `~/.claude`/`~/.codex`).
- `vault-template/.gitignore` (keeps `_visual/`, `.env`, `_archives/`, Obsidian workspace state out of
  git); README CI + license badges.
