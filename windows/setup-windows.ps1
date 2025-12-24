# windows/setup-windows.ps1
$ErrorActionPreference = "Stop"

Write-Host "🪟 Restaurando configuración Windows..." -ForegroundColor Cyan

# ---------- Paths ----------
$RootDir   = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$CommonDir = Join-Path $RootDir "common"
$WinDir    = Join-Path $RootDir "windows"

function Test-Cmd($name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Get-LinesClean($path) {
  Get-Content $path | ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and (-not $_.StartsWith("#")) }
}

# ---------- Chocolatey ----------
if (-not (Test-Cmd "choco.exe")) {
  Write-Host "⚠️  Chocolatey no encontrado. Instalando..." -ForegroundColor Yellow
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# ---------- Choco packages ----------
$ChocoList = Join-Path $WinDir "choco-packages.txt"
if (Test-Path $ChocoList) {
  Write-Host "📦 Instalando paquetes con Chocolatey..." -ForegroundColor Green
  $pkgs = Get-LinesClean $ChocoList
  foreach ($pkg in $pkgs) {
    Write-Host "➡️ choco install $pkg"
    choco install $pkg -y --no-progress | Out-Host
  }
}

# ---------- Tools base: nvim + fetch ----------
# Nota: depende de que tengas en choco-packages.txt: neovim, fastfetch, neofetch (opcional)
if (-not (Test-Cmd "nvim")) {
  Write-Host "⚠️ Neovim no encontrado. Asegúrate de tener 'neovim' en windows/choco-packages.txt" -ForegroundColor Yellow
} else {
  Write-Host "✅ Neovim detectado."
}

if (-not (Test-Cmd "neofetch") -and -not (Test-Cmd "fastfetch")) {
  Write-Host "⚠️ neofetch/fastfetch no encontrado. Recomendado: agrega 'fastfetch' a windows/choco-packages.txt" -ForegroundColor Yellow
} else {
  Write-Host "✅ (Neo/Fast)fetch detectado."
}

# ---------- Deploy NVIM config ----------
Write-Host "🧠 Desplegando configuración de Neovim..." -ForegroundColor Green
$NvimSource = Join-Path $CommonDir "nvim"
$NvimTarget = Join-Path $env:LOCALAPPDATA "nvim"

if (-not (Test-Path $NvimSource)) {
  Write-Host "⚠️ No existe: $NvimSource (skip)" -ForegroundColor Yellow
} else {
  if (Test-Path $NvimTarget) {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = "${NvimTarget}.backup-$ts"
    Write-Host "📦 Backup: $NvimTarget -> $backup"
    Move-Item -Force $NvimTarget $backup
  }

  # Symlink si se puede (Developer Mode o admin). Si falla, copia.
  try {
    New-Item -ItemType SymbolicLink -Path $NvimTarget -Target $NvimSource | Out-Null
    Write-Host "🔗 Symlink creado: $NvimTarget -> $NvimSource"
  } catch {
    Write-Host "⚠️ No se pudo crear symlink. Copiando archivos..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $NvimTarget | Out-Null
    robocopy $NvimSource $NvimTarget /E /NFL /NDL /NJH /NJS | Out-Null
  }
}

# ---------- Git config ----------
Write-Host "📁 Restaurando gitconfig..." -ForegroundColor Green
$GitCfgSrc = Join-Path $CommonDir "gitconfig"
$GitCfgDst = Join-Path $env:USERPROFILE ".gitconfig"
if (Test-Path $GitCfgSrc) {
  if (Test-Path $GitCfgDst) {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $GitCfgDst "${GitCfgDst}.backup-$ts" -Force
  }
  Copy-Item $GitCfgSrc $GitCfgDst -Force
}

# ---------- Conda envs + pip packages dentro del env ----------
if (Test-Cmd "conda") {
  Write-Host "🧪 Conda encontrado. Configurando entornos..." -ForegroundColor Green

  # Hook para conda en PowerShell
  $hook = (& conda "shell.powershell" "hook") 2>$null
  if ($LASTEXITCODE -eq 0 -and $hook) { Invoke-Expression $hook }

  $EnvDir = Join-Path $CommonDir "envs"

  # Defaults (override opcional con: $env:AHR_ENVS="env-base.yml env-sithlab.yml")
  $envFiles = @("env-base.yml", "env-sithlab.yml")
  if ($env:AHR_ENVS) { $envFiles = $env:AHR_ENVS -split '\s+' }

  foreach ($file in $envFiles) {
    $path = Join-Path $EnvDir $file
    if (-not (Test-Path $path)) {
      Write-Host "⚠️ No existe $path (skip)" -ForegroundColor Yellow
      continue
    }

    $targetEnv = "dev"
    if ($file -match "sithlab") { $targetEnv = "sithlab" }

    $existing = (& conda env list) | ForEach-Object { $_.Trim() } |
      Where-Object { $_ -and -not $_.StartsWith("#") }

    $hasEnv = $false
    foreach ($line in $existing) {
      $name = ($line -split '\s+')[0]
      if ($name -eq $targetEnv) { $hasEnv = $true; break }
    }

    if ($hasEnv) {
      Write-Host "🔁 Actualizando env: $targetEnv"
      & conda env update -n $targetEnv -f $path | Out-Host
    } else {
      Write-Host "🧱 Creando env: $targetEnv"
      # Override evita el error de 'base' reservado aunque el YAML diga name: base
      & conda env create -n $targetEnv -f $path | Out-Host
    }
  }

  # pip packages dentro del env dev
  $pipList = Join-Path $CommonDir "pip-packages.txt"
  if (Test-Path $pipList) {
    Write-Host "📌 Instalando pip packages en conda env: dev" -ForegroundColor Green
    & conda run -n dev python -m pip install --upgrade pip | Out-Host
    & conda run -n dev python -m pip install -r $pipList | Out-Host
  }
} else {
  Write-Host "⚠️ conda no encontrado. Instala Miniconda/Anaconda y re-corre." -ForegroundColor Yellow
}

# ---------- Auto-run fetch in PowerShell ----------
Write-Host "🧩 Configurando auto-run de (neo/fast)fetch en PowerShell..." -ForegroundColor Green

$ProfilePath = $PROFILE.CurrentUserAllHosts
$ProfileDir  = Split-Path $ProfilePath -Parent
if (-not (Test-Path $ProfileDir)) { New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null }
if (-not (Test-Path $ProfilePath)) { New-Item -ItemType File -Force -Path $ProfilePath | Out-Null }

$Start = "# >>> AHR auto-fetch (managed) >>>"
$End   = "# <<< AHR auto-fetch (managed) <<<"

$Block = @"
$Start
# Solo sesiones interactivas. Desactiva por sesión:
# `$env:AHR_NO_FETCH = 1
if (-not `$env:AHR_NO_FETCH) {
  if (Get-Command neofetch -ErrorAction SilentlyContinue) {
    neofetch
  } elseif (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch
  }
}
$End
"@

$content = Get-Content $ProfilePath -Raw
if ($content -match [regex]::Escape($Start)) {
  $pattern = "(?s)$([regex]::Escape($Start)).*?$([regex]::Escape($End))"
  $new = [regex]::Replace($content, $pattern, $Block)
  Set-Content -Path $ProfilePath -Value $new -Encoding UTF8
} else {
  Add-Content -Path $ProfilePath -Value "`n$Block" -Encoding UTF8
}

Write-Host "✅ Windows listo." -ForegroundColor Cyan
