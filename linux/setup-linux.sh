#!/bin/bash

echo "🔧 Restaurando configuración Linux..."

# Restaurar paquetes APT
if [ -f linux/apt-packages.txt ]; then
  echo "📦 Instalando paquetes APT..."
  sudo apt update
  sudo apt install -y $(cut -f1 linux/apt-packages.txt)
fi

# Restaurar paquetes pip
if [ -f common/pip-packages.txt ]; then
  echo "🐍 Instalando paquetes Python con pip..."
  pip install -r common/pip-packages.txt
fi

# Restaurar entornos Conda
if [ -f common/envs/env-base.yml ]; then
  echo "🧪 Restaurando entorno conda base..."
  conda env create -f common/envs/env-base.yml
fi

if [ -f common/envs/env-sithlab.yml ]; then
  echo "🧪 Restaurando entorno conda sithlab..."
  conda env create -f common/envs/env-sithlab.yml
fi

# Restaurar dotfiles
echo "📁 Copiando dotfiles a tu home..."
cp linux/dotfiles/.bashrc ~/
cp linux/dotfiles/.profile ~/
cp common/gitconfig ~/.gitconfig

echo "✅ Linux listo."
