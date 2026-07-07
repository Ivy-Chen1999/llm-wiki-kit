#!/usr/bin/env bash
# LLM-judge for an eval case — a SEMANTIC check that complements the structural assertions in
# assert_case.sh. Structural checks verify form (a keyword is present); the judge verifies meaning
# (the claim is actually hedged / the answer is actually grounded), which keyword greps can be
# fooled by. Adversarial by design: it defaults to FAIL when the evidence is not clearly satisfying.
#
#   usage: ./judge.sh <case-id> <vault-path>
#   env:   AGENT_OUTPUT=<file>   (agent's answer; used for answer-based cases)
#
# NO API KEY: uses your local, logged-in Claude Code (`claude -p`). Judging is read-only (it never
# touches a vault), so it's safe to run anywhere Claude Code is authenticated.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASE="${1:?case id}"; V="${2:?vault path}"
OUT="${AGENT_OUTPUT:-$(dirname "$V")/agent_output.txt}"

command -v claude >/dev/null 2>&1 || { echo "  \033[33mSKIP\033[0m judge ($CASE): 'claude' CLI not found"; exit 0; }

# criterion = the case's "tests" sentence from cases.jsonl
crit=$(grep "\"id\":\"$CASE\"" "$HERE/cases.jsonl" | sed -n 's/.*"tests":"\([^"]*\)".*/\1/p')
[ -n "$crit" ] || { echo "  no criterion for $CASE"; exit 2; }

# evidence = resulting notes (+ the agent's answer, if any)
evidence=$(
  for f in "$V"/notes/*.md; do [ -f "$f" ] && { echo "----- $(basename "$f") -----"; cat "$f"; echo; }; done
  [ -s "$OUT" ] && { echo "----- agent answer -----"; cat "$OUT"; }
)

prompt="You are a STRICT, adversarial evaluator for an LLM-maintained wiki. Judge ONLY whether the
agent's output below satisfies this one criterion. Be skeptical: if the evidence does not CLEARLY
satisfy the criterion, answer FAIL. Do not be lenient or give benefit of the doubt.

CRITERION: $crit

AGENT OUTPUT / RESULTING NOTES:
$evidence

Answer with EXACTLY one line, starting with the word PASS or FAIL, then a colon and a one-sentence reason."

resp=$(cd "$V" && claude -p "$prompt" --dangerously-skip-permissions 2>/dev/null | tr -d '\r')
line=$(printf '%s\n' "$resp" | grep -oiE '^(PASS|FAIL):.*' | head -1)
[ -n "$line" ] || line=$(printf '%s\n' "$resp" | grep -oiE '(PASS|FAIL):.*' | head -1)

verdict=$(printf '%s' "$line" | grep -oiE '^(PASS|FAIL)' | tr '[:lower:]' '[:upper:]')
case "$verdict" in
  PASS) printf '  \033[32mJUDGE PASS\033[0m %s — %s\n' "$CASE" "${line#*:}"; exit 0 ;;
  FAIL) printf '  \033[31mJUDGE FAIL\033[0m %s — %s\n' "$CASE" "${line#*:}"; exit 1 ;;
  *)    printf '  \033[33mJUDGE ????\033[0m %s — unparseable verdict: %s\n' "$CASE" "$(printf '%s' "$resp" | head -c 200)"; exit 2 ;;
esac
