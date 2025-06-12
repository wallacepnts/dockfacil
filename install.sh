#!/bin/bash
set -euo pipefail

APPS_DIR="./apps"
BASE_VOLUME="/opt/docker-volumes"

echo "📦 Baixando arquivos docker-compose..."
mkdir -p "$APPS_DIR"

APPS=$(cat <<EOF
actual
deluge
EOF
)

for app in $APPS; do
  file="$APPS_DIR/$app.yml"
  if [ ! -f "$file" ]; then
    curl -fsSL "https://raw.githubusercontent.com/wallacepnts/dockfacil/main/apps/$app.yml" -o "$file"
  fi
done

echo
echo "=== 🚀 DockFácil - Instalador Docker Interativo ==="
echo

AVAILABLE_APPS=()
i=1
for file in "$APPS_DIR"/*.yml; do
  appname=$(basename "$file" .yml)
  AVAILABLE_APPS+=("$appname")
  echo "$i) $appname"
  ((i++))
done

if [ "${#AVAILABLE_APPS[@]}" -eq 0 ]; then
  echo "❌ Nenhum app disponível para instalar. Abortando."
  exit 1
fi

echo
selections=()
read -rp "Digite os números dos apps que deseja instalar (ex: 1 3): " -a selections < /dev/tty

if [ "${#selections[@]}" -eq 0 ]; then
  echo "⚠️  Você não selecionou nenhum app. Abortando."
  exit 1
fi

for index in "${selections[@]}"; do
  if ! [[ "$index" =~ ^[0-9]+$ ]]; then
    echo "❌ Seleção inválida: $index. Pulando."
    continue
  fi

  if (( index < 1 || index > ${#AVAILABLE_APPS[@]} )); then
    echo "❌ Número fora do intervalo: $index. Pulando."
    continue
  fi

  app="${AVAILABLE_APPS[$((index-1))]}"
  export DOCKER_VOLUME="$BASE_VOLUME/$app"

  echo
  echo "🔧 Criando volume em $DOCKER_VOLUME"
  mkdir -p "$DOCKER_VOLUME"

  container_name=$(docker compose -f "$APPS_DIR/$app.yml" config --services | head -n1)

  if docker ps -a --format '{{.Names}}' | grep -q "^$container_name\$"; then
    echo "⚠️  O container \"$container_name\" já existe."

    read -rp "❓ Deseja recriar o container \"$container_name\"? (s/N): " confirm < /dev/tty
    if [[ ! "$confirm" =~ ^[sS]$ ]]; then
      echo "⏩ Pulando $app..."
      continue
    fi

    echo "🧹 Removendo container antigo..."
    docker compose -f "$APPS_DIR/$app.yml" down
  fi

  echo "📥 Instalando $app..."
  docker compose -f "$APPS_DIR/$app.yml" up -d
done

echo
echo "✅ Instalação concluída com sucesso!"