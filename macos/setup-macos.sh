#!/bin/bash

echo "🍎 Restaurando configuración MacOS..."

# Instalar Homebrew si no está
if ! command -v brew &> /dev/null; then
  echo "⚠️ Homebrew no encontrado. Instalando..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Restaurar Brewfile
if [ -f macos/Brewfile ]; then
  echo "📦 Instalando paquetes con Brew..."
  brew bundle --file=macos/Brewfile
fi

# Restaurar pip y conda
if [ -f common/pip-packages.txt ]; then
  pip install -r common/pip-packages.txt
fi

if [ -f common/envs/env-base.yml ]; then
  conda env create -f common/envs/env-base.yml
fi

echo "✅ MacOS listo."
