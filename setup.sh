#!/bin/bash

echo "🧠 Detectando sistema operativo..."
OS="$(uname)"

case "$OS" in
  "Linux")
    echo "🐧 Linux detectado"
    bash linux/setup-linux.sh
    ;;

  "Darwin")
    echo "🍎 MacOS detectado"
    bash macos/setup-macos.sh
    ;;

  MINGW* | MSYS* | CYGWIN*)
    echo "🪟 Windows detectado"
    powershell.exe -ExecutionPolicy Bypass -File windows/setup-windows.ps1
    ;;

  *)
    echo "❌ SO no reconocido"
    ;;
  esac
