#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GLOBAL="$ROOT_DIR/global"
SO_DIR="$ROOT_DIR/so"
README="$ROOT_DIR/README.md"

mkdir -p "$GLOBAL/envs" "$SO_DIR/macos" "$SO_DIR/linux" "$SO_DIR/windows"

FECHA="$(date '+%Y-%m-%d')"
STAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"
OS="$(uname -s)"

echo "🧾 Snapshot @ $STAMP" > "$GLOBAL/LAST_UPDATE.txt"

# ---------------- Conda + pip (sithlab only) ----------------
DETAIL="pip + conda (sithlab)"

if command -v conda &>/dev/null; then
  echo "🧪 Exportando conda env: sithlab"
  conda env export --from-history -n sithlab \
    | sed '/^prefix:/d' \
    > "$GLOBAL/envs/env-sithlab.yml"

  echo "🐍 Exportando pip freeze (sithlab)"
  conda run -n sithlab python -m pip freeze > "$GLOBAL/pip-sithlab.txt"
else
  echo "⚠️ conda no encontrado. (skip conda/pip snapshot)"
fi

# ---------------- Paquetes del SO ----------------
if [[ "$OS" == "Darwin" ]]; then
  if command -v brew &>/dev/null; then
    echo "🍺 Dump Brewfile (macOS)"
    brew bundle dump --force --file="$SO_DIR/macos/Brewfile"
    DETAIL="$DETAIL + brew"
  else
    echo "⚠️ brew no encontrado (skip Brewfile)"
  fi

elif [[ "$OS" == "Linux" ]]; then
  if command -v apt &>/dev/null && command -v dpkg-query &>/dev/null; then
    echo "📦 Dump apt-packages.txt"
    dpkg-query -f '${binary:Package}\n' -W | sort > "$SO_DIR/linux/apt-packages.txt"
    DETAIL="$DETAIL + apt"
  elif command -v pacman &>/dev/null; then
    echo "📦 Dump pacman-packages.txt"
    pacman -Qqe | sort > "$SO_DIR/linux/pacman-packages.txt"
    DETAIL="$DETAIL + pacman"
  else
    echo "⚠️ No se detectó gestor compatible (apt/pacman)."
  fi
fi

# ---------------- Log en README ----------------
START="<!-- BACKUP_LOG_START -->"
END="<!-- BACKUP_LOG_END -->"
LINE="| $FECHA | Respaldo automático | $DETAIL |"

if [[ -f "$README" ]] && grep -qF "$START" "$README" && grep -qF "$END" "$README"; then
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
  echo "$LINE" >> "$README"
fi

echo "✅ Respaldo completado para el $FECHA"
