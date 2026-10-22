import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

// The task: clear a history that cannot be brought back. The first press
// arms, the second confirms; the pointer leaving, focus leaving and the
// timeout abandon it. ArmedAction is the helper; the host (this unit, as the
// notification center is) wires the pointer and the focus to it.
Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool destructive: true
    property int fired: 0
    property int disarmed: 0

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    ArmedAction {
        id: guard
        destructive: root.destructive
        onFired: {
            root.fired++
            root.eventRecorder?.("intent", "fired", {})
        }
        onDisarmed: {
            root.disarmed++
            root.eventRecorder?.("intent", "disarmed", {})
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Style.space3

        IconButton {
            id: button
            icon: "trash-2"
            accessibleName: guard.armed ? "Confirm clear history" : "Clear history"
            color: guard.armed ? Style.danger : Style.text
            hoverEnabled: true
            onClicked: guard.trigger()
            onHoveredChanged: if (!hovered) guard.disarm()
            onActiveFocusChanged: if (!activeFocus) guard.disarm()
            // Escape takes the question back; unarmed, it is left to the surface.
            Keys.onEscapePressed: event => event.accepted = guard.cancel()
        }

        // Both wordings take the longer one's width, so arming never moves the
        // button out from under the pointer.
        Prose {
            id: note
            Layout.preferredWidth: longest.advanceWidth
            role: "supporting"
            text: guard.armed ? "Press again to clear 12 items" : "12 items in history"
        }
        TextMetrics {
            id: longest
            font: note.font
            text: "Press again to clear 12 items"
        }
    }

    readonly property var controls: [
        { label: "guard", options: [
            { label: "destructive", set: { destructive: true } },
            { label: "safe", set: { destructive: false } }
        ] }
    ]

    readonly property var integration: ({
        events: ["fired", "disarmed"],
        actions: ["trigger", "disarm"],
        targets: ({ button: () => button, elsewhere: () => note }),
        observables: {
            armed: () => guard.armed,
            destructive: () => root.destructive,
            fired: () => root.fired,
            disarmed: () => root.disarmed,
            timeout: () => guard.timeout,
            "button-name": () => button.Accessible.name
        },
        runAction: name => {
            if (name === "trigger") { guard.trigger(); return true }
            if (name === "disarm") { guard.disarm(); return true }
            return false
        }
    })
}
