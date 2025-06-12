#!/bin/bash
set -euo pipefail

APPS_DIR="./apps"
BASE_VOLUME="/opt/docker-volumes"
CSV_URL="https://raw.githubusercontent.com/wallacepnts/dockfacil/main/apps/apps.csv"
CSV_FILE="$APPS_DIR/apps.csv"

echo "📦 Baixando arquivos docker-compose..."
mkdir -p "$APPS_DIR"

# Baixa o CSV para a pasta apps
curl -fsSL "$CSV_URL" -o "$CSV_FILE"

# Baixa os arquivos docker-compose conforme o CSV (pulando a primeira linha)
tail -n +2 "$CSV_FILE" | while IFS=',' read -r app label; do
  file="$APPS_DIR/$app.yml"
  if [ ! -f "$file" ]; then
    curl -fsSL "https://raw.githubusercontent.com/wallacepnts/dockfacil/main/apps/$app.yml" -o "$file"
  fi
done

echo
echo "=== 🚀 DockFácil - Instalador Docker Interativo ==="
echo

# Inicializa arrays
AVAILABLE_APPS=()
AVAILABLE_LABELS=()

# Ler CSV e preencher arrays
while IFS=',' read -r app label; do
  AVAILABLE_APPS+=("$app")
  AVAILABLE_LABELS+=("$label")
done < <(tail -n +2 "$CSV_FILE")

# Mostrar opções
for (( idx=0; idx < ${#AVAILABLE_APPS[@]}; idx++ )); do
  echo "$((idx+1))) ${AVAILABLE_LABELS[$idx]}"
done

echo
read -rp "Digite os números dos apps que deseja instalar (ex: 1 3): " -a selections < /dev/tty

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
  export DOCKER_VOLUME="$BASE_VOLUME/$app"

  echo
  echo "🔧 Criando volume em $DOCKER_VOLUME"
  mkdir -p "$DOCKER_VOLUME"

  echo "📥 Instalando ${AVAILABLE_LABELS[$((index-1))]}..."
  docker compose -f "$APPS_DIR/$app.yml" up -d && ((installed_count++))
done

echo

if (( installed_count == 0 )); then
  echo "⚠️ Nenhum aplicativo foi instalado."
elif (( installed_count == 1 )); then
  echo "✅ 1 aplicativo instalado com sucesso!"
else
  echo "✅ $installed_count aplicativos instalados com sucesso!"
fi