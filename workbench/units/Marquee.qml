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
    color: Style.background

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
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            overflows: () => line.overflows,
            mode: () => line.mode
        },
        textDriver: text => {
            line.text = String(text)
            return true
        }
    })
}
