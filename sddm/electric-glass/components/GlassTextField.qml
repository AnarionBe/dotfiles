// GlassTextField.qml — champ de saisie en verre.
//
// TextInput brut, délibérément pas QtQuick.Controls : qqc2-desktop-style et
// qqc2-breeze-style sont installés sur cette machine, et si un paquet KDE
// déposait un /etc/xdg/qtquickcontrols2.conf avec Style=org.kde.desktop,
// org.kde.* reviendrait par la porte de derrière — exactement la panne qu'on
// fuit.
//
// Mise en page par ancres et non par Row : pas de calcul de largeur à la main.

import QtQuick

Rectangle {
    id: field

    property var theme
    property string placeholder: "Mot de passe"
    property bool isPassword: true
    property bool showReveal: true
    property string glyph: ""   // nf-fa-lock

    readonly property alias value: input.text
    readonly property bool inputFocus: input.activeFocus
    property bool errorState: false

    signal accepted()
    signal tabPressed()

    function clear() {
        input.text = ""
    }

    function focusInput() {
        input.forceActiveFocus()
    }

    function flashError() {
        errorState = true
        errorTimer.restart()
    }

    Timer {
        id: errorTimer
        interval: 1200
        onTriggered: field.errorState = false
    }

    height: theme ? theme.fieldHeight : 44
    radius: theme ? theme.fieldRadius : 10
    color: theme ? theme.glassField : "#b3101a2e"
    antialiasing: true
    border.width: theme ? theme.borderWidth : 2
    border.color: {
        if (errorState)
            return theme ? theme.errorColor : "#ff2e63"
        if (input.activeFocus)
            return theme ? theme.borderActive : "#ee00eaff"
        return theme ? theme.borderIdle : "#3300eaff"
    }

    Behavior on border.color {
        ColorAnimation { duration: field.theme ? field.theme.durMicro : 150 }
    }

    GlowFrame {
        baseRadius: field.radius
        spread: field.theme ? field.theme.glowSpread : 16
        glowColor: field.errorState
                   ? (field.theme ? field.theme.errorColor : "#ff2e63")
                   : (field.theme ? field.theme.accent : "#00eaff")
        intensity: (input.activeFocus || field.errorState) ? 0.9 : 0.0
        animDuration: field.theme ? field.theme.durMicro : 150
    }

    // Déclarée en premier, donc derrière le contenu : un clic dans le vide du
    // champ y ramène le focus, sans voler les clics du bouton œil.
    MouseArea {
        anchors.fill: parent
        onClicked: input.forceActiveFocus()
    }

    // ─── Glyphe ───────────────────────────────────────────────────────────
    Text {
        id: lockGlyph
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: field.glyph
        color: field.theme ? field.theme.accent : "#00eaff"
        font.family: field.theme ? field.theme.fontFamily : "JetBrainsMono Nerd Font"
        font.pixelSize: field.theme ? field.theme.fontSizeField : 13
        renderType: Text.NativeRendering
    }

    // ─── Bouton œil ───────────────────────────────────────────────────────
    Item {
        id: revealButton
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: visible ? 24 : 0
        height: 24
        visible: field.isPassword && field.showReveal

        property bool revealed: false

        Text {
            anchors.centerIn: parent
            // nf-fa-eye / nf-fa-eye_slash
            text: revealButton.revealed ? "" : ""
            color: revealArea.containsMouse
                   ? (field.theme ? field.theme.accentLight : "#3ddcff")
                   : (field.theme ? field.theme.textSecondary : "#9bb3d3")
            font.family: field.theme ? field.theme.fontFamily : "JetBrainsMono Nerd Font"
            font.pixelSize: field.theme ? field.theme.fontSizeField : 13
            renderType: Text.NativeRendering

            Behavior on color {
                ColorAnimation { duration: field.theme ? field.theme.durMicro : 150 }
            }
        }

        MouseArea {
            id: revealArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                revealButton.revealed = !revealButton.revealed
                input.forceActiveFocus()
            }
        }
    }

    // ─── Saisie ───────────────────────────────────────────────────────────
    TextInput {
        id: input

        anchors.left: lockGlyph.right
        anchors.leftMargin: 10
        anchors.right: revealButton.visible ? revealButton.left : parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        echoMode: (field.isPassword && !revealButton.revealed)
                  ? TextInput.Password
                  : TextInput.Normal
        passwordCharacter: "•"
        passwordMaskDelay: 0

        color: field.theme ? field.theme.textPrimary : "#e6f1ff"
        font.family: field.theme ? field.theme.fontFamily : "JetBrainsMono Nerd Font"
        font.pixelSize: field.theme ? field.theme.fontSizeField : 13

        selectByMouse: true
        selectionColor: field.theme ? field.theme.selection : "#4000eaff"
        selectedTextColor: field.theme ? field.theme.textPrimary : "#e6f1ff"

        inputMethodHints: Qt.ImhSensitiveData
                          | Qt.ImhNoPredictiveText
                          | Qt.ImhNoAutoUppercase

        clip: true
        renderType: Text.NativeRendering

        Keys.onReturnPressed: field.accepted()
        Keys.onEnterPressed: field.accepted()
        Keys.onTabPressed: field.tabPressed()

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text.length === 0
            text: field.placeholder
            color: field.theme ? field.theme.textDisabled : "#4b5668"
            font.family: input.font.family
            font.pixelSize: input.font.pixelSize
            renderType: Text.NativeRendering
        }
    }
}
