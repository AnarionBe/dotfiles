// GlowButton.qml — bouton carré à glyphe, rayon 8 px (rayon « boutons » du
// design system, cf. gtk.css).

import QtQuick

Rectangle {
    id: button

    property var theme
    property string glyph: ""   // nf-fa-arrow_right
    property real glyphSize: 14

    signal clicked()

    width: 36
    height: 36
    radius: theme ? theme.buttonRadius : 8
    antialiasing: true

    readonly property bool hovered: area.containsMouse
    readonly property bool pressedDown: area.pressed

    color: theme
           ? theme.alpha(theme.accent, pressedDown ? 0.36 : (hovered ? 0.28 : 0.15))
           : "#2600eaff"
    border.width: theme ? theme.borderWidth : 2
    border.color: theme
                  ? theme.alpha(theme.accent, hovered ? 1.0 : 0.5)
                  : "#8000eaff"

    Behavior on color {
        ColorAnimation { duration: button.theme ? button.theme.durMicro : 150 }
    }

    Behavior on border.color {
        ColorAnimation { duration: button.theme ? button.theme.durMicro : 150 }
    }

    GlowFrame {
        baseRadius: button.radius
        spread: button.theme ? button.theme.glowSpread : 16
        glowColor: button.theme ? button.theme.accent : "#00eaff"
        intensity: button.hovered ? 0.9 : 0.0
        animDuration: button.theme ? button.theme.durMicro : 150
    }

    Text {
        anchors.centerIn: parent
        text: button.glyph
        color: button.theme ? button.theme.accent : "#00eaff"
        font.family: button.theme ? button.theme.fontFamily : "JetBrainsMono Nerd Font"
        font.pixelSize: button.glyphSize
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
