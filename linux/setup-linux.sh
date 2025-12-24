#!/bin/bash
set -euo pipefail

echo "🐧 Restaurando configuración Linux..."

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMON_DIR="$ROOT_DIR/common"
LINUX_DIR="$ROOT_DIR/linux"

# ---------- APT packages ----------
if [ -f "$LINUX_DIR/apt-packages.txt" ]; then
  echo "📦 Instalando paquetes APT..."
  sudo apt update

  # Soporta lista simple (un paquete por línea) y también TSV (paquete en primera columna)
  # Ignora líneas vacías y comentarios
  PKGS="$(awk 'NF && $1 !~ /^#/' "$LINUX_DIR/apt-packages.txt" | cut -f1 | tr '\n' ' ')"
  if [ -n "${PKGS// }" ]; then
    sudo apt install -y $PKGS
  fi
fi

# ---------- Tools base: nvim + fetch ----------
echo "🛠️ Verificando Neovim..."
if ! command -v nvim &>/dev/null; then
  # En Ubuntu/Debian suele estar, pero puede ser viejo. Lo instalamos igual.
  sudo apt install -y neovim || true
fi

echo "🛰️ Verificando neofetch/fastfetch..."
if ! command -v neofetch &>/dev/null && ! command -v fastfetch &>/dev/null; then
  # neofetch suele existir; si no, usamos fastfetch
  if apt-cache show neofetch &>/dev/null; then
    sudo apt install -y neofetch
  else
    sudo apt install -y fastfetch
  fi
fi

# ---------- Deploy de config NVIM ----------
echo "🧠 Desplegando configuración de Neovim..."
mkdir -p "$HOME/.config"

if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  TS="$(date +%Y%m%d-%H%M%S)"
  echo "📦 Backup: ~/.config/nvim -> ~/.config/nvim.backup-$TS"
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup-$TS"
fi

ln -sfn "$COMMON_DIR/nvim" "$HOME/.config/nvim"

# ---------- Conda ----------
if command -v conda &>/dev/null; then
  echo "🧪 Conda encontrado: $(conda --version)"

  CONDA_BASE="$(conda info --base)"
  # shellcheck disable=SC1091
  source "$CONDA_BASE/etc/profile.d/conda.sh"

  # Qué envs crear/actualizar (override opcional)
  ENVS_DEFAULT=("env-base.yml" "env-sithlab.yml")
  if [ -n "${AHR_ENVS:-}" ]; then
    read -r -a ENVS_DEFAULT <<< "$AHR_ENVS"
  fi

  for ENV_FILE in "${ENVS_DEFAULT[@]}"; do
    ENV_PATH="$COMMON_DIR/envs/$ENV_FILE"
    if [ -f "$ENV_PATH" ]; then
      echo "🧱 Procesando env: $ENV_FILE"

      TARGET_ENV="dev"
      if [[ "$ENV_FILE" == *"sithlab"* ]]; then
        TARGET_ENV="sithlab"
      fi

      if conda env list | awk '{print $1}' | grep -qx "$TARGET_ENV"; then
        conda env update -n "$TARGET_ENV" -f "$ENV_PATH"
      else
        conda env create -n "$TARGET_ENV" -f "$ENV_PATH"
      fi
    else
      echo "⚠️ No existe $ENV_PATH (skip)"
    fi
  done

  # ---------- pip packages dentro del env (evita pip global sucio) ----------
  if [ -f "$COMMON_DIR/pip-packages.txt" ]; then
    echo "📌 Instalando pip packages en conda env: dev"
    conda run -n dev python -m pip install --upgrade pip
    conda run -n dev python -m pip install -r "$COMMON_DIR/pip-packages.txt"
  fi

else
  echo "⚠️ conda no encontrado. Instala Miniconda/Anaconda/mambaforge y re-corre."
fi

# ---------- Dotfiles ----------
echo "📁 Restaurando dotfiles..."

# Copiar con backup si existe el archivo destino
backup_copy () {
  local src="$1"
  local dst="$2"
  if [ -f "$src" ]; then
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
      local TS
      TS="$(date +%Y%m%d-%H%M%S)"
      echo "📦 Backup: $dst -> $dst.backup-$TS"
      cp "$dst" "$dst.backup-$TS"
    fi
    cp "$src" "$dst"
  fi
}

backup_copy "$LINUX_DIR/dotfiles/.bashrc"   "$HOME/.bashrc"
backup_copy "$LINUX_DIR/dotfiles/.profile" "$HOME/.profile"
backup_copy "$COMMON_DIR/gitconfig"        "$HOME/.gitconfig"

# ---------- Auto-run de fetch (bash + zsh) ----------
echo "🧩 Configurando auto-run de (neo/fast)fetch..."

AUTOFETCH_BLOCK_BASH=$(cat <<'EOF'
# >>> AHR auto-fetch (managed) >>>
# Solo shells interactivos
case $- in
  *i*)
    # Desactiva por sesión: AHR_NO_FETCH=1 bash
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
)

apply_block () {
  local file="$1"
  local start="# >>> AHR auto-fetch (managed) >>>"
  local end="# <<< AHR auto-fetch (managed) <<<"

  touch "$file"
  if grep -qF "$start" "$file"; then
    # GNU sed (Linux): -i sin sufijo
    sed -i "/$start/,/$end/c\\$AUTOFETCH_BLOCK_BASH" "$file"
  else
    printf "\n%s\n" "$AUTOFETCH_BLOCK_BASH" >> "$file"
  fi
}

apply_block "$HOME/.bashrc"
apply_block "$HOME/.zshrc"

echo "✅ Linux listo."
