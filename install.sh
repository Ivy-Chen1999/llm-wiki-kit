#!/usr/bin/env bash
#
# llm-wiki-kit installer
# Symlinks the bundled skills into your agent skills directory and creates a
# global config so the skills work from any project directory.
#
# Usage:
#   ./install.sh                 # install into ~/.agents/skills (default)
#   ./install.sh ~/.claude/skills  # install into a different skills dir
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
TARGET="${1:-$HOME/.agents/skills}"
CONFIG_DIR="$HOME/.obsidian-wiki"

echo "llm-wiki-kit installer"
echo "  source : $SKILLS_SRC"
echo "  target : $TARGET"
echo ""

mkdir -p "$TARGET"

linked=0
skipped=0
for dir in "$SKILLS_SRC"/*/; do
  name="$(basename "$dir")"
  dest="$TARGET/$name"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "  skip   $name (already exists — remove it first to relink)"
    skipped=$((skipped + 1))
    continue
  fi
  ln -s "$dir" "$dest"
  echo "  link   $name"
  linked=$((linked + 1))
done

echo ""
echo "Skills: $linked linked, $skipped skipped."

# Global config so skills resolve the vault path from any directory.
if [ ! -f "$CONFIG_DIR/config" ]; then
  mkdir -p "$CONFIG_DIR"
  cp "$REPO_DIR/.env.example" "$CONFIG_DIR/config"
  echo ""
  echo "Created $CONFIG_DIR/config — EDIT IT and set OBSIDIAN_VAULT_PATH."
else
  echo ""
  echo "Config already present at $CONFIG_DIR/config (left untouched)."
fi

echo ""
echo "Next steps:"
echo "  1. Edit $CONFIG_DIR/config and set OBSIDIAN_VAULT_PATH."
echo "  2. Copy vault-template/ to that path (or run the wiki-setup skill)."
echo "  3. Open the vault in Obsidian and start with wiki-ingest / wiki-query."
