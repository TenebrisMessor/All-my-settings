#Requires -Version 5.1
[CmdletBinding()]
param(
  [switch]$SkipPackages,
  [switch]$SkipCommon
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Log {
  param(
    [Parameter(Mandatory)][string]$Msg,
    [ConsoleColor]$Color = [ConsoleColor]::Gray
  )
  Write-Host $Msg -ForegroundColor $Color
}

function Assert-Admin {
  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

  if (-not $isAdmin) {
    throw "[WIN] Ejecuta PowerShell como ADMIN (Run as Administrator) para instalar con Chocolatey."
  }
}

function Refresh-Path {
  $machine = [Environment]::GetEnvironmentVariable("Path","Machine")
  $user    = [Environment]::GetEnvironmentVariable("Path","User")
  $env:Path = ($machine + ";" + $user)
}

function Ensure-Choco {
  $chocoExe = Join-Path $env:ProgramData "chocolatey\bin\choco.exe"
  if (Test-Path $chocoExe) {
    Refresh-Path
    Log "[WIN] Chocolatey OK: $chocoExe" Cyan
    return $chocoExe
  }

  Log "[WIN] Chocolatey no encontrado. Instalando..." Yellow

  # Instalación oficial (TLS 1.2)
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Set-ExecutionPolicy Bypass -Scope Process -Force

  # Si hay restos de una instalación previa, Chocolatey bootstrap suele quejarse.
  # Preferimos NO borrar automáticamente (riesgo), solo avisar.
  $chocoFolder = Join-Path $env:ProgramData "chocolatey"
  if (Test-Path $chocoFolder) {
    Log "[WIN] AVISO: Ya existe '$chocoFolder'. Si choco está corrupto, borra esa carpeta y reintenta." Yellow
  }

  iex ((New-Object System.Net.WebClient).DownloadString("https://community.chocolatey.org/install.ps1"))

  Refresh-Path

  if (!(Test-Path $chocoExe)) {
    throw "[WIN] Instalación de Chocolatey falló. No existe: $chocoExe"
  }

  Log "[WIN] Chocolatey instalado: $chocoExe" Cyan
  return $chocoExe
}

function Install-ChocoPackagesFromFile {
  param(
    [Parameter(Mandatory)][string]$ChocoExe,
    [Parameter(Mandatory)][string]$PackagesFile
  )

  if (!(Test-Path $PackagesFile)) {
    Log "[WIN] choco-packages.txt no existe: $PackagesFile (skip packages)" Yellow
    return
  }

  Log "[WIN] Instalando paquetes desde: $PackagesFile" Cyan

  Get-Content $PackagesFile | ForEach-Object {
    $pkg = $_.Trim()
    if ($pkg -and -not $pkg.StartsWith("#")) {
      Log "[WIN] -> $pkg" DarkCyan
      & $ChocoExe install $pkg -y --no-progress
    }
  }

  Log "[WIN] Paquetes listos." Green
}

# ---------------- MAIN ----------------
Log "[WIN] Restoring Windows base packages..." Cyan
Assert-Admin

# Repo root: este script vive en so/windows/
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$PackagesFile = Join-Path $PSScriptRoot "choco-packages.txt"
$CommonScript = Join-Path $RepoRoot "global\setup-common.ps1"

$chocoExe = Ensure-Choco

if (-not $SkipPackages) {
  Install-ChocoPackagesFromFile -ChocoExe $chocoExe -PackagesFile $PackagesFile
} else {
  Log "[WIN] SkipPackages activado (no instalo choco packages)." Yellow
}

Log "[WIN] Windows base ready." Green

if (-not $SkipCommon) {
  if (Test-Path $CommonScript) {
    Log "[WIN] Corriendo common: $CommonScript" Cyan
    # Ejecuta el setup common de Windows (si existe)
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $CommonScript
  } else {
    Log "[WIN] No existe global/setup-common.ps1 (skip common)." Yellow
  }
} else {
  Log "[WIN] SkipCommon activado (no corro common)." Yellow
}

Log "[WIN] ✅ Windows listo." Green
Log "[WIN] Nota: si acabas de instalar choco, cierra y abre PowerShell para que PATH se refresque en nuevas sesiones." DarkGray
