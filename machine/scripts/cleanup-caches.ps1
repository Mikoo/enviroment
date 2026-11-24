<#
.SYNOPSIS
  Safe cache cleanup for Windows developer workstations.
.DESCRIPTION
  Runs in dry-run mode by default. Pass -Execute to actually delete transient caches.
  Never deletes ~/.gemini/antigravity, ~/.gemini/config, source repos, or project notes.
#>
[CmdletBinding()]
param(
  [switch]$Execute,
  [switch]$IncludeDockerPrune
)

$ErrorActionPreference = 'Stop'

# Explicitly protected paths that must NEVER be cleaned by this script
$ProtectedPaths = @(
  (Join-Path $env:USERPROFILE ".gemini\antigravity"),
  (Join-Path $env:USERPROFILE ".gemini\config"),
  (Join-Path $env:USERPROFILE ".agents"),
  (Join-Path $env:USERPROFILE ".claude")
)

$Targets = @(
  @{ Name = "Gemini CLI Temp"; Path = (Join-Path $env:USERPROFILE ".gemini\tmp") },
  @{ Name = "Antigravity Migration Backup"; Path = (Join-Path $env:USERPROFILE ".gemini\antigravity-backup") },
  @{ Name = "pip Cache"; Path = (Join-Path $env:LOCALAPPDATA "pip\Cache") },
  @{ Name = "uv Cache"; Path = (Join-Path $env:LOCALAPPDATA "uv\cache") },
  @{ Name = "npm Cache"; Path = (Join-Path $env:LOCALAPPDATA "npm-cache") }
)

function Assert-NotProtected {
  param([string]$CandidatePath)
  $resolved = [System.IO.Path]::GetFullPath($CandidatePath)
  foreach ($prot in $ProtectedPaths) {
    $protFull = [System.IO.Path]::GetFullPath($prot)
    if ($resolved -eq $protFull -or $resolved.StartsWith($protFull + [System.IO.Path]::DirectorySeparatorChar)) {
      throw "SAFETY ABORT: Refusing to touch protected path $resolved"
    }
  }
}

if (-not $Execute) {
  Write-Host "[DRY-RUN] No files will be deleted. Re-run with -Execute to apply." -ForegroundColor Yellow
}

foreach ($t in $Targets) {
  if (-not (Test-Path $t.Path)) {
    continue
  }
  Assert-NotProtected -CandidatePath $t.Path
  $bytes = (Get-ChildItem -Path $t.Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
  $mb = [math]::Round(($bytes / 1MB), 1)
  if ($Execute) {
    Write-Host "[CLEAN] Removing $($t.Name): $($t.Path) ($mb MB)" -ForegroundColor Cyan
    Remove-Item -Path $t.Path -Recurse -Force -ErrorAction SilentlyContinue
  } else {
    Write-Host "[DRY-RUN] Would remove $($t.Name): $($t.Path) ($mb MB)"
  }
}

if ($IncludeDockerPrune) {
  if (Get-Command docker -ErrorAction SilentlyContinue) {
    if ($Execute) {
      Write-Host "[CLEAN] Pruning unused Docker build cache and dangling images..." -ForegroundColor Cyan
      docker system prune -f
    } else {
      Write-Host "[DRY-RUN] Would run: docker system prune -f"
    }
  }
}
