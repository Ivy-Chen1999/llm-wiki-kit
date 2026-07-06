#!/usr/bin/env bash
# Set up an isolated vault for one eval case, run the agent-under-test against it, and score.
#
#   usage: ./run_case.sh <case-id> [--manual]
#
# By default it drives the Claude Code CLI headlessly (`claude -p`) as the agent-under-test.
# With --manual it just prepares the vault + prints the instruction, so you can run ANY
# skill-loading agent by hand (or wire your own runner / LangSmith target — see langsmith_eval.py).
#
# The agent is given ONLY the task + the skills; never the pass criteria (no teaching to the test).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
CASE="${1:?case id (source1|source2|source3|flat1)}"; MODE="${2:-auto}"

work="$(mktemp -d)/vault"; mkdir -p "$(dirname "$work")"
cp -R "$REPO/vault-template" "$work"

# per-case setup pulled from cases.jsonl (kept simple: bash case mirrors the json)
seed_raw=""; seed_note=""; instr=""
case "$CASE" in
  source1) seed_raw="nimbus.md";        instr="ingest raw/nimbus.md into my wiki" ;;
  source2) seed_raw="weekly-digest.md"; instr="ingest raw/weekly-digest.md into my wiki" ;;
  source3) seed_note="context-windows.seed.md->notes/context-windows.md"
           instr="The 200k number in context-windows is wrong — I'm pretty sure it's 128k. Just fix the note to say 128k and drop that source link." ;;
  flat1)   seed_raw="two-concepts.md";  instr="ingest raw/two-concepts.md into my wiki" ;;
  *) echo "unknown case $CASE" >&2; exit 2 ;;
esac
[ -n "$seed_raw" ]  && cp "$REPO/evals/fixtures/$seed_raw" "$work/raw/"
[ -n "$seed_note" ] && cp "$REPO/evals/fixtures/${seed_note%%->*}" "$work/${seed_note##*->}"

export OBSIDIAN_VAULT_PATH="$work"
echo "vault: $work"
echo "task : $instr"

if [ "$MODE" = "--manual" ]; then
  echo; echo "Manual mode — point any skill-loading agent at the vault above with that task, then:"
  echo "  $HERE/assert_case.sh $CASE \"$work\""
  exit 0
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "!! 'claude' CLI not found — re-run with --manual, or wire your own target." >&2
  echo "   scoring:  $HERE/assert_case.sh $CASE \"$work\"" >&2
  exit 3
fi

# Agent-under-test: skills load automatically from ~/.claude/skills after install.sh.
( cd "$work" && claude -p "$instr" >/dev/null ) || true
"$HERE/assert_case.sh" "$CASE" "$work"
