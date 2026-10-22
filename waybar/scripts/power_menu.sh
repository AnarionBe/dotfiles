#!/usr/bin/env bash
# Menu d'alimentation rofi, ouvert depuis le module custom/power de waybar.
# Pendant du menu réseau (network_menu.sh).

set -uo pipefail

# Actions demandant une confirmation. Vider la variable pour tout exécuter
# directement au premier clic.
CONFIRM="logout reboot shutdown"

rofi_menu() {
    rofi -dmenu -i -format i -p "$1" -theme-str 'window { width: 420px; }'
}

# Les entrées inoffensives d'abord : la première ligne est présélectionnée.
labels=(
    "$(printf '  Mise en veille')"
    "$(printf '  Hibernation')"
    "$(printf '  Fermer la session')"
    "$(printf '  Redémarrer')"
    "$(printf '  Éteindre')"
)
actions=(suspend hibernate logout reboot shutdown)

declare -A commands=(
    [suspend]="systemctl suspend"
    [hibernate]="systemctl hibernate"
    [logout]="hyprctl dispatch hl.dsp.exit()"   # syntaxe Lua depuis Hyprland 0.56
    [reboot]="systemctl reboot"
    [shutdown]="systemctl poweroff"
)

choice=$(printf '%s\n' "${labels[@]}" | rofi_menu "Alimentation") || exit 0
[[ -z "$choice" ]] && exit 0

action=${actions[$choice]}
label=${labels[$choice]}
label=${label#* }   # libellé sans l'icône, pour la question de confirmation

if [[ " $CONFIRM " == *" $action "* ]]; then
    answer=$(printf '%s\n%s\n' \
        "$(printf '  Annuler')" \
        "$(printf '  Confirmer :%s' "$label")" |
        rofi_menu "Confirmer") || exit 0
    [[ "$answer" != "1" ]] && exit 0
fi

exec ${commands[$action]}
