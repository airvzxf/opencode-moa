#!/usr/bin/env bash
# install.sh — Install opencode-moa into ~/.config/opencode/.
#
# Default behaviour (no flag, interactive shell):
#   copies the installable bundle (agents/, commands/, orquestador.json)
#   into the user's opencode config dir. Existing orquestador.json is
#   preserved unless the user explicitly answers 'y' to the overwrite
#   prompt. Agents are additive — files already present that no longer
#   exist in the new bundle are NOT removed (legacy compatibility).
#
# --force-upgrade:
#   non-interactive upgrade. Skips the TTY prompt and:
#   - removes installed agents that are no longer present in the new
#     bundle (orphans from prior versions)
#   - replaces orquestador.json after taking a timestamped .bak backup
#
# In a non-TTY shell WITHOUT --force-upgrade, existing orquestador.json
# is preserved and a warning is printed — re-run with --force-upgrade
# to overwrite.

set -euo pipefail

FORCE_UPGRADE=0
for arg in "$@"; do
  case "$arg" in
    --force-upgrade) FORCE_UPGRADE=1 ;;
    -h|--help)
      cat <<USAGE
Usage: install.sh [--force-upgrade]

  Default:  copies bundle files into \$CONFIG_DIR (additive).
            Existing orquestador.json is preserved unless you answer 'y'
            to the overwrite prompt.

  --force-upgrade:
            non-interactive upgrade. Removes orphan agents that are
            not in the new bundle and replaces orquestador.json after
            taking a timestamped .bak.

USAGE
      exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# --- paths ---
if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
  CONFIG_DIR="$XDG_CONFIG_HOME/opencode"
else
  CONFIG_DIR="$HOME/.config/opencode"
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="$REPO_ROOT/opencode-moa"

if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "ERROR: Bundle directory not found at $BUNDLE_DIR"
  echo "Make sure you're running this from the opencode-moa repo root."
  exit 1
fi

# Interactivity: stdin AND stdout both attached to a TTY
INTERACTIVE=0
if [ -t 0 ] && [ -t 1 ]; then INTERACTIVE=1; fi

echo "=== Installing opencode-moa ==="
echo "Source: $BUNDLE_DIR"
echo "Target: $CONFIG_DIR"
if [[ $FORCE_UPGRADE -eq 1 ]]; then
  echo "Mode:   --force-upgrade (non-interactive, will clean orphans + overwrite config)"
fi
echo

mkdir -p "$CONFIG_DIR/agents" "$CONFIG_DIR/commands"

# --- agents: copy bundle over installed ---
echo "Copying agents..."
AGENT_FILES=("$BUNDLE_DIR/agents/"*.md)
cp "${AGENT_FILES[@]}" "$CONFIG_DIR/agents/"
echo "  ✓ ${#AGENT_FILES[@]} agent files"

# --- agents: orphan cleanup (--force-upgrade only) ---
if [[ $FORCE_UPGRADE -eq 1 ]]; then
  shopt -s nullglob
  ORPHANS=()
  for installed in "$CONFIG_DIR/agents/"*.md; do
    [[ -f "$installed" ]] || continue
    base=$(basename "$installed")
    if [[ ! -f "$BUNDLE_DIR/agents/$base" ]]; then
      ORPHANS+=("$installed")
    fi
  done
  shopt -u nullglob
  if [[ ${#ORPHANS[@]} -gt 0 ]]; then
    echo
    echo "Removing ${#ORPHANS[@]} orphan agent(s) (not in new bundle):"
    for orphan in "${ORPHANS[@]}"; do
      echo "  - $(basename "$orphan")"
      rm -f "$orphan"
    done
  fi
fi

# --- commands ---
echo
echo "Copying commands..."
COMMAND_FILES=("$BUNDLE_DIR/commands/"*.md)
cp "${COMMAND_FILES[@]}" "$CONFIG_DIR/commands/"
echo "  ✓ ${#COMMAND_FILES[@]} command files"

# --- orquestador.json ---
echo
if [[ ! -f "$CONFIG_DIR/orquestador.json" ]]; then
  # No existing config — straightforward install.
  cp "$BUNDLE_DIR/orquestador.json" "$CONFIG_DIR/"
  echo "  ✓ orquestador.json"
elif [[ $FORCE_UPGRADE -eq 1 ]]; then
  # Explicit non-interactive upgrade: backup + overwrite.
  TS=$(date -u +%Y%m%d-%H%M%SZ)
  BACKUP="$CONFIG_DIR/orquestador.json.bak.$TS"
  cp "$CONFIG_DIR/orquestador.json" "$BACKUP"
  cp "$BUNDLE_DIR/orquestador.json" "$CONFIG_DIR/"
  echo "  ✓ orquestador.json (existing backed up to $(basename "$BACKUP"))"
elif [[ $INTERACTIVE -eq 1 ]]; then
  # Interactive upgrade: prompt, then backup + overwrite on 'y'.
  echo "WARNING: $CONFIG_DIR/orquestador.json already exists."
  read -p "Overwrite? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "  Skipped orquestador.json (existing file preserved)"
  else
    TS=$(date -u +%Y%m%d-%H%M%SZ)
    BACKUP="$CONFIG_DIR/orquestador.json.bak.$TS"
    cp "$CONFIG_DIR/orquestador.json" "$BACKUP"
    cp "$BUNDLE_DIR/orquestador.json" "$CONFIG_DIR/"
    echo "  ✓ orquestador.json (existing backed up to $(basename "$BACKUP"))"
  fi
else
  # Non-interactive without --force-upgrade: refuse to overwrite, warn.
  echo "WARNING: $CONFIG_DIR/orquestador.json already exists and stdin/stdout"
  echo "are not a TTY. Refusing to overwrite. Re-run with --force-upgrade to"
  echo "overwrite after backup, or run from an interactive shell to be prompted."
fi

echo
echo "=== Installation complete ==="
echo
echo "Next steps:"
echo "  1. Verify: ls $CONFIG_DIR/agents/  (should match the bundle)"
echo "  2. If opencode is running, restart it so it picks up the new agents/"
echo "     and orquestador.json:"
echo "       pkill -TERM -u \$USER -f 'opencode --auto'"
echo "     (a supervisor / systemd user instance will relaunch it within seconds)"
echo
echo "For more info, see docs/installation.md"
