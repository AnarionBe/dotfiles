// ClockBlock.qml — heure et date en français.
//
// La locale est forcée explicitement : /etc/locale.conf dit fr_BE.UTF-8, mais
// l'environnement du greeter (uid sddm) n'hérite pas forcément de LANG.
//
// Largeur entièrement implicite (dérivée des Text) : ne jamais se lier à
// parent.width dans un Column, dont la largeur dérive déjà des enfants — ce
// serait une boucle de binding.

import QtQuick

Column {
    id: block

    property var theme

    spacing: 6

    readonly property var loc: Qt.locale(theme ? theme.localeName : "fr_FR")
    property date now: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: block.now = new Date()
    }

    // ─── Heure ────────────────────────────────────────────────────────────
    Item {
        id: timeRow
        width: timeText.implicitWidth
        height: timeText.implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter

        // Halo de lisibilité : un jumeau cyan très atténué, légèrement
        // agrandi. Pas d'ombre portée (désactivée dans tout le design
        // system), pas d'effet graphique.
        Text {
            anchors.centerIn: parent
            text: timeText.text
            color: block.theme ? block.theme.accent : "#00eaff"
            opacity: 0.18
            scale: 1.015
            font: timeText.font
            renderType: Text.NativeRendering
        }

        Text {
            id: timeText
            anchors.centerIn: parent
            text: block.now.toLocaleTimeString(block.loc,
                      block.theme ? block.theme.timeFormat : "HH:mm")
            color: block.theme ? block.theme.textPrimary : "#e6f1ff"
            font.family: block.theme ? block.theme.fontFamily : "JetBrainsMono Nerd Font"
            font.pixelSize: block.theme ? block.theme.fontSizeClock : 76
            font.weight: Font.Medium
            font.letterSpacing: 2
            renderType: Text.NativeRendering
        }
    }

    // ─── Date ─────────────────────────────────────────────────────────────
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
            var s = block.now.toLocaleDateString(block.loc,
                        block.theme ? block.theme.dateFormat : "dddd d MMMM yyyy")
            // Qt rend la date tout en minuscules en français.
            return s.length > 0 ? s.charAt(0).toUpperCase() + s.slice(1) : s
        }
        color: block.theme ? block.theme.textSecondary : "#9bb3d3"
        font.family: block.theme ? block.theme.fontFamily : "JetBrainsMono Nerd Font"
        font.pixelSize: block.theme ? block.theme.fontSizeDate : 14
        font.letterSpacing: 1.5
        renderType: Text.NativeRendering
    }

    // ─── Entrée : opacity 0→1 + translation verticale +18→0 ──────────────
    // On translate via `transform` et non via `y` : le Column parent gère
    // déjà la position y de ce bloc.
    property real enterOffset: 18
    transform: Translate { y: block.enterOffset }

    opacity: 0

    Component.onCompleted: enterAnim.start()

    ParallelAnimation {
        id: enterAnim

        NumberAnimation {
            target: block
            property: "opacity"
            from: 0
            to: 1
            duration: block.theme ? block.theme.durClockEnter : 420
            easing.type: Easing.Bezier
            easing.bezierCurve: block.theme ? block.theme.easeOutQuint
                                            : [0.23, 1.0, 0.32, 1.0, 1.0, 1.0]
        }

        NumberAnimation {
            target: block
            property: "enterOffset"
            from: 18
            to: 0
            duration: block.theme ? block.theme.durClockEnter : 420
            easing.type: Easing.Bezier
            easing.bezierCurve: block.theme ? block.theme.easeOutQuint
                                            : [0.23, 1.0, 0.32, 1.0, 1.0, 1.0]
        }
    }
}
