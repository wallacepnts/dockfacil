#!/bin/bash

set -euo pipefail

APPS_DIR="/tmp/apps"
BASE_VOLUME="/opt/docker-volumes"

if [ ! -d "$APPS_DIR" ]; then
  echo "Baixando arquivos docker-compose..."
  mkdir -p "$APPS_DIR"
  curl -fsSL https://seusite.com/apps/actual.yml -o "$APPS_DIR/actual.yml"
  curl -fsSL https://seusite.com/apps/portainer.yml -o "$APPS_DIR/portainer.yml"
fi

echo "=== Instalador Docker Interativo ==="
echo

AVAILABLE_APPS=()
i=1
for file in "$APPS_DIR"/*.yml; do
  app=$(basename "$file" .yml)
  AVAILABLE_APPS+=("$app")
  echo "$i) $app"
  ((i++))
done

echo
read -p "Digite os números dos apps que deseja instalar (ex: 1 3): " -a selections
echo

for index in "${selections[@]}"; do
  app="${AVAILABLE_APPS[$((index-1))]}"
  export DOCKER_VOLUME="$BASE_VOLUME/$app"

  echo "-> Criando volume em $DOCKER_VOLUME"
  mkdir -p "$DOCKER_VOLUME"

  echo "-> Verificando se o container '$app' já existe..."
  if docker ps -a --format '{{.Names}}' | grep -wq "$app"; then
    echo "⚠️  O container '$app' já existe."
    read -p "Deseja removê-lo e instalar novamente? (s/n): " resposta
    if [[ "$resposta" =~ ^[sS]$ ]]; then
      docker rm -f "$app"
    else
      echo "⏩ Pulando instalação de $app"
      continue
    fi
  fi

  echo "-> Instalando $app..."
  DOCKER_VOLUME="$DOCKER_VOLUME" docker compose -f "$APPS_DIR/$app.yml" up -d
done

echo
echo "✅ Instalação concluída!"