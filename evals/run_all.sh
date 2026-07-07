#!/usr/bin/env bash
# Run every eval case K times and report a pass-rate per case (LLM behavior is non-deterministic,
# so a single green run is not enough — this measures stability).
#
#   usage: ./run_all.sh [K]        (default K=3)
#   env:   CASES="source1 flat1"   (subset; default = all)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K="${1:-3}"
CASES="${CASES:-source1 source2 source3 flat1 query1 dedup1 inject1 setup1}"

printf '\nRunning %s case(s) × %s run(s) each\n\n' "$(echo "$CASES" | wc -w | tr -d ' ')" "$K"
overall_fail=0
for c in $CASES; do
  passes=0
  for i in $(seq 1 "$K"); do
    if "$HERE/run_case.sh" "$c" >/dev/null 2>&1; then passes=$((passes+1)); fi
  done
  rate=$(( passes * 100 / K ))
  if [ "$passes" -eq "$K" ]; then col=32; else col=31; overall_fail=1; fi
  printf '  \033[%sm%3d%%\033[0m  %-8s (%d/%d runs all-assertions-pass)\n' "$col" "$rate" "$c" "$passes" "$K"
done
echo
[ "$overall_fail" -eq 0 ] && echo "STABLE: every case passed all $K runs" || echo "UNSTABLE: at least one case failed a run — inspect with ./run_case.sh <case>"
exit $overall_fail
