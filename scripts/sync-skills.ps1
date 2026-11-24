<#
.SYNOPSIS
  Mirrors canonical .agents/skills to .claude/skills and .codex/skills, and optionally to global Windows agent folders.
.EXAMPLE
  .\scripts\sync-skills.ps1
  .\scripts\sync-skills.ps1 -Global
  .\scripts\sync-skills.ps1 -Check
#>
[CmdletBinding()]
param(
  [switch]$Check,
  [switch]$Global
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Canonical = Join-Path $RepoRoot ".agents\skills"

if (-not (Test-Path $Canonical)) {
  throw "Missing canonical skills folder: $Canonical"
}

$RepoMirrors = @(
  (Join-Path $RepoRoot ".claude\skills"),
  (Join-Path $RepoRoot ".codex\skills")
)

function Get-TreeHashMap {
  param([string]$RootDir)
  $map = @{}
  if (-not (Test-Path $RootDir)) { return $map }
  $base = (Resolve-Path $RootDir).Path
  Get-ChildItem -Path $base -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($base.Length).TrimStart('\', '/').Replace('\', '/')
    $hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
    $map[$rel] = $hash
  }
  return $map
}

if ($Check) {
  $srcMap = Get-TreeHashMap -RootDir $Canonical
  $drift = $false
  foreach ($mirror in $RepoMirrors) {
    $dstMap = Get-TreeHashMap -RootDir $mirror
    $allKeys = ($srcMap.Keys + $dstMap.Keys) | Sort-Object -Unique
    foreach ($k in $allKeys) {
      if ($srcMap[$k] -ne $dstMap[$k]) {
        Write-Host "DRIFT: $mirror -> $k" -ForegroundColor Red
        $drift = $true
      }
    }
  }
  if ($drift) {
    throw "Skill mirrors drifted. Run .\scripts\sync-skills.ps1"
  }
  Write-Host "OK: .claude\skills and .codex\skills match .agents\skills" -ForegroundColor Green
  exit 0
}

foreach ($mirror in $RepoMirrors) {
  if (Test-Path $mirror) {
    Remove-Item -Path $mirror -Recurse -Force
  }
  New-Item -ItemType Directory -Path (Split-Path -Parent $mirror) -Force | Out-Null
  Copy-Item -Path $Canonical -Destination $mirror -Recurse -Force
  Write-Host "Synced repo mirror: $mirror" -ForegroundColor Cyan
}

if ($Global) {
  $badJson = Join-Path $env:USERPROFILE ".gemini\config\skills.json"
  if (Test-Path $badJson) {
    Write-Host "WARNING: Found $badJson -- Antigravity ignores global skills.json. Consider removing it." -ForegroundColor Yellow
  }

  $GlobalTargets = @(
    (Join-Path $env:USERPROFILE ".gemini\config\skills"),
    (Join-Path $env:USERPROFILE ".agents\skills"),
    (Join-Path $env:USERPROFILE ".claude\skills")
  )

  $skills = Get-ChildItem -Path $Canonical -Directory
  foreach ($targetRoot in $GlobalTargets) {
    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
    foreach ($skill in $skills) {
      $dest = Join-Path $targetRoot $skill.Name
      if (Test-Path $dest) {
        Remove-Item -Path $dest -Recurse -Force
      }
      Copy-Item -Path $skill.FullName -Destination $dest -Recurse -Force
    }
    Write-Host "Updated $($skills.Count) global skills in: $targetRoot" -ForegroundColor Green
  }
}
