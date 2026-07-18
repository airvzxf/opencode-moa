#!/usr/bin/env bash
# install.sh — Install opencode-moa into ~/.config/opencode/
# This script copies ONLY the installable files (agents/, commands/, orquestador.json).
# Documentation and proposals stay in the repo for reference.

set -euo pipefail

# Detect config directory
if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
  CONFIG_DIR="$XDG_CONFIG_HOME/opencode"
else
  CONFIG_DIR="$HOME/.config/opencode"
fi

# Detect repo root (where this script lives)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="$REPO_ROOT/opencode-moa"

# Verify bundle exists
if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "ERROR: Bundle directory not found at $BUNDLE_DIR"
  echo "Make sure you're running this from the opencode-moa repo root."
  exit 1
fi

echo "=== Installing opencode-moa ==="
echo "Source: $BUNDLE_DIR"
echo "Target: $CONFIG_DIR"
echo

# Create directories
mkdir -p "$CONFIG_DIR/agents"
mkdir -p "$CONFIG_DIR/commands"

# Copy agents
echo "Copying agents..."
AGENT_FILES=("$BUNDLE_DIR/agents/"*.md)
cp "${AGENT_FILES[@]}" "$CONFIG_DIR/agents/"
echo "  ✓ ${#AGENT_FILES[@]} agent files"

# Copy commands
echo "Copying commands..."
COMMAND_FILES=("$BUNDLE_DIR/commands/"*.md)
cp "${COMMAND_FILES[@]}" "$CONFIG_DIR/commands/"
echo "  ✓ ${#COMMAND_FILES[@]} command files"

# Copy config (don't overwrite if exists)
if [[ -f "$CONFIG_DIR/orquestador.json" ]]; then
  echo
  echo "WARNING: $CONFIG_DIR/orquestador.json already exists."
  read -p "Overwrite? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "  Skipped orquestador.json (existing file preserved)"
  else
    cp "$BUNDLE_DIR/orquestador.json" "$CONFIG_DIR/"
    echo "  ✓ orquestador.json overwritten"
  fi
else
  cp "$BUNDLE_DIR/orquestador.json" "$CONFIG_DIR/"
  echo "  ✓ orquestador.json"
fi

echo
echo "=== Installation complete ==="
echo
echo "Next steps:"
echo "  1. Verify: ls $CONFIG_DIR/agents/  (should show ${#AGENT_FILES[@]} files)"
echo "  2. Open OpenCode in any project: opencode"
echo
echo "For more info, see docs/installation.md"