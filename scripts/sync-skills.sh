#!/usr/bin/env bash
# sync-skills.sh — mirror canonical .agents/skills/ into .claude/ and .codex/
# (or into global user directories with --global).
#
# Symlinks are avoided inside Git because Windows checkouts break them and
# formatters/linters stumble on symlinks. Real copies + CI drift check instead.
#
# Usage:
#   scripts/sync-skills.sh           Sync repo .agents/skills -> .claude/skills & .codex/skills
#   scripts/sync-skills.sh --check   Fail if repo mirrors have drifted (CI)
#   scripts/sync-skills.sh --global  Install/update enviroment skills in ~/.gemini/config/skills, ~/.agents/skills, ~/.claude/skills
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CANONICAL="$REPO_ROOT/.agents/skills"

MODE="sync"
case "${1:-}" in
  "") MODE="sync" ;;
  --check) MODE="check" ;;
  --global) MODE="global" ;;
  -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "Unknown argument: $1" >&2; exit 2 ;;
esac

[[ -d "$CANONICAL" ]] || { echo "Missing canonical dir: $CANONICAL" >&2; exit 1; }

REPO_MIRRORS=(
  "$REPO_ROOT/.claude/skills"
  "$REPO_ROOT/.codex/skills"
)

if [[ "$MODE" == "check" ]]; then
  status=0
  for mirror in "${REPO_MIRRORS[@]}"; do
    if [[ ! -d "$mirror" ]]; then
      echo "DRIFT: missing mirror directory $mirror" >&2
      status=1
      continue
    fi
    if ! diff -rq "$CANONICAL" "$mirror" >/dev/null 2>&1; then
      echo "DRIFT: $mirror is out of sync with $CANONICAL" >&2
      diff -ru "$CANONICAL" "$mirror" >&2 || true
      status=1
    fi
  done
  if [[ "$status" -eq 0 ]]; then
    echo "OK: .claude/skills and .codex/skills are byte-identical to .agents/skills"
  else
    echo "Run 'bash scripts/sync-skills.sh' and commit updated mirrors." >&2
  fi
  exit "$status"
fi

if [[ "$MODE" == "sync" ]]; then
  for mirror in "${REPO_MIRRORS[@]}"; do
    rm -rf "$mirror"
    mkdir -p "$(dirname "$mirror")"
    cp -R "$CANONICAL" "$mirror"
    echo "Synced repo mirror: $mirror"
  done
  exit 0
fi

if [[ "$MODE" == "global" ]]; then
  GLOBAL_TARGETS=(
    "$HOME/.gemini/config/skills"
    "$HOME/.agents/skills"
    "$HOME/.claude/skills"
  )
  if [[ -f "$HOME/.gemini/config/skills.json" ]]; then
    echo "WARNING: $HOME/.gemini/config/skills.json exists; Antigravity ignores global skills.json." >&2
  fi
  for target_root in "${GLOBAL_TARGETS[@]}"; do
    mkdir -p "$target_root"
    for skill_dir in "$CANONICAL"/*; do
      [[ -d "$skill_dir" ]] || continue
      skill_name="$(basename "$skill_dir")"
      rm -rf "$target_root/$skill_name"
      cp -R "$skill_dir" "$target_root/$skill_name"
    done
    echo "Updated global skills in: $target_root"
  done
fi
