// UserBadge.qml — pastille d'identité.
//
// Pas d'avatar : il n'existe aucun /usr/share/sddm/faces/anarion.face.icon, et
// /home/anarion est en 0700 — l'uid sddm ne peut pas le traverser. On affiche
// donc l'initiale. Pour un vrai avatar, déposer un PNG en
// /usr/share/sddm/faces/<utilisateur>.face.icon (root:root 0644).

import QtQuick

Column {
    id: badge

    property var theme
    property string userName: ""
    property string displayName: ""
    property string hostName: ""

    spacing: 10

    readonly property string label: displayName !== "" ? displayName : userName

    Rectangle {
        id: disc
        width: 72
        height: 72
        radius: width / 2
        anchors.horizontalCenter: parent.horizontalCenter
        color: badge.theme ? badge.theme.glassBadge : "#bf101a2e"
        antialiasing: true
        border.width: badge.theme ? badge.theme.borderWidth : 2
        border.color: badge.theme ? badge.theme.alpha(badge.theme.accent, 0.6) : "#9900eaff"

        GlowFrame {
            baseRadius: disc.radius
            spread: badge.theme ? badge.theme.glowSpread : 16
            glowColor: badge.theme ? badge.theme.accent : "#00eaff"
            intensity: 0.4
        }

        Text {
            anchors.centerIn: parent
            text: badge.label.length > 0 ? badge.label.charAt(0).toUpperCase() : "?"
            color: badge.theme ? badge.theme.accent : "#00eaff"
            font.family: badge.theme ? badge.theme.fontFamily : "JetBrainsMono Nerd Font"
            font.pixelSize: 28
            font.bold: true
            renderType: Text.NativeRendering
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: badge.label !== ""
        text: badge.label
        color: badge.theme ? badge.theme.textPrimary : "#e6f1ff"
        font.family: badge.theme ? badge.theme.fontFamily : "JetBrainsMono Nerd Font"
        font.pixelSize: badge.theme ? badge.theme.fontSizeUser : 15
        renderType: Text.NativeRendering
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: badge.hostName !== ""
        text: badge.hostName
        color: badge.theme ? badge.theme.textSecondary : "#9bb3d3"
        font.family: badge.theme ? badge.theme.fontFamily : "JetBrainsMono Nerd Font"
        font.pixelSize: badge.theme ? badge.theme.fontSizeHost : 10
        font.letterSpacing: 1
        renderType: Text.NativeRendering
    }
}
