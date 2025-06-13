#!/bin/bash
set -euo pipefail

APPS_DIR="./apps"
BASE_VOLUME="/opt/docker-volumes"
CSV_URL="https://raw.githubusercontent.com/wallacepnts/dockfacil/main/apps/apps.csv"
CSV_FILE="$APPS_DIR/apps.csv"

echo "📦 Baixando arquivos docker-compose e lista de apps..."
mkdir -p "$APPS_DIR"

if ! curl -fsSL "$CSV_URL" -o "$CSV_FILE"; then
  echo "❌ Falha ao baixar a lista de apps."
  exit 1
fi

if [ ! -s "$CSV_FILE" ]; then
  echo "❌ O arquivo de apps está vazio ou não existe."
  exit 1
fi

tail -n +2 "$CSV_FILE" | while IFS=',' read -r app label; do
  app=$(echo "$app" | xargs)
  label=$(echo "$label" | xargs)
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
read -rp "Digite os números dos apps que deseja instalar (ex: 1 3): " -a selections < /dev/tty

if [ "${#selections[@]}" -eq 0 ]; then
  echo "⚠️ Você não selecionou nenhum app."
  exit 1
fi

for index in "${selections[@]}"; do
  if ! [[ "$index" =~ ^[0-9]+$ ]]; then
    echo "❌ Seleção inválida: $index."
    continue
  fi

  if (( index < 1 || index > ${#AVAILABLE_APPS[@]} )); then
    echo "❌ Número fora do intervalo: $index."
    continue
  fi

  app="${AVAILABLE_APPS[$((index-1))]}"
  label="${AVAILABLE_LABELS[$((index-1))]}"
  export DOCKER_VOLUME="$BASE_VOLUME/$app"

  echo
    read -rp "Deseja reinstalar (parar, remover e subir novamente) o $label? (s/N): " answer < /dev/tty
    case "$answer" in
      [Ss]* )
        echo "🔄 Reinstalando $label..."
        docker rm -f "$app"
        docker compose -f "$APPS_DIR/$app.yml" up -d
        ;;
      * )
        echo "⏩ Pulando $app..."
        ;;
    esac
  elif [[ -n "$existing_container" ]]; then
    echo "⚠️ O container \"$app\" existe, mas não está rodando."
    read -rp "Deseja iniciar/reinstalar o $label? (s/N): " answer < /dev/tty
    case "$answer" in
      [Ss]* )
        echo "🔄 Iniciando/reinstalando $label..."
        docker rm -f "$app" || true
        docker compose -f "$APPS_DIR/$app.yml" up -d
        ;;
      * )
        echo "⏩ Pulando $app..."
        ;;
    esac
        echo "🔄 Iniciando/reinstalando $label..."
        docker rm -f "$app" || true
        docker compose -f "$APPS_DIR/$app.yml" up -d
        ;;
      * )
        echo "⏩ Pulando $app..."
        ;;
    esac
  else
    echo "📥 Instalando $label..."
    docker compose -f "$APPS_DIR/$app.yml" up -d
  fi
done
