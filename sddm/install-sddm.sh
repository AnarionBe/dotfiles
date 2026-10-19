#!/usr/bin/env bash
# Déploie le thème SDDM Electric Glass et sa surcharge de configuration.
#
# COPIE, jamais symlink : /home/anarion est en 0700 et le greeter tourne sous
# l'utilisateur `sddm`. Un lien vers le home échouerait en EACCES au chargement,
# et SDDM retomberait sur son thème embarqué — l'écran gris.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$DOTFILES_DIR/sddm/electric-glass"
DEST="/usr/share/sddm/themes/electric-glass"
CONF_SRC="$DOTFILES_DIR/sddm/20-electric-glass.conf"
CONF_DEST="/etc/sddm.conf.d/20-electric-glass.conf"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERR]${NC} $*"; }

if [[ $EUID -ne 0 ]]; then
    error "Ce script doit être lancé avec sudo."
    echo "  sudo $0"
    exit 1
fi

[[ -d "$SRC" ]] || { error "Thème introuvable : $SRC"; exit 1; }

# ---------- 1. Garde-fou : QtVersion=6 ----------
# Sans cette clef, SDDM lance /usr/bin/sddm-greeter, qui est lié à Qt 5 :
# notre QML Qt6 échouerait au chargement.
if ! grep -q '^QtVersion=6$' "$SRC/metadata.desktop"; then
    error "QtVersion=6 absent de metadata.desktop — SDDM lancerait le greeter Qt5."
    exit 1
fi
ok "QtVersion=6 présent."

# ---------- 2. Garde-fou : aucun import interdit ----------
# C'est la raison d'être de ce thème : ne dépendre d'aucun module KDE, dont la
# disparition a cassé eos-breeze lors du passage à Plasma 6.8.
if grep -rnE '^[[:space:]]*import[[:space:]]+(org\.kde|Qt5Compat|QtQuick\.Controls)' "$SRC"; then
    error "Import interdit détecté (org.kde / Qt5Compat / QtQuick.Controls)."
    exit 1
fi
ok "Aucun import org.kde, Qt5Compat ou QtQuick.Controls."

# ---------- 3. Déploiement ----------
info "Copie de $SRC vers $DEST..."
install -d -m 0755 -o root -g root "$DEST"

if command -v rsync &>/dev/null; then
    rsync -a --delete --chown=root:root --chmod=D0755,F0644 "$SRC"/ "$DEST"/
else
    warn "rsync absent, repli sur cp."
    rm -rf "${DEST:?}"/*
    cp -a "$SRC"/. "$DEST"/
    chown -R root:root "$DEST"
    find "$DEST" -type d -exec chmod 0755 {} +
    find "$DEST" -type f -exec chmod 0644 {} +
fi
ok "Thème déployé."

# ---------- 4. Preuve de lisibilité par l'uid sddm ----------
# Une vérification, pas une supposition : c'est ce processus-là qui lira le QML.
if setpriv --reuid=sddm --regid=sddm --clear-groups \
        cat "$DEST/Main.qml" >/dev/null 2>&1; then
    ok "Lisible par l'utilisateur sddm."
else
    error "L'utilisateur sddm ne peut pas lire $DEST/Main.qml."
    exit 1
fi

# ---------- 5. Surcharge de configuration ----------
# 20- passe après 10-endeavouros.conf (eos-breeze-sddm), qui n'est pas un
# fichier de sauvegarde pacman et sera réécrit sans .pacnew à chaque MAJ.
info "Installation de $CONF_DEST..."
install -D -m 0644 -o root -g root "$CONF_SRC" "$CONF_DEST"
ok "Configuration installée."

current=$(grep -E '^Current=' "$CONF_DEST" | tail -1 | cut -d= -f2)
echo ""
echo -e "${CYAN}══════════════════════════════════════${NC}"
echo -e "  Thème actif    : ${GREEN}${current}${NC}"
echo -e "  Thème installé : ${GREEN}${DEST}${NC}"
echo -e "${CYAN}══════════════════════════════════════${NC}"
echo ""
warn "SDDM ne recharge pas un thème à chaud."
warn "Appliquer au prochain démarrage, ou : sudo systemctl restart sddm"
warn "(ce redémarrage ferme la session en cours)."
