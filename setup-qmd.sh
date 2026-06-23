#!/usr/bin/env bash
#
# Optional: install qmd (local BM25 + vector search) and index your vault.
# qmd is NOT required — the skills fall back to Grep automatically without it.
# qmd just makes wiki-query / wiki-research faster and more semantic.
#
# Usage:
#   ./setup-qmd.sh
#
# Reads OBSIDIAN_VAULT_PATH and QMD_WIKI_COLLECTION from ~/.obsidian-wiki/config
# (created by install.sh) or from ./.env.
set -euo pipefail

# 1. Locate config
CONFIG="$HOME/.obsidian-wiki/config"
[ -f "$CONFIG" ] || CONFIG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.env"
if [ ! -f "$CONFIG" ]; then
  echo "No config found. Run ./install.sh first, or create .env from .env.example." >&2
  exit 1
fi
# shellcheck disable=SC1090
set -a; . "$CONFIG"; set +a

VAULT="${OBSIDIAN_VAULT_PATH:?Set OBSIDIAN_VAULT_PATH in $CONFIG}"
COLLECTION="${QMD_WIKI_COLLECTION:-wiki}"
VAULT="${VAULT/#\~/$HOME}"   # expand leading ~

# 2. Install qmd if missing
if ! command -v qmd >/dev/null 2>&1; then
  if ! command -v npm >/dev/null 2>&1; then
    echo "npm not found. Install Node.js first: https://nodejs.org" >&2
    exit 1
  fi
  echo "Installing qmd (npm i -g @tobilu/qmd)..."
  npm install -g @tobilu/qmd
else
  echo "qmd already installed: $(qmd --version 2>/dev/null | head -1)"
fi

# 3. Index the vault as a collection
echo "Indexing $VAULT as collection '$COLLECTION'..."
qmd collection add "$VAULT" --name "$COLLECTION"

# 4. Build vector embeddings for semantic search
echo "Building embeddings..."
qmd embed

echo ""
echo "Done. Verify with:  qmd collection list"
echo "The wiki-query / wiki-research skills will now use qmd automatically."
echo ""
echo "Tip: to auto-refresh the index on changes, see 'qmd collection update-cmd'."
