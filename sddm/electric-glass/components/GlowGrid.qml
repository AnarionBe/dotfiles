// GlowGrid.qml — fine grille technique en arrière-plan.
//
// Simples Rectangle de 1 px : à 2560x1440 avec une maille de 64 px, cela fait
// une quarantaine de verticales et une vingtaine d'horizontales — négligeable,
// et le greeter n'a pas de compositeur pour l'aider.

import QtQuick

Item {
    id: grid

    property int cell: 64
    property color lineColor: "#00eaff"
    property real minorAlpha: 0.055
    property real majorAlpha: 0.09
    property int majorEvery: 4   // une ligne renforcée toutes les 4 mailles

    clip: true

    function lineAlpha(i) {
        return (i % grid.majorEvery === 0) ? grid.majorAlpha : grid.minorAlpha
    }

    Repeater {
        model: Math.max(0, Math.ceil(grid.width / grid.cell) + 1)

        Rectangle {
            x: index * grid.cell
            y: 0
            width: 1
            height: grid.height
            color: Qt.rgba(grid.lineColor.r, grid.lineColor.g,
                           grid.lineColor.b, grid.lineAlpha(index))
        }
    }

    Repeater {
        model: Math.max(0, Math.ceil(grid.height / grid.cell) + 1)

        Rectangle {
            x: 0
            y: index * grid.cell
            width: grid.width
            height: 1
            color: Qt.rgba(grid.lineColor.r, grid.lineColor.g,
                           grid.lineColor.b, grid.lineAlpha(index))
        }
    }
}
