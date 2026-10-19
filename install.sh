#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Couleurs
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERR]${NC} $*"; }

# ---------- 1. Vérifier Arch Linux ----------
if [[ ! -f /etc/arch-release ]]; then
    error "Ce script est prévu pour Arch Linux uniquement."
    exit 1
fi
ok "Arch Linux détecté."

# ---------- 2. Installer yay si absent ----------
if ! command -v yay &>/dev/null; then
    info "Installation de yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    ok "yay installé."
else
    ok "yay déjà installé."
fi

# ---------- 3. Installer les paquets ----------
info "Installation des paquets depuis packages.txt..."
# Lire les paquets (ignorer commentaires et lignes vides)
mapfile -t packages < <(grep -v '^#' "$DOTFILES_DIR/packages.txt" | grep -v '^$')

yay -S --needed --noconfirm "${packages[@]}"
ok "Tous les paquets sont installés."

# ---------- 3b. Oh My Zsh + Powerlevel10k ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installation de Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "Oh My Zsh installé."
else
    ok "Oh My Zsh déjà installé."
fi

P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    info "Installation de Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    ok "Powerlevel10k installé."
else
    ok "Powerlevel10k déjà installé."
fi

# ---------- 3c. Zen Browser (Flatpak) ----------
if ! flatpak info app.zen_browser.zen &>/dev/null; then
    info "Installation de Zen Browser via Flatpak..."
    flatpak install -y flathub app.zen_browser.zen
    ok "Zen Browser installé."
else
    ok "Zen Browser déjà installé."
fi

# ---------- 3d. Docker ----------
if ! systemctl is-enabled docker.service &>/dev/null; then
    info "Activation du service Docker..."
    sudo systemctl enable --now docker.service
    ok "Docker activé."
else
    ok "Docker déjà activé."
fi

if ! groups | grep -q docker; then
    info "Ajout de l'utilisateur au groupe docker..."
    sudo usermod -aG docker "$USER"
    warn "Déconnectez-vous puis reconnectez-vous pour utiliser Docker sans sudo."
else
    ok "Utilisateur déjà dans le groupe docker."
fi

# ---------- 4. Créer les symlinks ----------
info "Mise en place des symlinks..."

declare -A LINKS=(
    ["$DOTFILES_DIR/hypr"]="$HOME/.config/hypr"
    ["$DOTFILES_DIR/dunst"]="$HOME/.config/dunst"
    ["$DOTFILES_DIR/rofi"]="$HOME/.config/rofi"
    ["$DOTFILES_DIR/waybar"]="$HOME/.config/waybar"
    ["$DOTFILES_DIR/alacritty"]="$HOME/.config/alacritty"
    ["$DOTFILES_DIR/kitty"]="$HOME/.config/kitty"
    ["$DOTFILES_DIR/zsh/.zshrc"]="$HOME/.zshrc"
    ["$DOTFILES_DIR/zsh/.p10k.zsh"]="$HOME/.p10k.zsh"
    ["$DOTFILES_DIR/zed"]="$HOME/.config/zed"
)

created=0
skipped=0
backed_up=0

for src in "${!LINKS[@]}"; do
    dest="${LINKS[$src]}"

    # Déjà un symlink correct → rien à faire
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
        ok "Symlink déjà en place : $dest"
        ((skipped++)) || true
        continue
    fi

    # Sauvegarder l'existant
    if [[ -e "$dest" || -L "$dest" ]]; then
        backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        warn "Sauvegarde de $dest → $backup"
        mv "$dest" "$backup"
        ((backed_up++)) || true
    fi

    # Créer le dossier parent si nécessaire
    mkdir -p "$(dirname "$dest")"

    ln -s "$src" "$dest"
    ok "Symlink créé : $dest → $src"
    ((created++)) || true
done

# ---------- 4b. Thème SDDM ----------
# Pas un symlink : le greeter tourne sous l'utilisateur `sddm`, qui ne peut pas
# traverser $HOME (0700). Le thème est donc copié en root par son propre script.
if [[ -x "$DOTFILES_DIR/sddm/install-sddm.sh" ]]; then
    info "Installation du thème SDDM Electric Glass..."
    sudo "$DOTFILES_DIR/sddm/install-sddm.sh"
else
    warn "sddm/install-sddm.sh introuvable, thème SDDM ignoré."
fi

# ---------- 5. Résumé ----------
echo ""
echo -e "${CYAN}══════════════════════════════════════${NC}"
echo -e "${CYAN}  Résumé de l'installation${NC}"
echo -e "${CYAN}══════════════════════════════════════${NC}"
echo -e "  Symlinks créés   : ${GREEN}${created}${NC}"
echo -e "  Symlinks existants: ${GREEN}${skipped}${NC}"
echo -e "  Backups effectués : ${YELLOW}${backed_up}${NC}"
echo -e "${CYAN}══════════════════════════════════════${NC}"
echo ""
ok "Installation terminée ! Redémarrez Hyprland pour appliquer les changements."
