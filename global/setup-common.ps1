#Requires -Version 5.1
$ErrorActionPreference = "Stop"

Write-Host "🌐 Common setup (Windows) — Conda + sithlab + NVIM + shortcuts"

# Repo root: este archivo vive en global/
$RootDir   = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$GlobalDir = Join-Path $RootDir "global"

$EnvYml   = Join-Path $GlobalDir "envs\env-sithlab.yml"
$PipReq   = Join-Path $GlobalDir "pip-sithlab.txt"
$NvimSrc  = Join-Path $GlobalDir "nvim"
$NvimDst  = Join-Path $env:LOCALAPPDATA "nvim"

function Test-Cmd($name) {
  return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

# ---------- Conda ----------
if (-not (Test-Cmd "conda")) {
  throw "❌ conda no encontrado en PATH. Instala Miniconda/Anaconda y vuelve a correr."
}

if (-not (Test-Path $EnvYml)) {
  throw "❌ No existe: $EnvYml"
}

Write-Host "✅ Conda detectado: $(conda --version)"

# Remover prefix: para portabilidad
$tmpYml = Join-Path $env:TEMP ("sithlab-env-{0}.yml" -f ([guid]::NewGuid().ToString("N")))
(Get-Content $EnvYml) | Where-Object { $_ -notmatch '^\s*prefix\s*:\s*' } | Set-Content -Encoding utf8 $tmpYml

# ¿existe env?
$envList = conda env list
$hasSith = $envList | Select-String -Pattern '^\s*sithlab(\s|$)' -Quiet

if ($hasSith) {
  Write-Host "🧪 Actualizando env: sithlab (conda env update)..."
  conda env update -n sithlab -f $tmpYml --prune
} else {
  Write-Host "🧪 Creando env: sithlab (conda env create)..."
  conda env create -n sithlab -f $tmpYml
}

Remove-Item $tmpYml -Force -ErrorAction SilentlyContinue
Write-Host "✅ Env listo: sithlab"

# ---------- pip libs dentro de sithlab ----------
if (Test-Path $PipReq) {
  Write-Host "📌 Instalando pip libs en sithlab..."
  conda run -n sithlab python -m pip install --upgrade pip
  conda run -n sithlab python -m pip install -r $PipReq
} else {
  Write-Host "⚠️ No existe: $PipReq (skip pip libs)"
}

# ---------- Deploy NVIM ----------
if (-not (Test-Path $NvimSrc)) {
  throw "❌ No existe carpeta NVIM en repo: $NvimSrc"
}

Write-Host "🧠 Deploy NVIM: $NvimSrc -> $NvimDst"

# Backup si ya existe
if (Test-Path $NvimDst) {
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $bak = "${NvimDst}.backup-$ts"
  Write-Host "📦 Backup: $NvimDst -> $bak"
  Move-Item $NvimDst $bak
}

New-Item -ItemType Directory -Force -Path $NvimDst | Out-Null
Copy-Item -Recurse -Force (Join-Path $NvimSrc "*") $NvimDst

# ---------- packer.nvim + PackerSync (opcional) ----------
if (Test-Cmd "nvim" -and (Test-Cmd "git")) {
  $nvimData = Join-Path $env:LOCALAPPDATA "nvim-data"
  $packerDir = Join-Path $nvimData "site\pack\packer\start\packer.nvim"

  if (-not (Test-Path $packerDir)) {
    Write-Host "📦 Bootstrapping packer.nvim..."
    git clone --depth 1 https://github.com/wbthomason/packer.nvim $packerDir
  } else {
    Write-Host "✅ packer.nvim ya existe."
  }

  Write-Host "🔧 Corriendo PackerSync (headless)..."
  try {
    nvim --headless +PackerSync +qa
  } catch {
    Write-Host "⚠️ PackerSync falló. Revisa nvim/config/plugins."
  }
} else {
  Write-Host "⚠️ nvim o git no detectados (skip packer)."
}

# ---------- Shortcut: comando "sithlab" en PowerShell ----------
$start = "# >>> AHR shortcuts (managed) >>>"
$end   = "# <<< AHR shortcuts (managed) <<<"

$block = @"
$start
function sithlab { conda activate sithlab }
$end
"@

$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path -Parent $profilePath
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
if (-not (Test-Path $profilePath)) { New-Item -ItemType File -Force -Path $profilePath | Out-Null }

$content = Get-Content $profilePath -Raw

if ($content -match [regex]::Escape($start) -and $content -match [regex]::Escape($end)) {
  $pattern = [regex]::Escape($start) + ".*?" + [regex]::Escape($end)
  $newContent = [regex]::Replace($content, $pattern, $block, "Singleline")
} else {
  $newContent = ($content.TrimEnd() + "`r`n`r`n" + $block + "`r`n")
}

Set-Content -Path $profilePath -Value $newContent -Encoding UTF8

Write-Host "✅ Common Windows listo."
Write-Host "👉 Abre una NUEVA PowerShell y escribe: sithlab"
