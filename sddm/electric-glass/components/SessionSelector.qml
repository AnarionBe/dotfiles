// SessionSelector.qml — choix de la session, volontairement discret.
//
// ListView + MouseArea, pas de QtQuick.Controls (voir GlassTextField).
//
// sddm.login() attend un INDEX de ligne de sessionModel, pas un nom. L'index
// initial est sessionModel.lastIndex, la dernière session utilisée.
//
// Les noms ne sont pas lisibles directement depuis un modèle C++ par index :
// une sonde Repeater non visuelle les expose.

import QtQuick

Item {
    id: selector

    property var theme
    property var sessions: null

    property int currentIndex: 0
    property string currentName: ""
    property bool popupOpen: false

    // Nombre de sessions réellement proposées par SDDM. Une session dont le
    // TryExec est introuvable est filtrée en amont (c'est le cas de
    // hyprland-uwsm tant que uwsm n'est pas installé).
    readonly property alias sessionCount: probe.count

    signal namesReady()

    implicitHeight: trigger.height
    height: implicitHeight

    // Permet d'atteindre le sélecteur au clavier depuis le champ (Tab).
    activeFocusOnTab: true

    function refreshName() {
        var item = probe.itemAt(currentIndex)
        currentName = item ? item.sessionName : ""
    }

    function open() {
        if (popup.count > 0)
            popupOpen = true
    }

    function close() {
        popupOpen = false
    }

    function toggle() {
        popupOpen ? close() : open()
    }

    function select(index) {
        currentIndex = index
        close()
    }

    onCurrentIndexChanged: refreshName()
    onNamesReady: refreshName()
    Component.onCompleted: refreshName()

    // ─── Sonde : expose les noms du modèle par index ──────────────────────
    Repeater {
        id: probe
        model: selector.sessions

        Item {
            visible: false
            readonly property string sessionName: (model.name !== undefined) ? model.name : ""
            Component.onCompleted: selector.namesReady()
        }
    }

    // ─── Déclencheur compact ──────────────────────────────────────────────
    Row {
        id: trigger
        anchors.horizontalCenter: parent.horizontalCenter
        height: 28
        spacing: 7

        readonly property color activeColor: triggerArea.containsMouse
                                             || selector.popupOpen
                                             || selector.activeFocus
                                             ? (selector.theme ? selector.theme.accentLight : "#3ddcff")
                                             : (selector.theme ? selector.theme.textSecondary : "#9bb3d3")

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""   // nf-fa-desktop
            color: trigger.activeColor
            font.family: selector.theme ? selector.theme.fontFamily : "JetBrainsMono Nerd Font"
            font.pixelSize: selector.theme ? selector.theme.fontSizeSmall : 10
            renderType: Text.NativeRendering
            Behavior on color { ColorAnimation { duration: selector.theme ? selector.theme.durMicro : 150 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: selector.currentName !== "" ? selector.currentName : "Session"
            color: trigger.activeColor
            font.family: selector.theme ? selector.theme.fontFamily : "JetBrainsMono Nerd Font"
            font.pixelSize: selector.theme ? selector.theme.fontSizeSmall : 10
            font.letterSpacing: 0.5
            renderType: Text.NativeRendering
            Behavior on color { ColorAnimation { duration: selector.theme ? selector.theme.durMicro : 150 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""   // nf-fa-chevron_down
            color: trigger.activeColor
            font.family: selector.theme ? selector.theme.fontFamily : "JetBrainsMono Nerd Font"
            font.pixelSize: (selector.theme ? selector.theme.fontSizeSmall : 10) - 2
            rotation: selector.popupOpen ? 180 : 0
            renderType: Text.NativeRendering
            Behavior on rotation { NumberAnimation { duration: selector.theme ? selector.theme.durMicro : 150 } }
            Behavior on color { ColorAnimation { duration: selector.theme ? selector.theme.durMicro : 150 } }
        }
    }

    MouseArea {
        id: triggerArea
        anchors.fill: trigger
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: selector.toggle()
    }

    Keys.onUpPressed:     if (selector.currentIndex > 0) selector.currentIndex -= 1
    Keys.onDownPressed:   if (selector.currentIndex < probe.count - 1) selector.currentIndex += 1
    Keys.onReturnPressed: selector.toggle()
    Keys.onEnterPressed:  selector.toggle()
    Keys.onEscapePressed: selector.close()
    Keys.onSpacePressed:  selector.toggle()

    // ─── Popup ────────────────────────────────────────────────────────────
    Rectangle {
        id: popup

        readonly property int rowHeight: 32
        readonly property alias count: list.count

        anchors.horizontalCenter: parent.horizontalCenter
        y: trigger.height + 8
        z: 100

        width: Math.max(220, trigger.width + 60)
        height: Math.min(6, Math.max(1, list.count)) * rowHeight + 12

        radius: selector.theme ? selector.theme.fieldRadius : 10
        color: selector.theme ? selector.theme.glassPopup : "#eb101a2e"
        antialiasing: true
        border.width: selector.theme ? selector.theme.borderWidth : 2
        border.color: selector.theme ? selector.theme.borderIdle : "#3300eaff"

        visible: opacity > 0.01
        opacity: selector.popupOpen ? 1 : 0
        scale: selector.popupOpen ? 1.0 : 0.87
        transformOrigin: Item.Top

        GlowFrame {
            baseRadius: popup.radius
            spread: selector.theme ? selector.theme.glowSpread : 16
            glowColor: selector.theme ? selector.theme.accent : "#00eaff"
            intensity: 0.6
        }

        // Ouverture en popin 87 % ; fermeture linéaire, comme
        // windowsOut, linear, popin 87% dans hyprland.lua.
        Behavior on opacity {
            NumberAnimation {
                duration: selector.popupOpen
                          ? (selector.theme ? selector.theme.durPopup : 180)
                          : (selector.theme ? selector.theme.durPopupClose : 120)
                easing.type: selector.popupOpen ? Easing.Bezier : Easing.Linear
                easing.bezierCurve: selector.theme ? selector.theme.easeOutQuint
                                                   : [0.23, 1.0, 0.32, 1.0, 1.0, 1.0]
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: selector.popupOpen
                          ? (selector.theme ? selector.theme.durPopup : 180)
                          : (selector.theme ? selector.theme.durPopupClose : 120)
                easing.type: selector.popupOpen ? Easing.Bezier : Easing.Linear
                easing.bezierCurve: selector.theme ? selector.theme.easeOutQuint
                                                   : [0.23, 1.0, 0.32, 1.0, 1.0, 1.0]
            }
        }

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            model: selector.sessions
            interactive: contentHeight > height
            currentIndex: selector.currentIndex

            delegate: Rectangle {
                width: list.width
                height: popup.rowHeight
                radius: selector.theme ? selector.theme.fieldRadius : 10
                antialiasing: true

                readonly property bool active: index === selector.currentIndex
                                               || rowArea.containsMouse

                color: active
                       ? (selector.theme ? selector.theme.selection : "#4000eaff")
                       : "transparent"
                border.width: active ? 1 : 0
                border.color: selector.theme ? selector.theme.accent : "#00eaff"

                Behavior on color {
                    ColorAnimation { duration: selector.theme ? selector.theme.durMicro : 150 }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: (model.name !== undefined) ? model.name : ""
                    color: parent.active
                           ? (selector.theme ? selector.theme.accent : "#00eaff")
                           : (selector.theme ? selector.theme.textSecondary : "#9bb3d3")
                    font.family: selector.theme ? selector.theme.fontFamily : "JetBrainsMono Nerd Font"
                    font.pixelSize: selector.theme ? selector.theme.fontSizeSmall : 10
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: selector.select(index)
                }
            }
        }
    }
}
