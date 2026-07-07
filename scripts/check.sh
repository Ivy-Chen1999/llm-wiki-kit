#!/usr/bin/env bash
# Deterministic repo-hygiene checks — no API key, no agent needed.
# Guards the invariants that keep the kit clone-and-go and on the flat model.
# Run locally before pushing; also runs in CI (.github/workflows/ci.yml).
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
fails=0
ok(){   printf '  \033[32mok\033[0m   %s\n' "$1"; }
bad(){  printf '  \033[31mFAIL\033[0m %s\n' "$1"; fails=$((fails+1)); }

# 1. every skill has SKILL.md with name + description frontmatter
for d in skills/*/; do
  f="$d/SKILL.md"
  [ -f "$f" ] || { bad "missing $f"; continue; }
  head -20 "$f" | grep -qE "^name:"        || bad "$f: no 'name:' frontmatter"
  head -20 "$f" | grep -qE "^description:" || bad "$f: no 'description:' frontmatter"
done
[ "$fails" -eq 0 ] && ok "all skills have name/description frontmatter"

# 2. no CJK anywhere shippable
if grep -rlP '[\x{4e00}-\x{9fff}]' skills/ README.md .env.example vault-template/ evals/ 2>/dev/null | grep -q .; then
  bad "CJK found in shipped files"; else ok "no CJK in shipped files"; fi

# 3. no personal info / machine-specific absolute paths
if grep -rniE "yuxin|futurice|iCloud~md~obsidian" skills/ README.md .env.example install.sh evals/ 2>/dev/null | grep -q .; then
  bad "personal info leaked"; else ok "no personal info"; fi

# 4. flat-model regression guards
if grep -rn "_raw/" skills/ 2>/dev/null | grep -q .; then
  bad "'_raw/' present (staging dir must be 'raw/')"; else ok "no '_raw/' (staging is raw/)"; fi
if grep -rnE 'VAULT[_A-Z]*[}/]*/(index|hot|log|tags)\.md' skills/ 2>/dev/null | grep -v "_system/" | grep -q .; then
  bad "bookkeeping file referenced at vault root (must be under _system/)"; else ok "bookkeeping under _system/"; fi

# 5. shell scripts parse
for s in install.sh setup-qmd.sh evals/*.sh scripts/*.sh; do
  [ -f "$s" ] || continue
  bash -n "$s" && ok "bash -n $s" || bad "bash -n $s"
done

# 6. README skill table count == skills on disk
rows=$(grep -cE '^\| `[a-z]' README.md)
dirs=$(ls -d skills/*/ | wc -l | tr -d ' ')
[ "$rows" = "$dirs" ] && ok "README lists all $dirs skills" || bad "README table ($rows) != skills dir ($dirs)"

echo
[ "$fails" -eq 0 ] && { echo "ALL CHECKS PASSED"; exit 0; } || { echo "$fails CHECK(S) FAILED"; exit 1; }
