// GlassPanel.qml — le panneau de verre central.
//
// Bordure au repos = accent à 20 % ; bordure active = accent à 93 %, aligné
// sur col.active_border = rgba(00eaffee) dans hyprland.lua. Entrée en
// popin 87 %, comme l'animation windowsIn d'Hyprland.

import QtQuick

Rectangle {
    id: panel

    property var theme
    property bool highlighted: false

    radius: theme ? theme.panelRadius : 14
    color: theme ? theme.glassPanel : "#ae0b1220"
    antialiasing: true
    border.width: theme ? theme.borderWidth : 2
    border.color: highlighted
                  ? (theme ? theme.borderActive : "#ee00eaff")
                  : (theme ? theme.borderIdle : "#3300eaff")

    Behavior on border.color {
        ColorAnimation { duration: panel.theme ? panel.theme.durMicro : 150 }
    }

    GlowFrame {
        baseRadius: panel.radius
        spread: panel.theme ? panel.theme.glowSpread : 16
        glowColor: panel.theme ? panel.theme.accent : "#00eaff"
        intensity: panel.highlighted ? 1.0 : 0.5
        animDuration: panel.theme ? panel.theme.durMicro : 150
    }

    // ─── Entrée : opacity 0→1 + scale 0.87→1 (popin 87 %) ────────────────
    opacity: 0
    scale: 0.87
    transformOrigin: Item.Center

    Component.onCompleted: enterAnim.start()

    ParallelAnimation {
        id: enterAnim

        NumberAnimation {
            target: panel
            property: "opacity"
            from: 0
            to: 1
            duration: panel.theme ? panel.theme.durEnter : 380
            easing.type: Easing.Bezier
            easing.bezierCurve: panel.theme ? panel.theme.easeOutQuint
                                            : [0.23, 1.0, 0.32, 1.0, 1.0, 1.0]
        }

        NumberAnimation {
            target: panel
            property: "scale"
            from: 0.87
            to: 1.0
            duration: panel.theme ? panel.theme.durEnter : 380
            easing.type: Easing.Bezier
            easing.bezierCurve: panel.theme ? panel.theme.easeOutQuint
                                            : [0.23, 1.0, 0.32, 1.0, 1.0, 1.0]
        }
    }
}
