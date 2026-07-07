# Evals

Behavioral evals for the kit's skills. Static checks (does the text parse, no stray paths)
tell you the skills aren't *broken*; these tell you an agent handed the skills actually
*does the right thing*. Each case gives a cold agent only a task + the skills — never the
pass criteria — then asserts on the files it produced.

## What's covered

| Case | Skill(s) | What it proves |
|------|----------|----------------|
| `source1` | wiki-ingest + wiki-sourcing | Unverifiable falsifiable facts are hedged (`[unverified]`), not asserted as bare fact. |
| `source2` | wiki-ingest + wiki-sourcing | A claim that only appears in a digest is treated as second-hand — hedged, not minted into a confident entity page. |
| `source3` | wiki-update + wiki-sourcing | **Anti-sycophancy**: sourceless user pushback does not flip a verified, sourced claim. |
| `flat1`   | wiki-ingest | Flat-model conformance: notes land in `notes/` with frontmatter `category`, no per-category folders, bare `[[links]]`, index updated. |
| `query1`  | wiki-query | Retrieval: the answer is grounded in and cites the right seeded note, not an unrelated one. |
| `dedup1`  | wiki-ingest | Update-over-create: an overlapping source expands the existing note instead of creating a duplicate. |
| `inject1` | wiki-ingest (Content Trust Boundary) | Prompt-injection defense: instructions embedded in a source are distilled as content, never executed. |

Cases live in [`cases.jsonl`](cases.jsonl); each case's setup is an overlay dir under
[`fixtures/`](fixtures/) (`fixtures/<case>/` is copied on top of the starter vault).

## Run it

Skills must be installed first (`./install.sh`), so the agent-under-test loads them.

```bash
# one case, end-to-end (sets up an isolated vault, runs `claude -p`, scores it)
evals/run_case.sh source3

# EVERY case × 3 runs, reported as a pass-rate (LLM output varies — one green run isn't enough)
evals/run_all.sh 3

# no `claude` CLI, or want to test another agent? prepare + print the task, run your
# agent by hand, then score the resulting vault:
evals/run_case.sh flat1 --manual
AGENT_OUTPUT=<answer-file> evals/assert_case.sh flat1 /path/to/that/vault
```

`assert_case.sh` exits non-zero if any assertion fails, so it drops straight into CI.

## LangSmith

[`langsmith_eval.py`](langsmith_eval.py) wraps the same cases + assertions as a LangSmith
dataset and evaluators, for traces and run-over-run comparison:

```bash
pip install langsmith
export LANGSMITH_API_KEY=...   ANTHROPIC_API_KEY=...
python evals/langsmith_eval.py
```

The scores are identical to `assert_case.sh` — LangSmith just adds tracing and history.
Swap the agent-under-test by editing `run_agent()` in that file.

## Adding a case

1. Create `fixtures/<case>/` as an overlay — whatever it contains (e.g. `raw/foo.md`,
   `notes/bar.md`, `_system/index.md`) is copied on top of the starter vault.
2. Add a line to `cases.jsonl` (`id`, `skill`, `instruction`, `tests`, `asserts`).
3. Add the case's `instruction` to the `case` map in `run_case.sh`, and a scoring branch in
   `assert_case.sh` (hard file assertions; use `$OUT` for answer-based cases like `query1`).
