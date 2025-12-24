#!/usr/bin/env bash
set -euo pipefail

echo "🌐 Common setup (global) — Conda + sithlab + NVIM + shortcuts"

# Repo root (este archivo vive en: global/setup-common.sh)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLOBAL_DIR="$ROOT_DIR/global"

ENV_YML="$GLOBAL_DIR/envs/env-sithlab.yml"
PIP_REQ="$GLOBAL_DIR/pip-sithlab.txt"
NVIM_SOURCE="$GLOBAL_DIR/nvim"
NVIM_TARGET="$HOME/.config/nvim"

# ---------------- Helpers ----------------
log() { echo -e "$@"; }

backup_move() {
  local path="$1"
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    log "📦 Backup: $path -> ${path}.backup-$ts"
    mv "$path" "${path}.backup-$ts"
  fi
}

apply_block() {
  # Inserta/actualiza un bloque "managed" en un archivo shell rc
  local file="$1"
  local start="$2"
  local end="$3"
  local content="$4"

  touch "$file"
  if grep -qF "$start" "$file"; then
    # macOS sed necesita sufijo para -i; Linux lo permite sin sufijo
    if sed --version >/dev/null 2>&1; then
      sed -i "/$start/,/$end/c\\$content" "$file"
    else
      sed -i '' "/$start/,/$end/c\\$content" "$file"
    fi
  else
    printf "\n%s\n" "$content" >> "$file"
  fi
}

# ---------------- 1) Conda bootstrap (no instala conda: asume que ya existe) ----------------
if ! command -v conda >/dev/null 2>&1; then
  log "❌ conda no encontrado."
  log "   Instala Miniconda/Mambaforge y vuelve a correr este setup."
  exit 1
fi

CONDA_BASE="$(conda info --base)"
# shellcheck disable=SC1091
source "$CONDA_BASE/etc/profile.d/conda.sh"
log "✅ Conda cargado: $(conda --version) | base: $CONDA_BASE"

# ---------------- 2) Crear/Actualizar env sithlab desde YAML del repo ----------------
if [ ! -f "$ENV_YML" ]; then
  log "❌ No existe: $ENV_YML"
  exit 1
fi

# IMPORTANTÍSIMO:
# Tu YAML puede traer "prefix:" (eso rompe portabilidad). Lo filtramos.
TMP_ENV="$(mktemp)"
grep -vE '^\s*prefix:\s*' "$ENV_YML" > "$TMP_ENV"

if conda env list | awk '{print $1}' | grep -qx "sithlab"; then
  log "🧪 Actualizando env: sithlab (conda env update)..."
  conda env update -n sithlab -f "$TMP_ENV"
else
  log "🧪 Creando env: sithlab (conda env create)..."
  conda env create -n sithlab -f "$TMP_ENV"
fi

rm -f "$TMP_ENV"
log "✅ Env listo: sithlab"

# ---------------- 3) Instalar librerías pip dentro de sithlab ----------------
if [ -f "$PIP_REQ" ]; then
  log "📌 Instalando libs pip en sithlab desde: global/pip-sithlab.txt"
  conda run -n sithlab python -m pip install --upgrade pip
  conda run -n sithlab python -m pip install -r "$PIP_REQ"
else
  log "⚠️ No existe $PIP_REQ (skip pip libs)"
fi

# ---------------- 4) Deploy NVIM config (symlink al repo) ----------------
log "🧠 Deploy de config Neovim..."
mkdir -p "$HOME/.config"

if [ ! -d "$NVIM_SOURCE" ]; then
  log "❌ No existe carpeta NVIM en repo: $NVIM_SOURCE"
  exit 1
fi

backup_move "$NVIM_TARGET"
ln -sfn "$NVIM_SOURCE" "$NVIM_TARGET"
log "✅ NVIM apuntando a repo: $NVIM_TARGET -> $NVIM_SOURCE"

# ---------------- 5) Shortcuts (bash + zsh) ----------------
log "⚡ Agregando shortcuts (bash/zsh): comando 'sithlab'"

SHORTCUT_BLOCK=$(cat <<'EOF'
# >>> AHR shortcuts (managed) >>>
# Carga conda en shells interactivos y crea comando "sithlab"
case $- in
  *i*)
    if command -v conda >/dev/null 2>&1; then
      CONDA_BASE="$(conda info --base 2>/dev/null)"
      if [ -n "$CONDA_BASE" ] && [ -f "$CONDA_BASE/etc/profile.d/conda.sh" ]; then
        # shellcheck disable=SC1091
        source "$CONDA_BASE/etc/profile.d/conda.sh"
      fi
      sithlab() { conda activate sithlab; }
    fi
  ;;
esac
# <<< AHR shortcuts (managed) <<<
EOF
)

apply_block "$HOME/.zshrc" "# >>> AHR shortcuts (managed) >>>" "# <<< AHR shortcuts (managed) <<<" "$SHORTCUT_BLOCK"
apply_block "$HOME/.bashrc" "# >>> AHR shortcuts (managed) >>>" "# <<< AHR shortcuts (managed) <<<" "$SHORTCUT_BLOCK"

log "✅ Common setup terminado."
log "👉 Abre una NUEVA terminal y escribe: sithlab"
