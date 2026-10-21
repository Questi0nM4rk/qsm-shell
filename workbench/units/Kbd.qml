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
    color: Style.band

    Kbd {
        id: caps
        anchors.centerIn: parent
        // The host owns the width, as a keybind column does: a short combo
        // keeps its own width, a long one shrinks and elides inside the column.
        width: Math.min(implicitWidth, Style.controlWidth / 2)
        combo: root.combo
    }

    readonly property var controls: [
        { label: "combo", options: [
            { label: "short", set: { variant: "SUPER + Q" } },
            { label: "modifiers", set: { variant: "SUPER + SHIFT + Q" } },
            { label: "long", set: { variant: "SUPER + CTRL + ALT + SHIFT + PRINTSCREEN + ENTER" } }
        ] }
    ]
}
