import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property string mode: root.variant.length > 0 ? root.variant : "once"
    property string text: "Battery 87 percent, charging, three hours remaining at the present rate"

    implicitWidth: Style.controlWidth
    implicitHeight: line.implicitHeight
    color: Style.band

    Marquee {
        id: line
        anchors.centerIn: parent
        // The host owns the width and the line clips inside it; the travel
        // distance is whatever that leaves over.
        width: Style.controlWidth
        text: root.text
        mode: root.mode
    }

    readonly property var controls: [
        { label: "mode", options: [
            { label: "once", set: { mode: "once" } },
            { label: "always", set: { mode: "always" } },
            { label: "hover", set: { mode: "hover" } },
            { label: "never", set: { mode: "never" } }
        ] },
        { label: "text", options: [
            { label: "long", set: { text: "Battery 87 percent, charging, three hours remaining at the present rate" } },
            { label: "short", set: { text: "Battery 87 percent" } },
            { label: "empty", set: { text: "" } }
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        targets: ({
            marquee: () => line,
            scene: () => root
        }),
        observables: {
            overflows: () => line.overflows,
            mode: () => line.mode,
            travelling: () => line.travelling,
            offset: () => line.offset,
            "accessible-name": () => line.Accessible.name
        },
        textDriver: text => {
            root.text = String(text)
            return true
        }
    })
}
