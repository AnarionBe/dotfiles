# Thème SDDM — Electric Glass

Écran de connexion assorti au reste du bureau : glassmorphism cyan `#00eaff`,
fond procédural, JetBrainsMono Nerd Font.

## Pourquoi ce thème existe

Le 16/10/2026, la mise à jour `plasma-workspace 6.7.5-3 → 6.8.0-1` a supprimé
`VirtualKeyboardLoader.qml` du module QML `org.kde.breeze.components`. Le thème
EndeavourOS `eos-breeze` l'instancie à `Main.qml:305` :

```
sddm-greeter-qt6: .../eos-breeze/Main.qml:305:9: VirtualKeyboardLoader is not a type
sddm-greeter-qt6: Fallback to embedded theme
```

D'où l'écran gris minimal au démarrage.

Ce thème est écrit en **QtQuick pur**. Imports autorisés, et rien d'autre :

- `QtQuick`
- `QtQml`
- `QtQuick.Shapes` (dégradés radiaux du fond)

Tous fournis par `qt6-declarative` seul. Sont volontairement bannis :

| Interdit | Raison |
|---|---|
| `org.kde.*` | la panne qu'on fuit |
| `Qt5Compat.GraphicalEffects` | paquet `qt6-5compat`, installé seulement comme dépendance de Plasma → orphelinable |
| `QtQuick.Controls` | `qqc2-desktop-style` et `qqc2-breeze-style` sont installés ; un `/etc/xdg/qtquickcontrols2.conf` avec `Style=org.kde.desktop` ferait revenir `org.kde.*` par la porte de derrière |

Vérification empirique (modules réellement chargés par le processus) :

```bash
PID=$(pgrep -f '^/usr/bin/sddm-greeter-qt6' | head -1)
awk '{print $6}' /proc/$PID/maps | grep -c 'qml/org/kde'   # doit afficher 0
```

## Installation

```bash
sudo ~/Documents/dotfiles/sddm/install-sddm.sh
```

Le script vérifie `QtVersion=6`, refuse tout import interdit, copie le thème en
`root:root`, prouve que l'uid `sddm` peut le lire, puis installe
`/etc/sddm.conf.d/20-electric-glass.conf`.

**Copie, jamais symlink** : `/home/anarion` est en `0700` et le greeter tourne
sous l'utilisateur `sddm`. Un lien vers le home échouerait en `EACCES`.

SDDM ne recharge pas un thème à chaud :

```bash
sudo systemctl restart sddm   # ferme la session en cours
```

## Développement

```bash
./test-theme.sh          # greeter de test, sans sudo ni redémarrage
EG_TRACE=1 ./test-theme.sh   # + trace des imports QML
```

En mode test : `sddm.login()` est un no-op et `sddm.hostName` est vide, mais
`userModel`, `sessionModel` et `keyboard` sont réels. Le panneau n'apparaît que
sur l'écran principal (`primaryScreen`) ; les autres écrans ne reçoivent que le
fond.

## Configuration

Tout est paramétrable dans `electric-glass/theme.conf` : palette, opacités,
rayons, tailles de police, durées d'animation, et les bascules `showHalos`,
`showGrid`, `showSessionSelector`, `showCapsLockHint`, `showRevealButton`.

`Theme.qml` lit ces clefs avec un repli en dur pour chacune : une clef absente
ou mal orthographiée ne casse rien.

Le sélecteur de session **se masque automatiquement s'il n'y a qu'une seule
session** : il n'y aurait rien à choisir. Attention, SDDM filtre en amont les
sessions dont le `TryExec` est introuvable — c'est pourquoi
`hyprland-uwsm.desktop` n'apparaît pas tant que `uwsm` n'est pas installé.

## Rollback

Éditer, ne pas supprimer — supprimer le fichier ramènerait `eos-breeze`, cassé :

```bash
sudo sed -i 's/^Current=.*/Current=maldives/' /etc/sddm.conf.d/20-electric-glass.conf
sudo systemctl restart sddm
```

Levier maximal (`/etc/sddm.conf` a la précédence la plus haute et n'appartient
à aucun paquet) :

```bash
printf '[Theme]\nCurrent=maldives\n' | sudo tee /etc/sddm.conf
```

Dernier recours, depuis un TTY (`Ctrl+Alt+F2`) :

```bash
sudo systemctl disable --now sddm
Hyprland
```

## Pièges SDDM/QML rencontrés

1. **`QtVersion=6` est obligatoire** dans `metadata.desktop`. Sans lui, SDDM
   lance `/usr/bin/sddm-greeter`, lié à Qt 5.
2. **`keyboard.capsLockState` est une MÉTHODE, pas une propriété.** `if
   (keyboard.capsLockState)` teste l'objet fonction et vaut toujours vrai. Il
   faut l'appeler — et comme un appel ne crée pas de dépendance de binding,
   réévaluer sur le signal `capsLockStateChanged`.
3. **Syntaxe `Connections` Qt6** : `function onLoginFailed() {}`, jamais
   `onLoginFailed:`.
4. **`loginSucceeded()` et `loginFailed()` n'ont aucun paramètre** ; seul
   `informationMessage(message)` en a un.
5. **`sddm.login()` attend un index** de ligne de `sessionModel`, pas un nom.
6. **`userModel.lastUser` est une chaîne** (le nom d'utilisateur),
   `userModel.lastIndex` est l'index.
7. **Les rôles d'un modèle C++ ne sont pas lisibles par index** depuis QML : on
   passe par une sonde `Repeater` non visuelle (voir `Main.qml` et
   `SessionSelector.qml`).
8. **`easing.bezierCurve` attend SIX nombres** — les deux points de contrôle
   plus le point final `1,1`. Avec quatre, l'animation est silencieusement
   ignorée.
9. **`config.<clef>` renvoie une chaîne**, `undefined` si absente. Pour un
   booléen, comparer la chaîne, sinon le repli écrase un `false` explicite.
10. **`ThemeDir` est un chemin unique** : `~/.local/share/sddm/themes` n'est pas
    scanné par SDDM 0.21.
11. **SDDM capture toute la sortie Qt** : `console.log` n'apparaît ni sur stdout
    ni sur stderr en mode test. Pour instrumenter, afficher à l'écran.
12. **Ne jamais lier `width` à `parent.width` dans un `Column`** dont la largeur
    dérive déjà des enfants : boucle de binding.
13. **`anchors.centerIn` fige `x`** : un élément dont on veut animer `x` (la
    secousse d'erreur) ne doit pas être ancré horizontalement.
14. Le clavier virtuel de `InputMethod=qtvirtualkeyboard` (imposé par
    `10-endeavouros.conf`) s'affiche **par-dessus tout** dès qu'un champ prend le
    focus. `20-electric-glass.conf` le neutralise avec `InputMethod=`, qui est
    aussi la valeur par défaut amont.
