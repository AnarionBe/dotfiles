# Dotfiles - Hyprland Glassmorphism Cyan

Dotfiles pour Arch Linux + Hyprland avec un thème glassmorphism cyan/bleu electrique.

## Apercu

| Composant | Config |
|---|---|
| WM | Hyprland (blur, opacity, borders cyan) |
| Barre | Waybar |
| Notifications | Dunst |
| Lanceur | Rofi (Wayland) |
| Terminaux | Alacritty, Kitty |
| Editeur | Zed (theme ElectricGlass) |
| Navigateur | Zen Browser (Flatpak) |
| Shell | Zsh + Oh My Zsh + Powerlevel10k |
| Police | JetBrains Mono Nerd Font |
| Icones | Papirus |

## Structure

```
dotfiles/
├── install.sh            # Script d'installation
├── packages.txt          # Liste des paquets (pacman/AUR)
├── hypr/                 # ~/.config/hypr/
│   └── hyprland.conf
├── waybar/               # ~/.config/waybar/
│   ├── config.jsonc
│   ├── style.css
│   └── colors.css
├── dunst/                # ~/.config/dunst/
│   └── dunstrc
├── rofi/                 # ~/.config/rofi/
│   ├── config.rasi
│   └── theme.rasi
├── alacritty/            # ~/.config/alacritty/
│   └── alacritty.toml
├── kitty/                # ~/.config/kitty/
│   └── kitty.conf
├── zed/                  # ~/.config/zed/
│   ├── settings.json
│   └── themes/
│       └── electric-glass.json
└── zsh/                  # ~/
    ├── .zshrc
    └── .p10k.zsh
```

## Installation

```bash
git clone <repo-url> ~/Documents/dotfiles
cd ~/Documents/dotfiles
chmod +x install.sh
./install.sh
```

Le script effectue dans l'ordre :

1. Verifie qu'on est sur Arch Linux
2. Installe `yay` (AUR helper) si absent
3. Installe tous les paquets depuis `packages.txt`
4. Installe Oh My Zsh + Powerlevel10k
5. Installe Zen Browser via Flatpak
6. Active Docker et ajoute l'utilisateur au groupe `docker`
7. Cree les symlinks (avec backup `.bak` des configs existantes)

Le script est **idempotent** : il peut etre relance sans risque.

## Symlinks

Apres installation, les configs pointent vers ce repo :

| Symlink | Cible |
|---|---|
| `~/.config/hypr` | `dotfiles/hypr` |
| `~/.config/waybar` | `dotfiles/waybar` |
| `~/.config/dunst` | `dotfiles/dunst` |
| `~/.config/rofi` | `dotfiles/rofi` |
| `~/.config/alacritty` | `dotfiles/alacritty` |
| `~/.config/kitty` | `dotfiles/kitty` |
| `~/.config/zed` | `dotfiles/zed` |
| `~/.zshrc` | `dotfiles/zsh/.zshrc` |
| `~/.p10k.zsh` | `dotfiles/zsh/.p10k.zsh` |

Toute modification dans le repo est immediatement appliquee.

## Aliases shell

Les outils modernes remplacent les commandes classiques :

| Alias | Commande reelle |
|---|---|
| `cat` | `bat --paging=never` |
| `less` | `bat` |
| `ls` | `eza --icons` |
| `ll` | `eza -lh --icons --git` |
| `la` | `eza -lah --icons --git` |
| `lt` / `tree` | `eza --tree --icons` |
| `top` | `btop` |
| `grep` | `rg` (ripgrep) |
| `find` | `fd` |

## Raccourcis Hyprland

| Raccourci | Action |
|---|---|
| `Super + T` | Terminal (Alacritty) |
| `Super + E` | Gestionnaire de fichiers (Dolphin) |
| `Super + R` | Lanceur d'apps (Rofi) |
| `Super + Q` | Fermer la fenetre |
| `Super + V` | Basculer flottant |
| `Super + S` | Scratchpad |
| `Super + 1-9` | Changer de workspace |
| `Super + Shift + 1-9` | Deplacer vers workspace |
| `Super + M` | Quitter Hyprland |

## Ajouter une config

1. Copier le dossier de config dans le repo :
   ```bash
   cp -r ~/.config/monapp dotfiles/monapp
   ```
2. Ajouter l'entree dans le tableau `LINKS` de `install.sh` :
   ```bash
   ["$DOTFILES_DIR/monapp"]="$HOME/.config/monapp"
   ```
3. Ajouter les paquets associes dans `packages.txt`
4. Lancer `./install.sh` pour creer le symlink

## Restaurer apres un reset

```bash
# 1. Installer git
sudo pacman -S git

# 2. Cloner le repo
git clone <repo-url> ~/Documents/dotfiles

# 3. Lancer l'installation
cd ~/Documents/dotfiles && ./install.sh

# 4. Changer le shell par defaut
chsh -s /usr/bin/zsh

# 5. Redemarrer
reboot
```
