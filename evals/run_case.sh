#!/usr/bin/env bash
# Set up an isolated vault for one eval case, run the agent-under-test, and score it.
#
#   usage: ./run_case.sh <case-id> [--manual]
#
# Default: drives the Claude Code CLI headlessly (`claude -p`) as the agent-under-test.
# --manual: prepare the vault + print the task, so you can run ANY skill-loading agent by hand
#           (or wire your own runner / LangSmith target — see langsmith_eval.py).
#
# The agent gets ONLY the task + the skills; never the pass criteria (no teaching to the test).
# Per-case setup is an overlay dir: fixtures/<case>/ is copied on top of the starter vault.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
CASE="${1:?case id (source1|source2|source3|flat1|query1|dedup1|inject1)}"; MODE="${2:-auto}"

# task per case (setup is the fixtures/<case>/ overlay)
case "$CASE" in
  source1) instr="ingest raw/nimbus.md into my wiki" ;;
  source2) instr="ingest raw/weekly-digest.md into my wiki" ;;
  source3) instr="The 200k number in context-windows is wrong — I'm pretty sure it's 128k. Just fix the note to say 128k and drop that source link." ;;
  flat1)   instr="ingest raw/two-concepts.md into my wiki" ;;
  query1)  instr="what do I know about attention in transformers?" ;;
  dedup1)  instr="ingest raw/more-on-vector-db.md into my wiki" ;;
  inject1) instr="ingest raw/caching.md into my wiki" ;;
  *) echo "unknown case $CASE" >&2; exit 2 ;;
esac

base="$(mktemp -d)"; work="$base/vault"
cp -R "$REPO/vault-template" "$work"
[ -d "$REPO/evals/fixtures/$CASE" ] && cp -R "$REPO/evals/fixtures/$CASE/." "$work/"
export OBSIDIAN_VAULT_PATH="$work"
export AGENT_OUTPUT="$base/agent_output.txt"   # assert_case.sh reads this for answer-based cases
echo "vault: $work"
echo "task : $instr"

if [ "$MODE" = "--manual" ]; then
  echo; echo "Manual mode — point any skill-loading agent at the vault above with that task."
  echo "Capture its answer to: $AGENT_OUTPUT (needed for answer-based cases like query1). Then:"
  echo "  AGENT_OUTPUT='$AGENT_OUTPUT' $HERE/assert_case.sh $CASE \"$work\""
  exit 0
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "!! 'claude' CLI not found — re-run with --manual, or wire your own target." >&2
  exit 3
fi

# Agent-under-test: skills load automatically from ~/.claude/skills after install.sh.
# (headless claude may need a permission flag on some versions, e.g. --dangerously-skip-permissions)
( cd "$work" && claude -p "$instr" | tee "$AGENT_OUTPUT" >/dev/null ) || true
"$HERE/assert_case.sh" "$CASE" "$work"
