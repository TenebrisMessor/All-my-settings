#!/usr/bin/env bash
set -euo pipefail

echo "🧠 Detectando sistema operativo..."

# Raíz del repo (aunque corras el script desde otro lado)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OS="$(uname -s)"

case "$OS" in
  Linux*)
    echo "🐧 Linux detectado"
    bash "$ROOT_DIR/so/linux/setup-linux.sh"
    bash "$ROOT_DIR/global/setup-common.sh"
    ;;

  Darwin*)
    echo "🍎 macOS detectado"
    bash "$ROOT_DIR/so/macos/setup-macos.sh"
    bash "$ROOT_DIR/global/setup-common.sh"
    ;;

  MINGW*|MSYS*|CYGWIN*)
    echo "🪟 Windows detectado"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "cd '$ROOT_DIR'; & '$ROOT_DIR/so/windows/setup-windows.ps1'"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "cd '$ROOT_DIR'; & '$ROOT_DIR/global/setup-common.ps1'"    
    ;;

  *)
    echo "❌ SO no reconocido: $OS"
    exit 1
    ;;
esac
echo "✅ Setup finalizado."
