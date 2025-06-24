Write-Host "🪟 Restaurando configuración Windows..."

# Instalar Chocolatey si no está
if (!(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️ Chocolatey no encontrado. Instalando..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Restaurar paquetes
if (Test-Path "windows\choco-packages.txt") {
    Get-Content "windows\choco-packages.txt" | ForEach-Object {
        choco install $_ -y
    }
}

Write-Host "✅ Windows listo."
