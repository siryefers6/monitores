#!/bin/bash

# Ruta de la carpeta a monitorear
DIRECTORIO_SCRIPT="$(dirname "$(realpath "$0")")"
DIRECTORIO_ARCHIVOS="/sdcard/DCIM/Camera"

# Archivo que guarda el nombre del último archivo más reciente
ARCHIVO_ACTUAL="$DIRECTORIO_SCRIPT/archivo_actual.txt"

# Intervalo de tiempo entre verificaciones (en segundos)
INTERVALO=2

# Función para verificar si el archivo está siendo escrito
archivo_terminado() {
    local archivo=$1
    local tamano_inicial=$(stat -c%s "$archivo")
    sleep 2
    local tamano_final=$(stat -c%s "$archivo")
    if [ "$tamano_inicial" -eq "$tamano_final" ]; then
        return 0
    else
        return 1
    fi
}

# Bucle infinito para monitorear cambios
while true; do
    ARCHIVO_MAS_RECIENTE=$(ls -t "$DIRECTORIO_ARCHIVOS"/*.mp4 2>/dev/null | head -n 1)

    if [ -f "$ARCHIVO_ACTUAL" ]; then
        ULTIMO_ARCHIVO=$(cat "$ARCHIVO_ACTUAL")
    else
        ULTIMO_ARCHIVO=""
    fi

    # Si el archivo más reciente ha cambiado y ha terminado de grabarse
    if [ "$ARCHIVO_MAS_RECIENTE" != "$ULTIMO_ARCHIVO" ] && archivo_terminado "$ARCHIVO_MAS_RECIENTE"; then
        sleep 1
        # Intentar copiar el archivo con SCP
        if scp -i ~/.ssh/id_rsa3 "$ARCHIVO_MAS_RECIENTE" "siryefers@34.176.24.188:/home/siryefers/videos/"; then
            echo "Archivo copiado: $ARCHIVO_MAS_RECIENTE"
            echo "$ARCHIVO_MAS_RECIENTE" > "$ARCHIVO_ACTUAL"
        else
            echo "Error al copiar $ARCHIVO_MAS_RECIENTE. Intentando de nuevo..."
        fi
    fi

    sleep $INTERVALO
done

