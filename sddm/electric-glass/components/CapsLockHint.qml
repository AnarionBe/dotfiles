// CapsLockHint.qml — avertissement de verrouillage majuscules.
//
// keyboard.capsLockState est fiable ici : le greeter tourne en X11, donc
// SDDM utilise XcbKeyboardBackend.

import QtQuick

Item {
    id: hint

    property var theme
    property bool active: false

    implicitHeight: 14
    height: implicitHeight
    opacity: active ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: hint.theme ? hint.theme.durMicro : 150 }
    }

    Row {
        anchors.centerIn: parent
        spacing: 6

        Text {
            // nf-fa-warning ; repli "!" si le glyphe manque.
            text: ""
            color: hint.theme ? hint.theme.errorColor : "#ff2e63"
            font.family: hint.theme ? hint.theme.fontFamily : "JetBrainsMono Nerd Font"
            font.pixelSize: hint.theme ? hint.theme.fontSizeSmall : 10
            renderType: Text.NativeRendering
        }

        Text {
            text: "Verrouillage majuscules actif"
            color: hint.theme ? hint.theme.errorColor : "#ff2e63"
            font.family: hint.theme ? hint.theme.fontFamily : "JetBrainsMono Nerd Font"
            font.pixelSize: hint.theme ? hint.theme.fontSizeSmall : 10
            font.letterSpacing: 0.5
            renderType: Text.NativeRendering
        }
    }
}
