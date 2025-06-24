FECHA=$(date +%Y-%m-%d)
ENV_ACTUAL=$(conda info --envs | awk "/\*/ {print \$1}")

echo "🔍 Detectando sistema..."
OS=$(uname -s)

if [[ "$OS" == "Linux" ]]; then
  if command -v apt > /dev/null; then
    echo "📦 Respaldando paquetes APT..."
    dpkg --get-selections > ~/Documents/Configuraciones/linux/apt-packages.txt
  elif command -v pacman > /dev/null; then
    echo "📦 Respaldando paquetes Pacman..."
    pacman -Qe > ~/Documents/Configuraciones/linux/pacman-packages.txt
  else
    echo "⚠️ No se detectó un gestor de paquetes compatible."
  fi
fi

echo "🐍 Respaldando paquetes pip del entorno activo ($ENV_ACTUAL)..."
pip freeze > ~/Documents/Configuraciones/common/pip-packages.txt

echo "🧪 Exportando entorno conda ($ENV_ACTUAL)..."
conda env export -n $ENV_ACTUAL > ~/Documents/Configuraciones/common/envs/env-$ENV_ACTUAL.yml

echo "| $FECHA | Respaldo automático | pip + paquetes + conda ($ENV_ACTUAL) |" >> ~/Documents/Configuraciones/README.md

echo "✅ Respaldo completado para el $FECHA"
