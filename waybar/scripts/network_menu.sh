#!/usr/bin/env bash
# Menu réseau rofi, ouvert depuis le module network de waybar.
# Liste les réseaux Wi-Fi à portée, connecte / déconnecte, bascule la radio.

set -uo pipefail

notify() { notify-send -a "Réseau" "$1" "${2:-}"; }

wifi_dev=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2 == "wifi" { print $1; exit }')
radio=$(nmcli -t -f WIFI radio)

if [[ -n "$wifi_dev" ]]; then
    active=$(nmcli -t -f GENERAL.CONNECTION device show "$wifi_dev" | cut -d: -f2-)
else
    active=""
fi

# Icône de force du signal (Nerd Font, md-wifi-strength).
signal_icon() {
    local s="$1"
    if   (( s >= 75 )); then printf '\U000f0928'
    elif (( s >= 50 )); then printf '\U000f0925'
    elif (( s >= 25 )); then printf '\U000f0922'
    else                     printf '\U000f092f'
    fi
}

labels=()
actions=()

add() { labels+=("$1"); actions+=("$2"); }

declare -A seen_ssid=()
rest_labels=()
rest_actions=()
top_label=""
top_action=""

if [[ "$radio" == "enabled" && -n "$wifi_dev" ]]; then
    # SSID peut contenir des « : » échappés par nmcli : on lit les champs
    # fixes par la droite et tout ce qui précède forme le SSID.
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        security=${line##*:}
        rest=${line%:*}
        signal=${rest##*:}
        ssid=${rest%:*}
        ssid=${ssid//\\:/:}

        [[ -z "$ssid" ]] && continue                 # réseaux masqués
        [[ "$signal" =~ ^[0-9]+$ ]] || continue
        [[ -n "${seen_ssid[$ssid]:-}" ]] && continue  # même SSID, plusieurs bornes
        seen_ssid[$ssid]=1

        lock=""
        [[ -n "$security" ]] && lock=" "
        mark="  "
        [[ "$ssid" == "$active" ]] && mark=" "

        label=$(printf "%b%s  %s  %3s%%%b" "$mark" "$(signal_icon "$signal")" "$ssid" "$signal" "$lock")

        # Le réseau connecté passe en tête, les autres suivent par signal.
        if [[ "$ssid" == "$active" ]]; then
            top_label="$label"
            top_action="connect:$ssid:$security"
        else
            rest_labels+=("$label")
            rest_actions+=("connect:$ssid:$security")
        fi
    done < <(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list --rescan auto |
             sort -t: -k2 -nr)

    [[ -n "$top_label" ]] && add "$top_label" "$top_action"
    for i in "${!rest_labels[@]}"; do
        add "${rest_labels[$i]}" "${rest_actions[$i]}"
    done
fi

[[ -n "$active" ]] && add "$(printf '  Se déconnecter de %s' "$active")" "disconnect"

if [[ "$radio" == "enabled" ]]; then
    add "$(printf '\U000f092e  Désactiver le Wi-Fi')" "radio:off"
    add "$(printf '  Rechercher les réseaux')" "rescan"
else
    add "$(printf '  Activer le Wi-Fi')" "radio:on"
fi

add "$(printf '  Paramètres réseau')" "settings"

choice=$(printf '%s\n' "${labels[@]}" |
    rofi -dmenu -i -format i -p "Réseau" -theme-str 'window { width: 520px; }') || exit 0
[[ -z "$choice" ]] && exit 0

action=${actions[$choice]}

case "$action" in
    disconnect)
        nmcli connection down id "$active" >/dev/null 2>&1 &&
            notify "Déconnecté" "$active" ||
            notify "Échec de la déconnexion" "$active"
        ;;
    radio:off)
        nmcli radio wifi off && notify "Wi-Fi désactivé"
        ;;
    radio:on)
        nmcli radio wifi on && notify "Wi-Fi activé"
        ;;
    rescan)
        nmcli device wifi rescan >/dev/null 2>&1
        exec "$0"
        ;;
    settings)
        setsid -f nm-connection-editor >/dev/null 2>&1
        ;;
    connect:*)
        rest=${action#connect:}
        ssid=${rest%:*}
        security=${rest##*:}

        if [[ "$ssid" == "$active" ]]; then
            exit 0
        fi

        # Connexion déjà enregistrée : pas besoin du mot de passe.
        if nmcli -t -f NAME connection show | grep -qxF "$ssid"; then
            if nmcli connection up id "$ssid" >/dev/null 2>&1; then
                notify "Connecté" "$ssid"
            else
                notify "Échec de la connexion" "$ssid"
            fi
            exit 0
        fi

        if [[ -n "$security" ]]; then
            password=$(rofi -dmenu -password -p "Mot de passe" \
                -mesg "$ssid" -theme-str 'window { width: 420px; }') || exit 0
            [[ -z "$password" ]] && exit 0
            out=$(nmcli device wifi connect "$ssid" password "$password" 2>&1)
        else
            out=$(nmcli device wifi connect "$ssid" 2>&1)
        fi

        if [[ $? -eq 0 ]]; then
            notify "Connecté" "$ssid"
        else
            notify "Échec de la connexion" "${out##*Error: }"
        fi
        ;;
esac
