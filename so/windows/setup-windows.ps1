#Requires -Version 5.1
$ErrorActionPreference = "Stop"

Write-Host "[WIN] Restoring Windows base packages..." -ForegroundColor Cyan

function Test-Cmd($name) {
  return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

# Repo root (so/windows/ -> repo root)
$RootDir  = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$WinDir   = Join-Path $RootDir "so\windows"

# Chocolatey
if (-not (Test-Cmd "choco.exe")) {
  Write-Host "[WIN] Chocolatey not found. Installing..." -ForegroundColor Yellow
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Packages list (prefer: so/windows/choco-packages.txt)
$PkgFile = Join-Path $WinDir "choco-packages.txt"
if (-not (Test-Path $PkgFile)) {
  # fallback old structure
  $PkgFile = Join-Path $RootDir "windows\choco-packages.txt"
}

if (Test-Path $PkgFile) {
  Write-Host "[WIN] Installing choco packages from: $PkgFile" -ForegroundColor Cyan
  Get-Content $PkgFile |
    Where-Object { $_ -and $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#") } |
    ForEach-Object { choco install $_ -y }
} else {
  Write-Host "[WIN] choco-packages.txt not found (skip packages)" -ForegroundColor Yellow
}

Write-Host "[WIN] Windows base ready." -ForegroundColor Green
