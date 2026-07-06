#!/usr/bin/env python3
"""
LangSmith adapter for the llm-wiki-kit behavioral evals.

The eval logic lives in shell (`run_case.sh` sets up an isolated vault + runs the
agent-under-test; `assert_case.sh` scores the resulting files). This module wraps
those as a LangSmith dataset + evaluators so you get traces, scores, and run-over-run
comparison in the LangSmith UI.

What you need to actually run it (this repo ships no keys):
  pip install langsmith
  export LANGSMITH_API_KEY=...          # your LangSmith key
  export ANTHROPIC_API_KEY=...          # for the agent-under-test (Claude Code headless)
  ./install.sh                          # so the skills are loaded from ~/.claude/skills
  python evals/langsmith_eval.py

Design notes
------------
- `target()` is the agent-under-test. By default it shells out to run_case.sh, which
  drives `claude -p` and returns the result vault path. Swap in your own agent
  (Claude Agent SDK, another CLI) by editing `run_agent()` — the evaluators don't care
  how the vault got produced, only what's in it.
- Each assertion in cases.jsonl becomes an evaluator score in [0,1]; the case score is
  their mean. This keeps the LangSmith scores identical to `assert_case.sh` locally.
"""
from __future__ import annotations
import json, os, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
CASES = [json.loads(l) for l in (HERE / "cases.jsonl").read_text().splitlines() if l.strip()]


def run_agent(case_id: str) -> str:
    """Run the agent-under-test for a case; return the result vault path."""
    # run_case.sh prints 'vault: <path>' on its first line, then runs the agent + scorer.
    out = subprocess.run(
        ["bash", str(HERE / "run_case.sh"), case_id],
        capture_output=True, text=True,
    ).stdout
    for line in out.splitlines():
        if line.startswith("vault:"):
            return line.split("vault:", 1)[1].strip()
    raise RuntimeError(f"could not determine result vault for {case_id}:\n{out}")


def score(case_id: str, vault: str) -> float:
    """Fraction of the case's assertions that pass (via assert_case.sh)."""
    r = subprocess.run(["bash", str(HERE / "assert_case.sh"), case_id, vault],
                       capture_output=True, text=True)
    passes = r.stdout.count("PASS")
    total = passes + r.stdout.count("FAIL")
    return passes / total if total else 0.0


def main() -> None:
    try:
        from langsmith import Client, evaluate  # noqa
    except ImportError:
        sys.exit("pip install langsmith first (see module docstring for the full setup).")
    if not os.getenv("LANGSMITH_API_KEY"):
        sys.exit("set LANGSMITH_API_KEY (and ANTHROPIC_API_KEY for the agent).")

    client = Client()
    ds_name = "llm-wiki-kit-behavioral"
    if not client.has_dataset(dataset_name=ds_name):
        ds = client.create_dataset(ds_name, description="Behavioral evals for llm-wiki-kit skills")
        client.create_examples(
            inputs=[{"case_id": c["id"], "instruction": c["instruction"]} for c in CASES],
            outputs=[{"tests": c["tests"], "asserts": c["asserts"]} for c in CASES],
            dataset_id=ds.id,
        )

    def target(inputs: dict) -> dict:
        vault = run_agent(inputs["case_id"])
        return {"vault": vault, "score": score(inputs["case_id"], vault)}

    def assertions_pass(run, example) -> dict:
        return {"key": "assertions_pass", "score": run.outputs.get("score", 0.0)}

    evaluate(target, data=ds_name, evaluators=[assertions_pass],
             experiment_prefix="llm-wiki-kit", client=client)
    print("Done — see the experiment in your LangSmith project.")


if __name__ == "__main__":
    main()
