#!/bin/bash
set -euo pipefail

APPS_DIR="./apps"
BASE_VOLUME="/opt/docker-volumes"
CSV_URL="https://raw.githubusercontent.com/wallacepnts/dockfacil/main/apps/apps.csv"
CSV_FILE="$APPS_DIR/apps.csv"

echo "📦 Baixando arquivos docker-compose e lista de apps..."
mkdir -p "$APPS_DIR"

curl -fsSL "$CSV_URL" -o "$CSV_FILE"

tail -n +2 "$CSV_FILE" | while IFS=',' read -r app label; do
  app=$(echo "$app" | xargs)       # tira espaços
  label=$(echo "$label" | xargs)   # tira espaços
  file="$APPS_DIR/$app.yml"
  if [ ! -f "$file" ]; then
    curl -fsSL "https://raw.githubusercontent.com/wallacepnts/dockfacil/main/apps/$app.yml" -o "$file"
  fi
done

echo
echo "=== 🚀 DockFácil - Instalador Docker Interativo ==="
echo

AVAILABLE_APPS=()
AVAILABLE_LABELS=()

while IFS=',' read -r app label; do

  if [[ "$app" == "app" ]]; then
    continue
  fi
  app=$(echo "$app" | xargs)
  label=$(echo "$label" | xargs)
  AVAILABLE_APPS+=("$app")
  AVAILABLE_LABELS+=("$label")
done < "$CSV_FILE"

for i in "${!AVAILABLE_APPS[@]}"; do
  echo "$((i+1))) ${AVAILABLE_LABELS[$i]}"
done

echo

selections=()

echo -n "Digite os números dos apps que deseja instalar (ex: 1 3): "
read -r input
IFS=' ' read -r -a selections <<< "$input"

if [ "${#selections[@]}" -eq 0 ]; then
  echo "⚠️ Você não selecionou nenhum app. Abortando."
  exit 1
fi

installed_count=0

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
  label="${AVAILABLE_LABELS[$((index-1))]}"
  export DOCKER_VOLUME="$BASE_VOLUME/$app"

  echo
  echo "🔧 Criando volume em $DOCKER_VOLUME"
  mkdir -p "$DOCKER_VOLUME"

  if docker ps -a --format '{{.Names}}' | grep -qw "$app"; then
    echo "⚠️ O container \"$app\" já existe."
    read -rp "❓ Deseja reinstalar o container \"$app\"? (s/N): " yn
    case "$yn" in
      [Ss]* )
        docker compose -f "$APPS_DIR/$app.yml" down
        docker compose -f "$APPS_DIR/$app.yml" up -d && ((installed_count++))
        ;;
      * )
        echo "⏩ Pulando $app..."
        ;;
    esac
  else
    echo "📥 Instalando $label..."
    docker compose -f "$APPS_DIR/$app.yml" up -d && ((installed_count++))
  fi
done

echo

if (( installed_count == 0 )); then
  echo "⚠️ Nenhum aplicativo foi instalado."
elif (( installed_count == 1 )); then
  echo "✅ 1 aplicativo instalado com sucesso!"
else
  echo "✅ $installed_count aplicativos instalados com sucesso!"
fi
