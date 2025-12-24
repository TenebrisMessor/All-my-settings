#Requires -Version 5.1
$ErrorActionPreference = "Stop"

Write-Host "[COMMON] Windows common setup: conda + sithlab + nvim + shortcuts" -ForegroundColor Cyan

function Test-Cmd($name) {
  return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

# global/ -> repo root
$RootDir   = Split-Path -Parent $PSScriptRoot
$GlobalDir = Join-Path $RootDir "global"

$EnvYml  = Join-Path $GlobalDir "envs\env-sithlab.yml"
$PipReq  = Join-Path $GlobalDir "pip-sithlab.txt"
$NvimSrc = Join-Path $GlobalDir "nvim"
$NvimDst = Join-Path $env:LOCALAPPDATA "nvim"

# ---- Conda ----
if (-not (Test-Cmd "conda")) {
  throw "[COMMON] conda not found in PATH. Install Miniconda/Anaconda and re-run."
}
if (-not (Test-Path $EnvYml)) {
  throw "[COMMON] Missing env file: $EnvYml"
}

Write-Host "[COMMON] Conda detected: $(conda --version)" -ForegroundColor Green

# Remove prefix: for portability
$tmpYml = Join-Path $env:TEMP ("sithlab-env-{0}.yml" -f ([guid]::NewGuid().ToString("N")))
(Get-Content $EnvYml) | Where-Object { $_ -notmatch '^\s*prefix\s*:\s*' } | Set-Content -Encoding UTF8 $tmpYml

$envList = conda env list
$hasSith = $envList | Select-String -Pattern '^\s*sithlab(\s|$)' -Quiet

if ($hasSith) {
  Write-Host "[COMMON] Updating env sithlab..." -ForegroundColor Cyan
  conda env update -n sithlab -f $tmpYml --prune
} else {
  Write-Host "[COMMON] Creating env sithlab..." -ForegroundColor Cyan
  conda env create -n sithlab -f $tmpYml
}
Remove-Item $tmpYml -Force -ErrorAction SilentlyContinue

# ---- pip deps inside sithlab ----
if (Test-Path $PipReq) {
  Write-Host "[COMMON] Installing pip deps in sithlab..." -ForegroundColor Cyan
  conda run -n sithlab python -m pip install --upgrade pip
  conda run -n sithlab python -m pip install -r $PipReq
} else {
  Write-Host "[COMMON] pip-sithlab.txt not found (skip pip)" -ForegroundColor Yellow
}

# ---- Deploy NVIM config ----
if (-not (Test-Path $NvimSrc)) {
  throw "[COMMON] Missing nvim folder in repo: $NvimSrc"
}

Write-Host "[COMMON] Deploying NVIM config -> $NvimDst" -ForegroundColor Cyan
if (Test-Path $NvimDst) {
  $ts  = Get-Date -Format "yyyyMMdd-HHmmss"
  $bak = "${NvimDst}.backup-$ts"
  Write-Host "[COMMON] Backup: $NvimDst -> $bak" -ForegroundColor Yellow
  Move-Item $NvimDst $bak
}

New-Item -ItemType Directory -Force -Path $NvimDst | Out-Null
Copy-Item -Recurse -Force (Join-Path $NvimSrc "*") $NvimDst

# ---- Shortcut: sithlab in PowerShell ----
$Start = "# AHR_SHORTCUTS_START"
$End   = "# AHR_SHORTCUTS_END"
$Block = @"
$Start
function sithlab { conda activate sithlab }
$End
"@

$ProfilePath = $PROFILE.CurrentUserAllHosts
$ProfileDir  = Split-Path -Parent $ProfilePath
New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
if (-not (Test-Path $ProfilePath)) { New-Item -ItemType File -Force -Path $ProfilePath | Out-Null }

$content = Get-Content $ProfilePath -Raw

if ($content -match [regex]::Escape($Start) -and $content -match [regex]::Escape($End)) {
  $pattern = "(?s)" + [regex]::Escape($Start) + ".*?" + [regex]::Escape($End)
  $newContent = [regex]::Replace($content, $pattern, $Block.TrimEnd(), 1)
} else {
  $newContent = ($content.TrimEnd() + "`r`n`r`n" + $Block.TrimEnd() + "`r`n")
}

Set-Content -Path $ProfilePath -Value $newContent -Encoding UTF8

Write-Host "[COMMON] Done. Open a NEW PowerShell and run: sithlab" -ForegroundColor Green
