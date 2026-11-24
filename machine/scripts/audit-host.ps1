<#
.SYNOPSIS
  Read-only diagnostic of Windows workstation health, isolation tools, caches, and Cross-AI skill paths.
.DESCRIPTION
  Does not modify files, registry, containers, or WSL state.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

Write-Host "=== 1. Disk Space ===" -ForegroundColor Cyan
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
  $usedGB = [math]::Round($_.Used / 1GB, 2)
  $freeGB = [math]::Round($_.Free / 1GB, 2)
  [PSCustomObject]@{
    Drive = $_.Name
    Root  = $_.Root
    UsedGB = $usedGB
    FreeGB = $freeGB
  }
} | Format-Table -AutoSize

Write-Host "=== 2. WSL2 & .wslconfig ===" -ForegroundColor Cyan
$wslConfig = Join-Path $env:USERPROFILE ".wslconfig"
if (Test-Path $wslConfig) {
  Write-Host "[OK] Found $wslConfig" -ForegroundColor Green
} else {
  Write-Host "[WARN] Missing $wslConfig (WSL2 may consume excessive RAM). See machine/configs/.wslconfig.example" -ForegroundColor Yellow
}
if (Get-Command wsl -ErrorAction SilentlyContinue) {
  wsl -l -v
} else {
  Write-Host "wsl command not installed."
}

Write-Host "`n=== 3. Docker Status ===" -ForegroundColor Cyan
if (Get-Command docker -ErrorAction SilentlyContinue) {
  docker info --format "ServerRunning=true | ContainersRunning={{.ContainersRunning}}" 2>$null
  if ($LASTEXITCODE -eq 0) {
    docker system df
  } else {
    Write-Host "Docker CLI installed, daemon currently stopped (good for Zero-Idle)."
  }
} else {
  Write-Host "docker command not found."
}

Write-Host "`n=== 4. Cross-AI Global Skill Locations ===" -ForegroundColor Cyan
$badGlobalJson = Join-Path $env:USERPROFILE ".gemini\config\skills.json"
if (Test-Path $badGlobalJson) {
  Write-Host "[WARN] Found $badGlobalJson — Antigravity ignores global skills.json! Use sync-skills.ps1 -Global instead." -ForegroundColor Red
}

$skillDirs = @(
  @{ Name = "Antigravity Global"; Path = (Join-Path $env:USERPROFILE ".gemini\config\skills") },
  @{ Name = "Codex / Open Standard"; Path = (Join-Path $env:USERPROFILE ".agents\skills") },
  @{ Name = "Claude Code Global"; Path = (Join-Path $env:USERPROFILE ".claude\skills") }
)

foreach ($entry in $skillDirs) {
  if (Test-Path $entry.Path) {
    $count = (Get-ChildItem -Path $entry.Path -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "[OK] $($entry.Name): $($entry.Path) ($count skills)" -ForegroundColor Green
  } else {
    Write-Host "[INFO] $($entry.Name): not initialized ($($entry.Path))" -ForegroundColor Yellow
  }
}

Write-Host "`n=== 5. Cache Footprint (Read-Only) ===" -ForegroundColor Cyan
$cachePaths = @(
  (Join-Path $env:LOCALAPPDATA "npm-cache"),
  (Join-Path $env:LOCALAPPDATA "pip\Cache"),
  (Join-Path $env:LOCALAPPDATA "uv\cache"),
  (Join-Path $env:USERPROFILE ".gemini\tmp"),
  (Join-Path $env:LOCALAPPDATA "Temp")
)

foreach ($p in $cachePaths) {
  if (Test-Path $p) {
    $bytes = (Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $mb = [math]::Round(($bytes / 1MB), 1)
    Write-Host ("{0,10} MB  {1}" -f $mb, $p)
  }
}
