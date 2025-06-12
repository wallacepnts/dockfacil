#!/bin/bash
set -euo pipefail

APPS_DIR="./apps"
BASE_VOLUME="/opt/docker-volumes"

echo "Baixando arquivos docker-compose..."
mkdir -p "$APPS_DIR"

# Baixa os arquivos se não existirem
if [ ! -f "$APPS_DIR/actual.yml" ]; then
  curl -fsSL https://raw.githubusercontent.com/wallacepnts/dockfacil/main/apps/actual.yml -o "$APPS_DIR/actual.yml"
fi
if [ ! -f "$APPS_DIR/deluge.yml" ]; then
  curl -fsSL https://raw.githubusercontent.com/wallacepnts/dockfacil/main/apps/deluge.yml -o "$APPS_DIR/deluge.yml"
fi

echo "=== Instalador Docker Interativo ==="
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
  echo "Nenhum app disponível para instalar. Abortando."
  exit 1
fi

echo
read -rp "Digite os números dos apps que deseja instalar (ex: 1 3): " -a selections

if [ "${#selections[@]}" -eq 0 ]; then
  echo "Nenhuma seleção feita. Abortando."
  exit 1
fi

for index in "${selections[@]}"; do
  if ! [[ "$index" =~ ^[0-9]+$ ]]; then
    echo "Seleção inválida: $index. Pulando."
    continue
  fi

  if (( index < 1 || index > ${#AVAILABLE_APPS[@]} )); then
    echo "Número fora do intervalo: $index. Pulando."
    continue
  fi

  app="${AVAILABLE_APPS[$((index-1))]}"
  export DOCKER_VOLUME="$BASE_VOLUME/$app"

  echo "-> Criando volume em $DOCKER_VOLUME"
  mkdir -p "$DOCKER_VOLUME"

  echo "-> Instalando $app..."
  docker compose -f "$APPS_DIR/$app.yml" up -d
done

echo
echo "✅ Instalação concluída!"
