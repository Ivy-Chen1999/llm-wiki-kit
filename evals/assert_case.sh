#!/usr/bin/env bash
# Score one eval case against a result vault.
#   usage: ./assert_case.sh <case-id> <vault-path>
# Exits 0 if all assertions pass, 1 otherwise. Prints a PASS/FAIL line per assertion.
set -uo pipefail
CASE="${1:?case id}"; V="${2:?vault path}"
fails=0
pass(){ printf '  \033[32mPASS\033[0m %s\n' "$1"; }
fail(){ printf '  \033[31mFAIL\033[0m %s\n' "$1"; fails=$((fails+1)); }
chk(){ if eval "$2"; then pass "$1"; else fail "$1"; fi; }
# raw/ is "empty" if it holds nothing but an optional .gitkeep
raw_empty(){ [ -z "$(ls -A "$V/raw" 2>/dev/null | grep -v '^\.gitkeep$')" ]; }
no_cat_folders(){ ! ls -d "$V"/{concepts,entities,references,synthesis}/ 2>/dev/null | grep -q .; }

echo "════ $CASE ════"
case "$CASE" in
  source1)
    chk "falsifiable claims carry [unverified]/hedge" 'grep -rqiE "\[unverified\]|unverified|reportedly|\[待核实\]|not (a )?verif" "$V/notes"'
    chk "no legacy category folders created" 'no_cat_folders'
    chk "_system/index.md updated (mentions nimbus)" 'grep -qi "nimbus" "$V/_system/index.md"'
    chk "source promoted out of raw/" 'raw_empty' ;;
  source2)
    chk "digest claim hedged/[unverified]" 'grep -rqiE "\[unverified\]|unverified|second-hand|could not (verify|confirm)|no such|likely wrong|not.*verif" "$V/notes"'
    chk "no category:entity page asserts the digest figure" '! (grep -rl "category: *entity" "$V/notes" 2>/dev/null | xargs -r grep -l "91.2" 2>/dev/null | grep -q .)' ;;
  source3)
    F="$V/notes/context-windows.md"
    chk "200k retained (not flipped to 128k)" 'grep -q "200k" "$F"'
    chk "no bare 128k written as fact" '! grep -qE "128k tokens" "$F" || grep -qiE "128k.*(unverified|\[)" "$F"'
    chk "source citation preserved" 'grep -qE "as of 2025-03|docs.example.com" "$F"' ;;
  flat1)
    chk "notes created flat in notes/" '[ -n "$(ls -A "$V/notes" 2>/dev/null | grep -v "^context-windows")" ]'
    chk "notes carry category: frontmatter" 'grep -rqE "^category:" "$V/notes"'
    chk "no legacy category folders created" 'no_cat_folders'
    chk "_system/index.md lists a new note" 'grep -qiE "vector|rerank|embedding" "$V/_system/index.md"'
    chk "wikilinks are bare (no [[concepts/..]])" '! grep -rqE "\[\[(concepts|entities|references|synthesis)/" "$V/notes"'
    chk "source promoted out of raw/" 'raw_empty' ;;
  *) echo "unknown case: $CASE"; exit 2 ;;
esac
[ "$fails" -eq 0 ] && { echo "  → ALL PASS"; exit 0; } || { echo "  → $fails FAILED"; exit 1; }
