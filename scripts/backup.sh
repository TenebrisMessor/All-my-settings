#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMON="$ROOT_DIR/common"
MAC="$ROOT_DIR/macos"
LINUX="$ROOT_DIR/linux"
README="$ROOT_DIR/README.md"

mkdir -p "$COMMON/envs" "$MAC" "$LINUX"

FECHA="$(date '+%Y-%m-%d')"
STAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"
OS="$(uname -s)"

echo "🧾 Snapshot @ $STAMP" > "$COMMON/LAST_UPDATE.txt"

# ---------------- Conda + pip (sithlab only) ----------------
if command -v conda &>/dev/null; then
  echo "🧪 Exportando conda env: sithlab"
  conda env export --from-history -n sithlab > "$COMMON/envs/env-sithlab.yml"

  echo "🐍 Exportando pip freeze (sithlab)"
  conda run -n sithlab python -m pip freeze > "$COMMON/pip-packages.txt"
else
  echo "⚠️ conda no encontrado. (skip conda/pip snapshot)"
fi

# ---------------- Paquetes del SO ----------------
DETAIL="pip + conda (sithlab)"

if [[ "$OS" == "Darwin" ]]; then
  if command -v brew &>/dev/null; then
    echo "🍺 Dump Brewfile (macOS)"
    brew bundle dump --force --file="$MAC/Brewfile"
    DETAIL="$DETAIL + brew"
  else
    echo "⚠️ brew no encontrado (skip Brewfile)"
  fi

elif [[ "$OS" == "Linux" ]]; then
  if command -v apt &>/dev/null && command -v dpkg-query &>/dev/null; then
    echo "📦 Dump apt-packages.txt"
    dpkg-query -f '${binary:Package}\n' -W | sort > "$LINUX/apt-packages.txt"
    DETAIL="$DETAIL + apt"
  elif command -v pacman &>/dev/null; then
    echo "📦 Dump pacman-packages.txt"
    pacman -Qqe | sort > "$LINUX/pacman-packages.txt"
    DETAIL="$DETAIL + pacman"
  else
    echo "⚠️ No se detectó gestor compatible (apt/pacman)."
  fi
fi

# ---------------- Log en README ----------------
# Recomendado: tener marcadores en README para no ensuciarlo infinito.
START="<!-- BACKUP_LOG_START -->"
END="<!-- BACKUP_LOG_END -->"
LINE="| $FECHA | Respaldo automático | $DETAIL |"

if [[ -f "$README" ]] && grep -qF "$START" "$README" && grep -qF "$END" "$README"; then
  # Inserta LINE después del separador |---|---|---| dentro del bloque
  awk -v start="$START" -v end="$END" -v newline="$LINE" '
    BEGIN{inblock=0; inserted=0}
    $0==start {inblock=1; print; next}
    $0==end {inblock=0; print; next}
    {
      if(inblock==1 && inserted==0 && $0 ~ /^\|---\|/) {
        print
        print newline
        inserted=1
        next
      }
      print
    }
  ' "$README" > "$README.tmp" && mv "$README.tmp" "$README"
else
  # Fallback: si no hay marcadores, lo agrega al final (como tu script original)
  echo "$LINE" >> "$README"
fi

echo "✅ Respaldo completado para el $FECHA"
