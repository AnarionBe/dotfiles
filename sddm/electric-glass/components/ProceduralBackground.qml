// ProceduralBackground.qml — fond entièrement généré, aucun fichier image.
//
// Quatre couches, de bas en haut :
//   1. dégradé de base (vertical + voile horizontal = effet diagonal)
//   2. halos cyan diffus, en respiration lente
//   3. grille technique fine
//   4. vignette, qui éteint la grille en périphérie
//
// Aucune clef `background=` dans theme.conf : SDDM tenterait de résoudre un
// chemin de fichier.

import QtQuick
import QtQuick.Shapes

Item {
    id: bg

    property var theme

    // Dégradé de base. Rectangle.gradient ne gère que vertical/horizontal :
    // la diagonale est obtenue par superposition des deux.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.00; color: "#0b1220" }
            GradientStop { position: 0.55; color: "#0d1526" }
            GradientStop { position: 1.00; color: "#101a2e" }
        }
    }

    Rectangle {
        anchors.fill: parent
        opacity: 0.55
        gradient: Gradient {
            orientation: Gradient.Horizontal
            // Même RGB des deux côtés, seul l'alpha varie : pas de liseré.
            GradientStop { position: 0.0; color: "#00101a2e" }
            GradientStop { position: 1.0; color: "#38101a2e" }
        }
    }

    // ─── Halos ────────────────────────────────────────────────────────────
    Item {
        id: halos
        anchors.fill: parent
        visible: bg.theme ? bg.theme.showHalos : true

        readonly property real shortSide: Math.min(bg.width, bg.height)

        opacity: 0
        Component.onCompleted: haloEnter.start()

        NumberAnimation {
            id: haloEnter
            target: halos
            property: "opacity"
            from: 0
            to: 1
            duration: 600
            easing.type: Easing.Bezier
            easing.bezierCurve: bg.theme ? bg.theme.easeOutQuint
                                         : [0.23, 1.0, 0.32, 1.0, 1.0, 1.0]
        }

        // Respiration : uniquement sur l'opacité d'un groupe, jamais sur la
        // géométrie — aucun recalcul de maillage.
        Item {
            id: breath
            anchors.fill: parent

            SequentialAnimation on opacity {
                running: true
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.85; duration: 6000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.85; to: 1.0; duration: 6000; easing.type: Easing.InOutSine }
            }

            CyanHalo {
                anchors.fill: parent
                cx: bg.width * 0.18
                cy: bg.height * 0.22
                glowRadius: halos.shortSide * 0.55
                glowColor: bg.theme ? bg.theme.accent : "#00eaff"
                intensity: 0.10
            }

            CyanHalo {
                anchors.fill: parent
                cx: bg.width * 0.82
                cy: bg.height * 0.78
                glowRadius: halos.shortSide * 0.65
                glowColor: bg.theme ? bg.theme.accentLight : "#3ddcff"
                intensity: 0.08
            }
        }

        // Lit lumineux sous le panneau de connexion : ne respire pas, pour ne
        // pas faire pulser la lisibilité du contenu.
        CyanHalo {
            anchors.fill: parent
            cx: bg.width * 0.50
            cy: bg.height * 0.46
            glowRadius: 420
            glowColor: bg.theme ? bg.theme.accent : "#00eaff"
            intensity: 0.07
        }
    }

    // ─── Grille ───────────────────────────────────────────────────────────
    GlowGrid {
        anchors.fill: parent
        visible: bg.theme ? bg.theme.showGrid : true
        cell: bg.theme ? bg.theme.gridCell : 64
        lineColor: bg.theme ? bg.theme.accent : "#00eaff"
    }

    // ─── Vignette ─────────────────────────────────────────────────────────
    Shape {
        anchors.fill: parent
        asynchronous: false

        ShapePath {
            strokeWidth: -1

            fillGradient: RadialGradient {
                centerX: bg.width / 2
                centerY: bg.height / 2
                centerRadius: Math.max(bg.width, bg.height) * 0.62
                focalX: bg.width / 2
                focalY: bg.height / 2

                GradientStop { position: 0.00; color: "#000b1220" }
                GradientStop { position: 0.60; color: "#1a0b1220" }
                GradientStop { position: 1.00; color: "#8c0b1220" }
            }

            startX: 0
            startY: 0
            PathLine { x: bg.width; y: 0 }
            PathLine { x: bg.width; y: bg.height }
            PathLine { x: 0;        y: bg.height }
            PathLine { x: 0;        y: 0 }
        }
    }
}
