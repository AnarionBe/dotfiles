// Main.qml — thème SDDM Electric Glass.
//
// QtQuick pur : aucun import org.kde.*, Qt5Compat ou QtQuick.Controls. Tout ce
// qui est importé ici vient de qt6-declarative seul, de sorte qu'aucune mise à
// jour de Plasma ne puisse casser cet écran de connexion — c'est précisément
// ainsi que le thème eos-breeze est tombé (VirtualKeyboardLoader supprimé du
// module org.kde.breeze.components en plasma-workspace 6.8.0).
//
// Propriétés de contexte fournies par SDDM 0.21 : sddm, config, userModel,
// sessionModel, screenModel, keyboard, primaryScreen. Toutes sont accédées
// derrière un garde `typeof`, pour que le thème reste utilisable en
// --test-mode comme en conditions réelles.

import QtQuick
import "components"

Item {
    id: root

    // Dimensions nominales : QQuickView redimensionne l'objet racine
    // (SizeRootObjectToView). Tout est ancré, rien ne dépend de Screen.width,
    // qui est faux en mode test.
    width: 2560
    height: 1440

    Theme { id: tokens }

    // SDDM crée une vue par écran : le fond est partout, le panneau seulement
    // sur l'écran principal.
    readonly property bool isPrimary: (typeof primaryScreen !== "undefined") ? primaryScreen : true

    // ─── Verrouillage majuscules ──────────────────────────────────────────
    // Piège : dans SDDM 0.21, keyboard.capsLockState est exposé comme une
    // MÉTHODE, pas comme une propriété. `keyboard.capsLockState` évalue donc
    // l'objet fonction, toujours vrai. Il faut l'appeler — et comme un appel
    // de fonction ne crée aucune dépendance de binding, réévaluer sur le
    // signal capsLockStateChanged.
    property bool capsLockOn: false

    function refreshCapsLock() {
        if (typeof keyboard === "undefined")
            return
        try {
            capsLockOn = keyboard.capsLockState()
        } catch (e) {
            capsLockOn = false
        }
    }

    Connections {
        target: (typeof keyboard !== "undefined") ? keyboard : null
        function onCapsLockStateChanged() { root.refreshCapsLock() }
    }

    // ─── Utilisateur ──────────────────────────────────────────────────────
    // userModel.lastUser est une CHAÎNE (le nom d'utilisateur) ;
    // userModel.lastIndex est l'index. Ne pas les confondre.
    readonly property string lastUser: {
        if (typeof userModel === "undefined")
            return ""
        return userModel.lastUser ? userModel.lastUser : ""
    }

    // Si SDDM ne connaît pas de dernier utilisateur mais que le modèle n'en
    // contient qu'un seul, c'est forcément celui-là : inutile de demander à
    // le saisir.
    property string soleUser: ""

    readonly property string knownUser: lastUser !== "" ? lastUser : soleUser
    readonly property bool needsUsername: knownUser === ""
    readonly property string loginUser: needsUsername ? usernameField.value : knownUser

    property string displayName: ""

    signal usersReady()

    // Les rôles d'un modèle C++ ne sont pas lisibles par index depuis QML :
    // cette sonde non visuelle les expose pour retrouver le nom complet.
    Repeater {
        id: userProbe
        model: (typeof userModel !== "undefined") ? userModel : 0

        Item {
            visible: false
            readonly property string uName: (model.name !== undefined) ? model.name : ""
            readonly property string uReal: (model.realName !== undefined) ? model.realName : ""
            Component.onCompleted: root.usersReady()
        }
    }

    function refreshSoleUser() {
        if (userProbe.count === 1) {
            var only = userProbe.itemAt(0)
            soleUser = only ? only.uName : ""
        } else {
            soleUser = ""
        }
    }

    function refreshDisplayName() {
        var target = loginUser
        if (target === "") {
            displayName = ""
            return
        }
        for (var i = 0; i < userProbe.count; i++) {
            var item = userProbe.itemAt(i)
            if (item && item.uName === target) {
                displayName = item.uReal !== "" ? item.uReal : target
                return
            }
        }
        displayName = target
    }

    onUsersReady: {
        refreshSoleUser()
        refreshDisplayName()
    }
    onLoginUserChanged: refreshDisplayName()

    // ─── Connexion ────────────────────────────────────────────────────────
    function submit() {
        var user = loginUser

        if (user === "") {
            statusMsg.setError("Saisissez votre nom d'utilisateur")
            usernameField.focusInput()
            return
        }

        if (passwordField.value === "") {
            statusMsg.setError("Saisissez votre mot de passe")
            passwordField.focusInput()
            return
        }

        statusMsg.setInfo("Connexion…")

        if (typeof sddm !== "undefined") {
            // Le troisième argument est un INDEX de ligne de sessionModel.
            sddm.login(user, passwordField.value, sessionSelector.currentIndex)
        }
    }

    // Syntaxe Qt6 obligatoire : `function onSignal()`. L'ancienne forme
    // `onSignal: { ... }` de maldives est rejetée en Qt6.
    // loginSucceeded() et loginFailed() n'ont AUCUN paramètre ; seul
    // informationMessage(message) en a un.
    Connections {
        target: (typeof sddm !== "undefined") ? sddm : null

        function onLoginSucceeded() {
            statusMsg.setSuccess("Connexion réussie")
            passwordField.enabled = false
        }

        function onLoginFailed() {
            passwordField.clear()
            passwordField.flashError()
            statusMsg.setError("Mot de passe incorrect")
            passwordField.focusInput()
        }

        function onInformationMessage(message) {
            statusMsg.setError(message)
        }
    }

    // ─── Fond ─────────────────────────────────────────────────────────────
    ProceduralBackground {
        anchors.fill: parent
        theme: tokens
    }

    // Déclarée avant le contenu, donc derrière lui : ferme le popup de session
    // sur un clic en dehors du panneau, sans intercepter les clics du popup
    // lui-même ni ceux du panneau.
    MouseArea {
        anchors.fill: parent
        visible: sessionSelector.popupOpen
        enabled: visible
        onClicked: sessionSelector.close()
    }

    // ─── Contenu ──────────────────────────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing: tokens.clockGap
        visible: root.isPrimary

        ClockBlock {
            anchors.horizontalCenter: parent.horizontalCenter
            theme: tokens
        }

        GlassPanel {
            id: panel
            anchors.horizontalCenter: parent.horizontalCenter
            theme: tokens
            width: tokens.panelWidth
            height: panelContent.implicitHeight + tokens.panelPadding * 2
            highlighted: passwordField.inputFocus || usernameField.inputFocus

            Column {
                id: panelContent
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - tokens.panelPadding * 2
                spacing: tokens.contentSpacing

                UserBadge {
                    anchors.horizontalCenter: parent.horizontalCenter
                    theme: tokens
                    userName: root.loginUser
                    displayName: root.displayName
                    hostName: (typeof sddm !== "undefined" && sddm.hostName) ? sddm.hostName : ""
                }

                // Repli : seulement si SDDM ne connaît aucun dernier
                // utilisateur (système neuf, state.conf vierge).
                GlassTextField {
                    id: usernameField
                    width: parent.width
                    visible: root.needsUsername
                    theme: tokens
                    isPassword: false
                    showReveal: false
                    glyph: ""   // nf-fa-user
                    placeholder: "Nom d'utilisateur"
                    onAccepted: passwordField.focusInput()
                    onTabPressed: passwordField.focusInput()
                }

                Row {
                    width: parent.width
                    spacing: 10

                    GlassTextField {
                        id: passwordField
                        width: parent.width - submitButton.width - parent.spacing
                        theme: tokens
                        showReveal: tokens.showRevealButton
                        onAccepted: root.submit()
                        onTabPressed: sessionSelector.forceActiveFocus()
                    }

                    GlowButton {
                        id: submitButton
                        anchors.verticalCenter: parent.verticalCenter
                        theme: tokens
                        glyph: ""   // nf-fa-arrow_right
                        onClicked: root.submit()
                    }
                }

                StatusMessage {
                    id: statusMsg
                    width: parent.width
                    theme: tokens
                }

                CapsLockHint {
                    width: parent.width
                    theme: tokens
                    // Replié au repos : un Column ignore un enfant invisible,
                    // espacement compris, ce qui resserre le panneau.
                    visible: tokens.showCapsLockHint && root.capsLockOn
                    active: root.capsLockOn
                }

                SessionSelector {
                    id: sessionSelector
                    width: parent.width
                    // Masqué s'il n'y a qu'une seule session : il n'y aurait
                    // rien à choisir.
                    visible: tokens.showSessionSelector && sessionSelector.sessionCount > 1
                    theme: tokens
                    sessions: (typeof sessionModel !== "undefined") ? sessionModel : null
                }
            }
        }
    }

    // ─── Démarrage ────────────────────────────────────────────────────────
    Component.onCompleted: {
        if (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0)
            sessionSelector.currentIndex = sessionModel.lastIndex

        refreshCapsLock()

        // Sans cela, la frappe part dans le vide.
        if (needsUsername)
            usernameField.focusInput()
        else
            passwordField.focusInput()
    }
}
