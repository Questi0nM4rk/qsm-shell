import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    // "combo" is the name of this input, not a key: only a variant carrying a
    // join is a bind string, and one is rendered as it is written.
    property string combo: root.variant.includes("+") ? root.variant : "SUPER + SHIFT + Q"

    implicitWidth: caps.width
    implicitHeight: caps.height
    color: Style.background

    Kbd {
        id: caps
        anchors.centerIn: parent
        combo: root.combo
    }

    readonly property var controls: []
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            "min-cap-width": () => caps.minCapWidth,
            "cap-height": () => caps.height
        }
    })
}
