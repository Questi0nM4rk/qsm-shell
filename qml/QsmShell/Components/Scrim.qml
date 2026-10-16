import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// The ground going quiet behind something that has taken over.
//
// It does two jobs and the second is the one that matters: it dims what is
// behind (so the thing in front reads as in front), and it CATCHES the pointer
// (so a click meant for the surface underneath cannot land there while a modal
// is open). A dim without the catch is decoration; a modal over it is modal in
// appearance only.
//
// It does not decide what a click means. It reports `dismissed`; the surface
// that opened it decides whether clicking away is allowed — for an
// unsaved-work dialog it is not, and the component cannot know that.
Rectangle {
    id: root

    property bool shown: false
    property real strength: 0.55

    signal dismissed
    readonly property list<T.Action> actions: [T.Action { text: "Dismiss"; enabled: root.enabled && root.shown; onTriggered: root.dismiss() }]

    function dismiss(): void {
        if (root.shown && root.enabled)
            root.dismissed()
    }

    anchors.fill: parent
    color: Qt.rgba(Style.band.r, Style.band.g, Style.band.b, root.strength)
    opacity: shown ? 1 : 0
    // Not merely transparent: an invisible scrim still eats every click on the
    // surface underneath, which is a shell that has silently stopped working.
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: Motion.medium
            easing.type: root.shown ? Motion.standardEasing : Motion.exitEasing
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.shown && root.enabled
        // Every button, so a right-click cannot reach a context menu behind
        // an open modal.
        acceptedButtons: Qt.AllButtons
        onClicked: root.dismiss()
    }
}
