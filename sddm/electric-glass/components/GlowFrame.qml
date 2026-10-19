// GlowFrame.qml — le glow cyan signature du design system.
//
// Reproduit `box-shadow: 0 0 12px #00eaff` (waybar, gtk.css) SANS ombre portée
// — les ombres sont désactivées dans Hyprland, le relief vient du glow — et
// sans MultiEffect, pour ne dépendre que de QtQuick.
//
// Des anneaux concentriques dont l'alpha décroît quadratiquement donnent un
// rendu très proche d'un flou gaussien, pour un coût négligeable.
//
// À placer en enfant de l'élément à faire rayonner : z négatif pour passer
// derrière le fond du parent. Le parent ne doit pas avoir clip: true.

import QtQuick

Item {
    id: glow

    property real baseRadius: 14
    property real spread: 16
    property color glowColor: "#00eaff"
    property real peakAlpha: 0.20
    property int steps: 10

    // 0 = éteint, 1 = pleine intensité. Animé pour l'allumage au focus.
    property real intensity: 1.0
    property int animDuration: 150

    anchors.fill: parent
    z: -1
    opacity: Math.max(0, Math.min(1, intensity))
    visible: opacity > 0.001

    readonly property real stepSize: spread / steps

    Behavior on intensity {
        NumberAnimation {
            duration: glow.animDuration
            easing.type: Easing.OutQuad
        }
    }

    Repeater {
        model: glow.steps

        Rectangle {
            anchors.fill: parent
            anchors.margins: -(index + 1) * glow.stepSize
            radius: glow.baseRadius + (index + 1) * glow.stepSize
            color: "transparent"
            antialiasing: true
            border.width: Math.max(1, glow.stepSize)
            // Décroissance quadratique : dense près du bord, nulle au loin.
            border.color: Qt.rgba(glow.glowColor.r, glow.glowColor.g, glow.glowColor.b,
                                  glow.peakAlpha * Math.pow(1 - index / glow.steps, 2))
        }
    }
}
