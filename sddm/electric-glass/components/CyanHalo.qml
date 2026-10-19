// CyanHalo.qml — un halo radial diffus, généré (aucun fichier image).
//
// QtQuick.Shapes fournit RadialGradient ; Rectangle.gradient ne gère que le
// linéaire. Qt5Compat.GraphicalEffects est volontairement évité : son paquet
// (qt6-5compat) n'est installé ici que comme dépendance de Plasma, donc
// orphelinable.

import QtQuick
import QtQuick.Shapes

Item {
    id: halo

    property real cx: width / 2
    property real cy: height / 2
    property real glowRadius: 400
    property color glowColor: "#00eaff"
    property real intensity: 0.10

    Shape {
        anchors.fill: parent
        asynchronous: false

        ShapePath {
            strokeWidth: -1   // -1 = aucun contour en Qt Quick Shapes

            fillGradient: RadialGradient {
                centerX: halo.cx
                centerY: halo.cy
                centerRadius: halo.glowRadius
                focalX: halo.cx
                focalY: halo.cy

                GradientStop {
                    position: 0.0
                    color: Qt.rgba(halo.glowColor.r, halo.glowColor.g,
                                   halo.glowColor.b, halo.intensity)
                }
                GradientStop {
                    position: 0.45
                    color: Qt.rgba(halo.glowColor.r, halo.glowColor.g,
                                   halo.glowColor.b, halo.intensity * 0.45)
                }
                // Alpha nul en gardant le même RGB : évite le liseré sombre
                // dû à la prémultiplication.
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(halo.glowColor.r, halo.glowColor.g,
                                   halo.glowColor.b, 0.0)
                }
            }

            startX: 0
            startY: 0
            PathLine { x: halo.width; y: 0 }
            PathLine { x: halo.width; y: halo.height }
            PathLine { x: 0;          y: halo.height }
            PathLine { x: 0;          y: 0 }
        }
    }
}
