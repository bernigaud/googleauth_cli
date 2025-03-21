#!/bin/bash

# Charger les variables d'environnement à partir du fichier .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Requirement: sudo apt-get install oathtool

# Extraction des noms de services et de leurs clés depuis le fichier .env
declare -A SERVICES

while IFS='=' read -r key value; do
    if [[ $key == *_KEY ]]; then
        service_name="${key%%_KEY}"
        service_name="$(echo "$service_name" | tr '[:upper:]' '[:lower:]')"
        
	# echo DEBUG $service_name
	SERVICES[$service_name]=$value
    fi
done < .env

function formatTime {
    current_time=$(date +"%H:%M:%S")
    seconds=$(date +"%S")
    
    if [[ $seconds -ge 00 && $seconds -le 30 ]]; then
        # Afficher en vert clair (code couleur ANSI)
        printf "%-12s \033[92m%s\033[0m\n" "Time" "$current_time"
    elif [[ $seconds -ge 50 && $seconds -le 59 ]]; then
        # Afficher en rouge clair (code couleur ANSI)
        printf "%-12s \033[91m%s\033[0m\n" "Time" "$current_time"
    else
        # Afficher normalement
        printf "%-12s %s\n" "Time" "$current_time"
    fi
    
    echo "-------------------"
}


function formatGA0 {
    printf "%-12s %s\n" "$1" $(oathtool --totp -b "$2")
}

function formatGA {
    # Supprimer tous les caractères non-alphanumériques (sauf = qui est valide en base32)
    local clean_key=$(echo "$2" | tr -dc 'A-Za-z0-9=')
    printf "%-12s %s\n" "$1" $(oathtool --totp -b "$clean_key")
}

formatTime

# Lire l'ordre des services depuis .env
# La variable DISPLAY_SERVICES dans .env doit être au format: "service1,service2,service3"
if [ -n "$DISPLAY_SERVICES" ]; then
    IFS=',' read -ra ORDERED_SERVICES <<< "$DISPLAY_SERVICES"
    
    # Parcourir les services dans l'ordre défini
    for service in "${ORDERED_SERVICES[@]}"; do
        service=$(echo "$service" | tr '[:upper:]' '[:lower:]' | xargs)
        if [[ -n "${SERVICES[$service]}" ]]; then
            formatGA "$service" "${SERVICES[$service]}"
        fi
    done
else
    # Si DISPLAY_SERVICES n'est pas défini, afficher tous les services
    for service in "${!SERVICES[@]}"; do
        formatGA "$service" "${SERVICES[$service]}"
    done
fi
