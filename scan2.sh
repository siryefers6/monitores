#!/bin/bash

API_URL="https://app.siryefers.org"
DIR_VIDEOS="/sdcard/DCIM/Camera"
NOMBRE="yeferson"
TRACK_FILE="ultimo_enviado.txt"
INTERVALO=5

mkdir -p "$(dirname "$TRACK_FILE")"
touch "$TRACK_FILE"

echo "🌀 Iniciando bucle de monitoreo en: $DIR_VIDEOS"
while true; do
  VIDEO_PATH=$(find "$DIR_VIDEOS" -type f -name "*.mp4" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2-)

  if [ -z "$VIDEO_PATH" ]; then
    sleep "$INTERVALO"
    continue
  fi

  FILENAME=$(basename "$VIDEO_PATH")

  if grep -Fxq "$FILENAME" "$TRACK_FILE"; then
    sleep "$INTERVALO"
    continue
  fi

  # Esperar que el tamaño del archivo se estabilice
  PREV_SIZE=0
  STABLE_COUNT=0
  MAX_STABLE=2
  CHECK_DELAY=1
  echo "⏳ Esperando a que se estabilice: $FILENAME"
  while true; do
    CUR_SIZE=$(stat -c %s "$VIDEO_PATH" 2>/dev/null || echo 0)
    if [ "$CUR_SIZE" -eq "$PREV_SIZE" ]; then
      ((STABLE_COUNT++))
    else
      STABLE_COUNT=0
      PREV_SIZE=$CUR_SIZE
    fi

    if [ "$STABLE_COUNT" -ge "$MAX_STABLE" ]; then
      break
    fi

    sleep "$CHECK_DELAY"
  done

  echo "📤 Enviando: $FILENAME"

  RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/resp_upload.json \
    -F "file=@$VIDEO_PATH" \
    -F "nombre=$NOMBRE" \
    "$API_URL/upload_video")

  if [ "$RESPONSE" -ne 200 ]; then
    echo "❌ Fallo al subir video ($RESPONSE)"
    cat /tmp/resp_upload.json
    sleep "$INTERVALO"
    continue
  fi

  echo "$FILENAME" > "$TRACK_FILE"
  echo "✅ Subido y registrado: $FILENAME"
  echo

  sleep "$INTERVALO"
done
