import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// The ground going quiet behind something that has taken over.
//
// It does two jobs and the second is the one that matters: it dims what is
// behind (so the thing in front reads as in front), and it CATCHES the pointer
// (so a click, a hover or a wheel meant for the surface underneath cannot land
// there while a modal is open). A dim without the catch is decoration; a modal
// over it is modal in appearance only.
//
// It does not decide what a click means. It reports `dismissed`; the surface
// that opened it decides whether clicking away is allowed — for an
// unsaved-work dialog it is not, and the component cannot know that. That
// refusal is `dismissible: false`, never `enabled: false`: a disabled item
// stops receiving events, so the ground underneath would hear every click.
Rectangle {
    id: root

    property bool shown: false
    property real strength: Style.scrimOpacity
    // Whether a click on the ground is an answer. The ground is caught either way.
    property bool dismissible: true

    signal dismissed
    readonly property list<T.Action> actions: [T.Action { text: "Dismiss"; enabled: root.shown && root.dismissible; onTriggered: root.dismiss() }]

    function dismiss(): void {
        if (root.shown && root.dismissible)
            root.dismissed()
    }

    anchors.fill: parent
    color: Qt.rgba(Style.band.r, Style.band.g, Style.band.b, root.strength)
    opacity: shown ? 1 : 0
    // Not merely transparent: an invisible scrim still eats every click on the
    // surface underneath, which is a shell that has silently stopped working.
    // It catches for as long as the dim is painted, the fade out included.
    visible: opacity > 0

    // Decoration for a screen reader: the modal in front names itself.
    Accessible.ignored: true

    Behavior on opacity {
        NumberAnimation {
            duration: root.shown ? Motion.medium : Motion.exit(Motion.medium)
            easing.type: root.shown ? Motion.standardEasing : Motion.exitEasing
        }
    }

    MouseArea {
        anchors.fill: parent
        // An item with hover on takes the hover from everything beneath it;
        // without it a row under the dim still lights up under the pointer.
        hoverEnabled: true
        // Every button, so a right-click cannot reach a context menu behind
        // an open modal.
        acceptedButtons: Qt.AllButtons
        onClicked: root.dismiss()
        // A MouseArea only takes the wheel when something listens to it;
        // without this the list under the dim still scrolls.
        onWheel: wheel => wheel.accepted = true
    }
}
