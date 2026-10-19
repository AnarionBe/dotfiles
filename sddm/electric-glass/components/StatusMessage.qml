// StatusMessage.qml — message d'information, de succès ou d'erreur.
//
// La hauteur est réservée en permanence : l'apparition d'un message ne doit
// pas faire sauter la mise en page du panneau.

import QtQuick

Item {
    id: status

    property var theme

    // "info" | "success" | "error"
    property string level: "info"
    property string message: ""

    implicitHeight: 18
    height: implicitHeight

    function setInfo(msg) {
        level = "info"
        message = msg
    }

    function setSuccess(msg) {
        level = "success"
        message = msg
    }

    function setError(msg) {
        level = "error"
        message = msg
        shake.restart()
    }

    function clear() {
        message = ""
    }

    readonly property color levelColor: {
        if (!theme)
            return level === "error" ? "#ff2e63" : "#9bb3d3"
        if (level === "error")
            return theme.errorColor
        if (level === "success")
            return theme.accentLight
        return theme.textSecondary
    }

    Text {
        id: label
        // Pas d'anchors.centerIn : les ancres figeraient x, que la
        // secousse d'erreur doit pouvoir animer.
        anchors.verticalCenter: parent.verticalCenter
        width: status.width
        text: status.message
        color: status.levelColor
        opacity: status.message === "" ? 0 : 1
        font.family: status.theme ? status.theme.fontFamily : "JetBrainsMono Nerd Font"
        font.pixelSize: status.theme ? status.theme.fontSizeError : 11
        renderType: Text.NativeRendering
        elide: Text.ElideMiddle
        horizontalAlignment: Text.AlignHCenter

        Behavior on opacity {
            NumberAnimation { duration: status.theme ? status.theme.durMicro : 150 }
        }

        Behavior on color {
            ColorAnimation { duration: status.theme ? status.theme.durMicro : 150 }
        }
    }

    // Secousse latérale sur erreur : ± 6 px, 3 cycles de 60 ms.
    SequentialAnimation {
        id: shake

        NumberAnimation { target: label; property: "x"; to:  6; duration: 60; easing.type: Easing.OutQuad }
        NumberAnimation { target: label; property: "x"; to: -6; duration: 60; easing.type: Easing.OutQuad }
        NumberAnimation { target: label; property: "x"; to:  6; duration: 60; easing.type: Easing.OutQuad }
        NumberAnimation { target: label; property: "x"; to: -6; duration: 60; easing.type: Easing.OutQuad }
        NumberAnimation { target: label; property: "x"; to:  3; duration: 60; easing.type: Easing.OutQuad }
        NumberAnimation { target: label; property: "x"; to:  0; duration: 60; easing.type: Easing.OutQuad }
    }
}
