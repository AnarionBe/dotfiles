#!/usr/bin/env bash
# Lance le thème dans le greeter de test, sans redémarrer SDDM ni sudo.
#
# En mode test : sddm.login() est un no-op et canPowerOff vaut false, mais
# userModel, sessionModel et keyboard sont réels. Toute erreur QML part sur
# stderr — c'est là qu'on lit « ... is not a type » ou « Fallback to embedded
# theme ».
set -euo pipefail

THEME_DIR="$(cd "$(dirname "$0")" && pwd)/electric-glass"
LOG="${EG_LOG:-/tmp/eg-greeter.log}"

# qt6-wayland n'est pas installé : le greeter de test tourne en client X11 via
# XWayland, comme le vrai greeter.
export QT_QPA_PLATFORM=xcb

# Filet de sécurité : empêche toute résolution de style vers org.kde.desktop.
export QT_QUICK_CONTROLS_STYLE=Basic

if [[ "${EG_TRACE:-0}" == "1" ]]; then
    # Vérifie qu'AUCUN module org/kde n'est résolu — le test qui valide
    # l'objectif du projet.
    export QML_IMPORT_TRACE=1
fi

echo "Thème   : $THEME_DIR"
echo "Journal : $LOG"
echo

exec /usr/bin/sddm-greeter-qt6 --test-mode --theme "$THEME_DIR" 2>&1 | tee "$LOG"
