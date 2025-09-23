#!/bin/bash

# Directorio del repositorio (cambia esto si es necesario)
REPO_DIR="/data/data/com.termux/files/home/storage/downloads/brain_maps"

# Intervalo de tiempo en segundos entre cada verificación de cambios
INTERVAL=60

# Entrar en el directorio del repositorio
cd "$REPO_DIR" || exit

while true; do
    # Verificar si hay cambios en el repositorio remoto
    git fetch

    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})

    if [ $LOCAL = $REMOTE ]; then
        echo "El repositorio local está sincronizado con el remoto."
    elif [ $LOCAL = $BASE ]; then
        echo "Cambios detectados en el remoto. Sincronizando..."
        git pull --rebase
    elif [ $REMOTE = $BASE ]; then
        echo "Hay cambios locales que no están en el remoto."
    else
        echo "El repositorio local y remoto han divergido. Es necesario resolver manualmente."
        exit 1
    fi

    # Verificar si hay cambios locales que no han sido commit
    if [[ -n $(git status --porcelain) ]]; then
        echo "Cambios locales detectados. Subiendo al repositorio..."

        # Añadir los cambios al índice
        git add .

        # Commit con un mensaje genérico (puedes modificar esto)
        git commit -m "Commit automático: cambios detectados"

        # Push a la rama principal
        git push origin main
    else
        echo "No se detectaron cambios locales."
    fi

    # Esperar el intervalo de tiempo antes de la próxima verificación
    sleep "$INTERVAL"
done
