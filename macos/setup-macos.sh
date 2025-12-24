#!/bin/bash
set -euo pipefail

echo "🍎 Restaurando configuración MacOS..."

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
  echo "⚠️ Homebrew no encontrado. Instalando..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Asegurar brew en PATH (Apple Silicon vs Intel)
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/usr/local/bin/brew shellenv)"
fi

# --- Brewfile ---
if [ -f macos/Brewfile ]; then
  echo "📦 Instalando paquetes con Brew..."
  brew bundle --file=macos/Brewfile
fi

# --- Neovim + Neofetch/Fastfetch ---
echo "🛠️ Verificando Neovim y Neofetch..."

if ! command -v nvim &>/dev/null; then
  echo "🧠 Neovim no encontrado. Instalando..."
  brew install neovim
else
  echo "✅ Neovim ya está instalado."
fi

# Neofetch puede no estar disponible en brew en algunas instalaciones -> fallback a fastfetch
if ! command -v neofetch &>/dev/null && ! command -v fastfetch &>/dev/null; then
  echo "🛰️ (Neo/Fast)fetch no encontrado. Intentando instalar..."
  if brew info neofetch &>/dev/null; then
    brew install neofetch
  else
    echo "⚠️ Neofetch no disponible en brew. Instalando fastfetch (reemplazo moderno)..."
    brew install fastfetch
  fi
else
  echo "✅ (Neo/Fast)fetch ya está instalado."
fi

# --- Python / pip (robusto) ---
if command -v python3 &>/dev/null; then
  echo "🐍 Python encontrado: $(python3 --version)"
  if [ -f common/pip-packages.txt ]; then
    echo "📌 Instalando pip packages..."
    python3 -m pip install --upgrade pip
    python3 -m pip install -r common/pip-packages.txt
  fi
else
  echo "❌ python3 no encontrado. Instala con: brew install python"
  exit 1
fi

# --- Conda env ---
# Requiere conda ya instalado (por Brewfile o por tu instalación de Anaconda/Miniconda)
if command -v conda &>/dev/null; then
  echo "🧪 Conda encontrado: $(conda --version)"

  # Habilitar conda en este script (sin depender de conda init del usuario)
  CONDA_BASE="$(conda info --base)"
  # shellcheck disable=SC1091
  source "$CONDA_BASE/etc/profile.d/conda.sh"

  if [ -f common/envs/env-base.yml ]; then
    echo "🧱 Creando/actualizando env desde YAML -> env: dev"
    if conda env list | awk '{print $1}' | grep -qx "dev"; then
      conda env update -n dev -f common/envs/env-base.yml
    else
      # Override del nombre (evita el error de 'base' reservado aunque tu YAML diga name: base)
      conda env create -n dev -f common/envs/env-base.yml
    fi
  fi
else
  echo "⚠️ conda no encontrado. Si lo quieres, instala Miniconda/Anaconda o mambaforge (o inclúyelo en tu Brewfile)."
fi

# --- Auto-run de neofetch/fastfetch en Zsh ---
echo "🧩 Configurando auto-run de (neo/fast)fetch en Zsh..."

ZSHRC="$HOME/.zshrc"
MARKER_START="# >>> AHR auto-fetch (managed) >>>"
MARKER_END="# <<< AHR auto-fetch (managed) <<<"

read -r -d '' AUTOFETCH_BLOCK <<'EOF'
# >>> AHR auto-fetch (managed) >>>
# Mostrar info del sistema al abrir terminal (solo interactivo)
case $- in
  *i*)
    # Si quieres desactivarlo en una sesión:
    # AHR_NO_FETCH=1 zsh
    if [ -z "${AHR_NO_FETCH:-}" ]; then
      if command -v neofetch >/dev/null 2>&1; then
        neofetch
      elif command -v fastfetch >/dev/null 2>&1; then
        fastfetch
      fi
    fi
  ;;
esac
# <<< AHR auto-fetch (managed) <<<
EOF

touch "$ZSHRC"

if grep -qF "$MARKER_START" "$ZSHRC"; then
  sed -i '' "/$MARKER_START/,/$MARKER_END/c\\
$AUTOFETCH_BLOCK
" "$ZSHRC"
else
  printf "\n%s\n" "$AUTOFETCH_BLOCK" >> "$ZSHRC"
fi

echo "✅ MacOS listo."
