#!/usr/bin/env bash
#
# llm-wiki-kit installer — interactive, one command does everything:
#   1. links the skills into your agent's skills directory
#   2. asks where your vault should live
#   3. creates the vault from the template (if it doesn't exist yet)
#   4. writes the config file with your real vault path
#   5. optionally installs local search (qmd)
#
# Just run:  ./install.sh
# Advanced:  ./install.sh --skills-dir ~/.claude/skills
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
CONFIG_DIR="$HOME/.obsidian-wiki"
CONFIG_FILE="$CONFIG_DIR/config"
SKILLS_DIR="$HOME/.agents/skills"

# --- parse optional flag ---
while [ $# -gt 0 ]; do
  case "$1" in
    --skills-dir) SKILLS_DIR="$2"; shift 2 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
ask()  { # ask "prompt" "default" -> echoes answer
  local reply
  if [ -t 0 ]; then printf '%s [%s]: ' "$1" "$2" >&2; read -r reply || true
  else reply=""; fi
  echo "${reply:-$2}"
}

say "llm-wiki-kit installer"

# --- 1. prerequisites ---
command -v git >/dev/null 2>&1 || warn "git not found — you'll need it to update the kit later."

# --- 2. link skills ---
say "Step 1/4 — linking skills into $SKILLS_DIR"
mkdir -p "$SKILLS_DIR"
linked=0; skipped=0
for dir in "$SKILLS_SRC"/*/; do
  name="$(basename "$dir")"; dest="$SKILLS_DIR/$name"
  if [ -e "$dest" ] || [ -L "$dest" ]; then skipped=$((skipped+1)); continue; fi
  ln -s "$dir" "$dest"; linked=$((linked+1))
done
ok "$linked skills linked, $skipped already present"

# --- 3. choose / create the vault ---
say "Step 2/4 — your wiki vault"
DEFAULT_VAULT="$HOME/Documents/my-wiki"
VAULT="$(ask "Where should the vault live?" "$DEFAULT_VAULT")"
VAULT="${VAULT/#\~/$HOME}"   # expand leading ~

if [ -d "$VAULT" ] && [ -n "$(ls -A "$VAULT" 2>/dev/null)" ]; then
  warn "$VAULT already exists and is not empty — leaving its contents alone."
else
  mkdir -p "$VAULT"
  cp -R "$REPO_DIR/vault-template/." "$VAULT/"
  # stamp the template's TIMESTAMP placeholders with today's date
  TODAY="$(date +%Y-%m-%d)"
  for f in "$VAULT"/_system/*.md; do
    [ -f "$f" ] && TODAY="$TODAY" perl -i -pe 's/TIMESTAMP/$ENV{TODAY}/g' "$f"
  done
  ok "vault created at $VAULT"
fi

# --- 4. write config ---
say "Step 3/4 — writing config to $CONFIG_FILE"
mkdir -p "$CONFIG_DIR"
if [ -f "$CONFIG_FILE" ]; then
  warn "config already exists — not overwriting. Edit it by hand if needed: $CONFIG_FILE"
else
  # start from the example, then set the real vault path
  sed "s|^OBSIDIAN_VAULT_PATH=.*|OBSIDIAN_VAULT_PATH=\"$VAULT\"|" "$REPO_DIR/.env.example" > "$CONFIG_FILE"
  ok "config written with OBSIDIAN_VAULT_PATH=$VAULT"
fi

# --- 5. optional search ---
say "Step 4/4 — local search (optional)"
SETUP_QMD="$(ask "Install local search now (needs Node/npm)? y/N" "N")"
case "$SETUP_QMD" in
  [yY]*) "$REPO_DIR/setup-qmd.sh" || warn "qmd setup skipped/failed — the skills will use Grep instead." ;;
  *) ok "Skipped. The skills work fine without it (they fall back to Grep)." ;;
esac

say "Done 🎉"
cat <<EOF
  Your vault:  $VAULT
  Config:      $CONFIG_FILE
  Skills:      $SKILLS_DIR

  Next:
   1. Open Obsidian → "Open folder as vault" → choose:
        $VAULT
   2. Ask your agent:  "ingest this article into my wiki"
                       "what do I know about X?"
                       "audit my wiki"
EOF
