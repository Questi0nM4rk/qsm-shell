import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// The task: label a shortcut in a keybind column. The host owns the column's
// width, as a cheat sheet does: a short combo keeps its own width, a long one
// shrinks its caps and elides inside the column, and one too long for even the
// smallest caps is cut at the column's edge.
Rectangle {
    id: root

    property string variant: ""
    // "combo" is the name of this input, not a key: only a variant carrying a
    // join is a bind string, and one is rendered as it is written.
    property string combo: root.variant.includes("+") ? root.variant : "SUPER + SHIFT + Q"
    // The column the host gives it; 0 leaves the combo its own width.
    property real column: 0

    implicitWidth: Style.controlWidth
    implicitHeight: caps.height + Style.space4 * 2
    color: Style.band

    Kbd {
        id: caps
        anchors.centerIn: parent
        width: root.column > 0 ? Math.min(implicitWidth, root.column) : implicitWidth
        combo: root.combo
    }

    readonly property var controls: [
        { label: "combo", options: [
            { label: "short", set: { variant: "SUPER + Q" } },
            { label: "modifiers", set: { variant: "SUPER + SHIFT + Q" } },
            { label: "long", set: { variant: "SUPER + CTRL + ALT + SHIFT + PRINTSCREEN + ENTER" } }
        ] },
        { label: "column", options: [
            { label: "natural", set: { column: 0 } },
            { label: "narrow", set: { column: 112 } },
            { label: "tight", set: { column: 72 } }
        ] }
    ]

    // Every Text under `item` that Qt had to elide.
    function _elided(item: Item): int {
        let count = 0
        for (const child of item.children) {
            if (child.truncated === true)
                count++
            count += root._elided(child)
        }
        return count
    }

    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            combo: () => root.combo,
            "kbd-name": () => caps.Accessible.name,
            "kbd-width": () => Math.round(caps.width),
            natural: () => Math.round(caps.width) === Math.round(caps.implicitWidth),
            // How many caps show an ellipsis instead of their text.
            elided: () => root._elided(caps),
            // How far the caps reach past the Kbd's own width, whether any are cut there, and whether it clips.
            overflow: () => Math.max(0, Math.round(caps.childrenRect.x + caps.childrenRect.width - caps.width)),
            cut: () => caps.childrenRect.x + caps.childrenRect.width - caps.width > 0.5,
            clipped: () => caps.clip
        }
    })
}
