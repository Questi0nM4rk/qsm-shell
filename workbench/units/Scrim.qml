import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool shown: variant === "shown"
    property int dismissals: 0

    // Not band: the scrim dims with band, so band under it would show no dim.
    color: Style.surface
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    Prose {
        anchors.centerIn: parent
        role: "body"
        text: "Behind the modal"
    }

    Scrim {
        id: scrim
        shown: root.shown
        onDismissed: {
            root.shown = false
            root.dismissals++
            root.eventRecorder?.("intent", "dismissed", {})
        }
    }

    readonly property var controls: [
        { label: "visibility", options: [
            { label: "shown", set: { shown: true } },
            { label: "hidden", set: { shown: false } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]

    readonly property var integration: ({
        events: ["dismissed"],
        actions: ["dismiss"],
        observables: {
            shown: () => scrim.shown,
            dismissals: () => root.dismissals
        },
        runAction: name => {
            if (name !== "dismiss")
                return false
            scrim.dismiss()
            return true
        }
    })
}
