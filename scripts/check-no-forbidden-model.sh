#!/usr/bin/env bash
# scripts/check-no-forbidden-model.sh
# CI check: ensure no agent, command, or default config references
# the forbidden model `opencode-go/minimax-m3`. The user directive is
# "nunca se va a ejecutar MiniMax de OpenCode".
#
# Exits 0 (clean) if no matches are found in active code.
# Exits 1 (failure) if matches are found outside of whitelisted docs.
#
# Whitelist (where references are ALLOWED):
#   - AGENTS.md (historical documentation)
#   - docs/research/experiments/2026-07-12-rust-gui-app-v3.md (post-mortem)
#
# Usage: ./scripts/check-no-forbidden-model.sh
# Or in CI: see .github/workflows/ if/when added.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORBIDDEN_MODEL="opencode-go/minimax-m3"

# Files where the forbidden model is ALLOWED to appear (historical context).
WHITELIST_FILES=(
  "opencode-moa/AGENTS.md"
  "opencode-moa/CHANGELOG.md"
  "docs/research/experiments/2026-07-11-rust-gui-app.md"
  "docs/research/experiments/2026-07-12-rust-gui-app-v3.md"
  "docs/proposals/001-orquestador-nativo-opencode.md"
  "docs/papers/DRAFT-multi-model-orchestration.md"
)

# Build a grep --exclude list from the whitelist (relative to REPO_ROOT).
EXCLUDE_ARGS=()
for FILE in "${WHITELIST_FILES[@]}"; do
  EXCLUDE_ARGS+=("--exclude=$(basename "$FILE")")
done

echo "=== check-no-forbidden-model.sh ==="
echo "Repo:       $REPO_ROOT"
echo "Forbidden:  $FORBIDDEN_MODEL"
echo "Whitelist:  ${WHITELIST_FILES[*]}"
echo ""

# Search active code (agents/, commands/, *.json, *.md except whitelist).
# We use --exclude with basenames because grep --exclude is filename-pattern based.
MATCHES=$(grep -rn "$FORBIDDEN_MODEL" \
  --include="*.md" \
  --include="*.json" \
  "$REPO_ROOT" \
  "${EXCLUDE_ARGS[@]}" 2>/dev/null || true)

# Filter out whitelist files by full path (grep --exclude only matches basenames).
FILTERED_MATCHES=$(echo "$MATCHES" | grep -v -F -f <(printf "%s\n" "${WHITELIST_FILES[@]/#/$REPO_ROOT/}") || true)

if [ -n "$FILTERED_MATCHES" ]; then
  echo "FAIL: forbidden model '$FORBIDDEN_MODEL' found in active code:"
  echo ""
  echo "$FILTERED_MATCHES"
  echo ""
  echo "If this is intentional (e.g. for backward compatibility), either:"
  echo "  1. Remove the reference from the active file"
  echo "  2. Add the file path to WHITELIST_FILES in this script"
  echo ""
  exit 1
fi

echo "PASS: no forbidden model '$FORBIDDEN_MODEL' in active code."
exit 0