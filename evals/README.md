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

Cases live in [`cases.jsonl`](cases.jsonl); inputs in [`fixtures/`](fixtures/).

## Run it

Skills must be installed first (`./install.sh`), so the agent-under-test loads them.

```bash
# one case, end-to-end (sets up an isolated vault, runs `claude -p`, scores it)
evals/run_case.sh source3

# all cases
for c in source1 source2 source3 flat1; do evals/run_case.sh "$c"; done

# no `claude` CLI, or want to test another agent? prepare + print the task, run your
# agent by hand, then score the resulting vault:
evals/run_case.sh flat1 --manual
evals/assert_case.sh flat1 /path/to/that/vault
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

1. Drop a fixture in `fixtures/`.
2. Add a line to `cases.jsonl` (`id`, `skill`, `seed_raw`/`seed_note`, `instruction`, `asserts`).
3. Add a `case` branch to `assert_case.sh` with the hard checks, and mirror the setup in `run_case.sh`.
