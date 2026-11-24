#!/usr/bin/env bash
# Structural safety checks on machine/scripts/* (adapted from InsForge's scripts/check-setup-sh.sh).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEANUP="$SCRIPT_DIR/cleanup-caches.ps1"
AUDIT="$SCRIPT_DIR/audit-host.ps1"
fails=0

fail() {
  echo "FAIL: $1" >&2
  fails=$((fails + 1))
}

# 1. cleanup-caches.ps1 must stay dry-run by default via -Execute switch
if ! grep -q '\[switch\]\$Execute' "$CLEANUP"; then
  fail "cleanup-caches.ps1 must require [switch]\$Execute for destructive actions"
fi
if ! grep -q 'if (-not \$Execute)' "$CLEANUP"; then
  fail "cleanup-caches.ps1 must check (-not \$Execute) before deleting"
fi

# 2. Protected paths guard must exist and run before any Remove-Item
if ! grep -q 'Assert-NotProtected' "$CLEANUP"; then
  fail "cleanup-caches.ps1 missing Assert-NotProtected guard"
fi
guard_line=$(grep -n 'Assert-NotProtected -CandidatePath' "$CLEANUP" | head -n1 | cut -d: -f1)
rm_line=$(grep -n 'Remove-Item' "$CLEANUP" | head -n1 | cut -d: -f1)
if [[ -z "$guard_line" || -z "$rm_line" || "$guard_line" -gt "$rm_line" ]]; then
  fail "Assert-NotProtected must run before Remove-Item in cleanup-caches.ps1"
fi

# 3. Ensure critical Antigravity/Agent paths stay protected
for prot in '.gemini\\antigravity' '.gemini\\config' '.agents' '.claude'; do
  if ! grep -q "$prot" "$CLEANUP"; then
    fail "cleanup-caches.ps1 must explicitly protect $prot"
  fi
done

# 4. audit-host.ps1 must remain strictly read-only (no Remove-Item / Set-Item / Clear-*)
if grep -qiE '\b(Remove-Item|Clear-RecycleBin|Set-Content|Out-File)\b' "$AUDIT"; then
  fail "audit-host.ps1 must remain strictly read-only"
fi

if [[ "$fails" -eq 0 ]]; then
  echo "OK: machine/scripts structural safety checks passed"
else
  echo "$fails check(s) failed" >&2
  exit 1
fi
