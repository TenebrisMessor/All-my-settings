#!/usr/bin/env bash
set -euo pipefail

echo "🌐 Common setup (global) — Conda + sithlab + NVIM + shortcuts"

# Repo root (este archivo vive en: global/setup-common.sh)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLOBAL_DIR="$ROOT_DIR/global"

ENV_YML="$GLOBAL_DIR/envs/env-sithlab.yml"
PIP_REQ="$GLOBAL_DIR/pip-sithlab.txt"
NVIM_SOURCE="$GLOBAL_DIR/nvim"
NVIM_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

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

# Inserta/actualiza un bloque "managed" en rc files de forma robusta (sin sed tricky)
apply_block() {
  local file="$1"
  local start="$2"
  local end="$3"
  local block="$4"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if grep -qF "$start" "$file"; then
    awk -v s="$start" -v e="$end" -v b="$block" '
      BEGIN{in=0}
      $0==s {print b; in=1; next}
      $0==e {in=0; next}
      in==0 {print}
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  else
    printf "\n%s\n" "$block" >> "$file"
  fi
}

# mktemp con extensión .yml (crítico para conda env update/create)
mktemp_yml() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    local base
    base="$(mktemp -t sithlabXXXXXX)"   # <-- aquí NO pongas .yml
    echo "${base}.yml"                 # <-- aquí sí garantizas el suffix real
  else
    mktemp --suffix=.yml
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

# IMPORTANTE: quitar prefix: para portabilidad + evitar problemas
TMP_ENV="$(mktemp_yml)"
grep -vE '^\s*prefix:\s*' "$ENV_YML" > "$TMP_ENV"

if conda env list | awk '{print $1}' | grep -qx "sithlab"; then
  log "🧪 Actualizando env: sithlab (conda env update)..."
  conda env update -n sithlab -f "$TMP_ENV" --prune
else
  log "🧪 Creando env: sithlab (conda env create)..."
  conda env create -n sithlab -f "$TMP_ENV"
fi

rm -f "$TMP_ENV"
log "✅ Env listo: sithlab"

# ---------------- 3) Instalar librerías pip dentro de sithlab ----------------
if [ -f "$PIP_REQ" ]; then
  log "📌 Instalando libs pip en sithlab desde: global/pip-sithlab.txt"

  # Limpia líneas que apuntan a paths locales (file://, conda-bld, /Users/runner, etc.)
  TMP_PIP="$(mktemp -t sithlabpipXXXXXX).txt"
  awk '
    NF &&
    $1 !~ /^#/ &&
    $0 !~ / @ file:|file:\/\/|\/conda-bld\/|\/Users\/runner\// { print }
  ' "$PIP_REQ" > "$TMP_PIP"

  if [ -s "$TMP_PIP" ]; then
    # No mates el script si pip falla (queremos que NVIM y shortcuts sí se apliquen)
    set +e
    conda run -n sithlab python -m pip install --upgrade pip
    conda run -n sithlab python -m pip install --no-deps -r "$TMP_PIP"
    PIP_RC=$?
    set -e

    if [ $PIP_RC -ne 0 ]; then
      log "⚠️ pip falló (pero continúo). Revisa $PIP_REQ por entradas raras."
    fi
  else
    log "⚠️ pip-sithlab.txt quedó vacío tras limpiar paths (skip pip install)"
  fi

  rm -f "$TMP_PIP"
else
  log "⚠️ No existe $PIP_REQ (skip pip libs)"
fi

# ---------------- 4) Deploy NVIM config (symlink al repo) ----------------
log "🧠 Deploy de config Neovim..."
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"

if [ ! -d "$NVIM_SOURCE" ]; then
  log "❌ No existe carpeta NVIM en repo: $NVIM_SOURCE"
  exit 1
fi

backup_move "$NVIM_TARGET"
ln -sfn "$NVIM_SOURCE" "$NVIM_TARGET"
log "✅ NVIM apuntando a repo: $NVIM_TARGET -> $NVIM_SOURCE"

# ---------------- 4.5) Bootstrap packer.nvim ----------------
NVIM_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
PACKER_DIR="$NVIM_DATA/site/pack/packer/start/packer.nvim"

log "📦 Bootstrapping packer.nvim..."
if [ ! -d "$PACKER_DIR" ]; then
  git clone --depth 1 https://github.com/wbthomason/packer.nvim "$PACKER_DIR"
  log "✅ packer.nvim instalado en: $PACKER_DIR"
else
  log "✅ packer.nvim ya existe: $PACKER_DIR"
fi

# ---------------- 4.6) Instalar/actualizar plugins ----------------
log "🔧 Corriendo PackerSync (headless)..."
nvim --headless +PackerSync +qa || log "⚠️ PackerSync falló (revisa errores arriba)"

# ---------------- 5) Shortcuts (bash + zsh) ----------------
log "⚡ Agregando shortcuts (bash/zsh): comando 'sithlab'"

START="# >>> AHR shortcuts (managed) >>>"
END="# <<< AHR shortcuts (managed) <<<"

SHORTCUT_BLOCK="$(cat <<EOF
$START
# Carga conda en shells interactivos y crea comando "sithlab"
case \$- in
  *i*)
    if command -v conda >/dev/null 2>&1; then
      CONDA_BASE="\$(conda info --base 2>/dev/null)"
      if [ -n "\$CONDA_BASE" ] && [ -f "\$CONDA_BASE/etc/profile.d/conda.sh" ]; then
        source "\$CONDA_BASE/etc/profile.d/conda.sh"
      fi
      sithlab() { conda activate sithlab; }
    fi
  ;;
esac
$END
EOF
)"

apply_block "$HOME/.zshrc" "$START" "$END" "$SHORTCUT_BLOCK"
apply_block "$HOME/.bashrc" "$START" "$END" "$SHORTCUT_BLOCK"

log "✅ Common setup terminado."
log "👉 Abre una NUEVA terminal y escribe: sithlab"
