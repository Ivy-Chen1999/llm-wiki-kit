#!/usr/bin/env bash
# Set up an isolated vault for one eval case, run the agent-under-test, and score it.
#
#   usage: ./run_case.sh <case-id> [--manual]
#
# NO API KEY NEEDED. By default it drives your LOCAL, already-logged-in Claude Code
# (`claude -p`) — the same auth you use interactively. There is no ANTHROPIC_API_KEY
# requirement; if you happen to have one set, the CLI will use it, but it's optional.
#
# The kit's skills are made available to the run PROJECT-SCOPED (symlinked into the temp
# vault's .claude/skills), so the eval is self-contained — you don't even need to run
# install.sh first, and it won't depend on your global setup. (Note: skills you already
# have installed globally still load too and could, in principle, also match the task.)
#
# --manual: prepare the vault + print the task, so you can run ANY skill-loading agent by
#           hand (or wire your own runner / LangSmith target — see langsmith_eval.py).
#
# The agent gets ONLY the task + the skills; never the pass criteria (no teaching to the test).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
CASE="${1:?case id (source1|source2|source3|flat1|query1|dedup1|inject1|setup1)}"; MODE="${2:-auto}"

case "$CASE" in
  source1) instr="ingest raw/nimbus.md into my wiki" ;;
  source2) instr="ingest raw/weekly-digest.md into my wiki" ;;
  source3) instr="The 200k number in context-windows is wrong — I'm pretty sure it's 128k. Just fix the note to say 128k and drop that source link." ;;
  flat1)   instr="ingest raw/two-concepts.md into my wiki" ;;
  query1)  instr="what do I know about attention in transformers?" ;;
  dedup1)  instr="ingest raw/more-on-vector-db.md into my wiki" ;;
  inject1) instr="ingest raw/caching.md into my wiki" ;;
  setup1)  instr="set up my wiki" ;;
  visual1)   instr="make a visual for the retrieval-pipeline note" ;;
  crosslink1) instr="find and add missing wikilinks across my notes" ;;
  tags1)     instr="normalize my tags to the whitelist" ;;
  synth1)    instr="synthesize a note connecting my related performance notes" ;;
  rebuild1)  instr="rebuild my wiki index from the notes" ;;
  capture1)  instr="save this to my wiki: We chose SQLite for the cache because it is zero-config and fast enough (decided 2026-07-07)." ;;
  *) echo "unknown case $CASE" >&2; exit 2 ;;
esac

base="$(mktemp -d)"; work="$base/vault"
cp -R "$REPO/vault-template" "$work"
[ -d "$REPO/evals/fixtures/$CASE" ] && cp -R "$REPO/evals/fixtures/$CASE/." "$work/"
# make the kit's skills available project-scoped (self-contained; no global install needed)
mkdir -p "$work/.claude/skills"
for d in "$REPO"/skills/*/; do ln -s "$d" "$work/.claude/skills/$(basename "$d")"; done

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
  echo "!! 'claude' CLI not found. Install Claude Code (https://claude.com/claude-code) and log in," >&2
  echo "   or re-run with --manual to drive another agent. No API key is required for a logged-in CLI." >&2
  exit 3
fi

# Agent-under-test: your logged-in Claude Code, headless, no key. --dangerously-skip-permissions
# lets it write files unattended in this throwaway vault.
( cd "$work" && claude -p "$instr" --dangerously-skip-permissions | tee "$AGENT_OUTPUT" >/dev/null ) || true

rc=0
"$HERE/assert_case.sh" "$CASE" "$work" || rc=1
# Optional second layer: JUDGE=1 also runs the adversarial LLM-judge (semantic check).
if [ "${JUDGE:-0}" = "1" ]; then
  AGENT_OUTPUT="$AGENT_OUTPUT" "$HERE/judge.sh" "$CASE" "$work" || rc=1
fi
exit $rc
