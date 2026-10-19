// Theme.qml — jetons de design du thème Electric Glass.
//
// Volontairement un QtObject simple, PAS un `pragma Singleton` : un singleton
// exigerait un fichier qmldir dans le dossier du thème, soit un mode de panne
// supplémentaire. Il est instancié une fois dans Main.qml et injecté dans chaque
// composant via `property Theme theme`.
//
// Toutes les valeurs sont lues depuis theme.conf via la propriété de contexte
// `config`, avec un repli en dur : `config.<clef>` renvoie une CHAÎNE, et
// `undefined` si la clef est absente.

import QtQml
import QtQuick

QtObject {
    id: tokens

    // ─── Accès sûr à theme.conf ───────────────────────────────────────────
    function str(key, fallback) {
        if (typeof config === "undefined")
            return fallback
        var v = config.stringValue(key)
        return (v === undefined || v === null || v === "") ? fallback : v
    }

    function num(key, fallback) {
        if (typeof config === "undefined")
            return fallback
        var v = config.realValue(key)
        // realValue() renvoie 0 sur clef absente ; aucun jeton numérique ici
        // ne vaut légitimement 0.
        return (v === undefined || v === null || isNaN(v) || v === 0) ? fallback : v
    }

    // Pour un booléen, comparer la chaîne : sinon un `false` explicite serait
    // écrasé par le repli.
    function flag(key, fallback) {
        if (typeof config === "undefined")
            return fallback
        var v = config.stringValue(key)
        if (v === undefined || v === null || v === "")
            return fallback
        return v === "true" || v === "1" || v === "yes"
    }

    // ─── Palette ──────────────────────────────────────────────────────────
    readonly property color accent:        str("accent",        "#00eaff")
    readonly property color accentLight:   str("accentLight",   "#3ddcff")
    readonly property color bgBase:        str("bgBase",        "#0b1220")
    readonly property color bgSurface:     str("bgSurface",     "#101a2e")
    readonly property color textPrimary:   str("textPrimary",   "#e6f1ff")
    readonly property color textSecondary: str("textSecondary", "#9bb3d3")
    readonly property color textTertiary:  str("textTertiary",  "#7aa2f7")
    readonly property color textDisabled:  str("textDisabled",  "#4b5668")
    readonly property color errorColor:    str("errorColor",    "#ff2e63")

    // ─── Opacités ─────────────────────────────────────────────────────────
    readonly property real panelOpacity: num("panelOpacity", 0.68)
    readonly property real fieldOpacity: num("fieldOpacity", 0.70)
    readonly property real popupOpacity: num("popupOpacity", 0.92)
    readonly property real badgeOpacity: num("badgeOpacity", 0.75)

    // ─── Géométrie ────────────────────────────────────────────────────────
    readonly property int panelRadius:    num("panelRadius",    14)
    readonly property int fieldRadius:    num("fieldRadius",    10)
    readonly property int buttonRadius:   num("buttonRadius",    8)
    readonly property int borderWidth:    num("borderWidth",     2)
    readonly property int glowSpread:     num("glowSpread",     16)
    readonly property int panelWidth:     num("panelWidth",    460)
    readonly property int fieldHeight:    num("fieldHeight",    44)
    readonly property int panelPadding:   num("panelPadding",   28)
    readonly property int contentSpacing: num("contentSpacing", 16)
    readonly property int clockGap:       num("clockGap",       48)

    // ─── Typographie ──────────────────────────────────────────────────────
    readonly property string fontFamily: str("fontFamily", "JetBrainsMono Nerd Font")
    readonly property int fontSizeClock: num("fontSizeClock", 76)
    readonly property int fontSizeDate:  num("fontSizeDate",  14)
    readonly property int fontSizeUser:  num("fontSizeUser",  15)
    readonly property int fontSizeHost:  num("fontSizeHost",  10)
    readonly property int fontSizeField: num("fontSizeField", 13)
    readonly property int fontSizeSmall: num("fontSizeSmall", 10)
    readonly property int fontSizeError: num("fontSizeError", 11)

    // ─── Animations ───────────────────────────────────────────────────────
    readonly property int durMicro:      num("durMicro",      150)
    readonly property int durEnter:      num("durEnter",      380)
    readonly property int durClockEnter: num("durClockEnter", 420)
    readonly property int durPopup:      num("durPopup",      180)
    readonly property int durPopupClose: num("durPopupClose", 120)

    // easeOutQuint — la courbe d'entrée d'Hyprland (bezier easeOutQuint
    // 0.23, 1, 0.32, 1). ATTENTION : easing.bezierCurve attend SIX nombres,
    // les deux points de contrôle PLUS le point final 1,1. Avec quatre
    // valeurs, l'animation est silencieusement ignorée.
    readonly property var easeOutQuint: [0.23, 1.0, 0.32, 1.0, 1.0, 1.0]

    // ─── Fonctionnalités ──────────────────────────────────────────────────
    readonly property bool showHalos:          flag("showHalos",          true)
    readonly property bool showGrid:            flag("showGrid",            true)
    readonly property int  gridCell:            num("gridCell",             64)
    readonly property bool showRevealButton:   flag("showRevealButton",   true)
    readonly property bool showSessionSelector: flag("showSessionSelector", true)
    readonly property bool showCapsLockHint:    flag("showCapsLockHint",    true)
    readonly property string localeName: str("localeName", "fr_FR")
    readonly property string dateFormat: str("dateFormat", "dddd d MMMM yyyy")
    readonly property string timeFormat: str("timeFormat", "HH:mm")

    // ─── Dérivés ──────────────────────────────────────────────────────────
    readonly property color glassPanel: Qt.rgba(bgBase.r, bgBase.g, bgBase.b, panelOpacity)
    readonly property color glassField: Qt.rgba(bgSurface.r, bgSurface.g, bgSurface.b, fieldOpacity)
    readonly property color glassPopup: Qt.rgba(bgSurface.r, bgSurface.g, bgSurface.b, popupOpacity)
    readonly property color glassBadge: Qt.rgba(bgSurface.r, bgSurface.g, bgSurface.b, badgeOpacity)

    // Bordure inactive = accent à 20 % (convention du design system) ;
    // bordure active = accent à 93 %, aligné sur
    // col.active_border = rgba(00eaffee) dans hyprland.lua.
    readonly property color borderIdle:   Qt.rgba(accent.r, accent.g, accent.b, 0.20)
    readonly property color borderActive: Qt.rgba(accent.r, accent.g, accent.b, 0.93)

    // Sélection = rgba(0, 234, 255, 0.25), comme rofi et waybar.
    readonly property color selection: Qt.rgba(accent.r, accent.g, accent.b, 0.25)

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}
