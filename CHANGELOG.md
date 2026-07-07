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
