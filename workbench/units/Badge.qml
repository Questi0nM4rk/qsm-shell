import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property string tone: root.variant !== "" ? root.variant : "neutral"
    property bool filled: false
    property string reading: "3"
    property string glyph: ""
    property bool dot: false

    implicitWidth: badge.implicitWidth
    implicitHeight: badge.implicitHeight
    color: Style.band

    Badge {
        id: badge
        anchors.centerIn: parent
        tone: root.tone
        filled: root.filled
        dot: root.dot
        text: root.reading
        icon: root.glyph
        accessibleName: root.dot ? "Unread" : root.glyph !== "" && root.reading === "" ? "Done" : ""
    }

    readonly property var controls: [
        { label: "tone", options: [
            { label: "neutral", set: { tone: "neutral" } },
            { label: "accent", set: { tone: "accent" } },
            { label: "success", set: { tone: "success" } },
            { label: "warning", set: { tone: "warning" } },
            { label: "danger", set: { tone: "danger" } },
            { label: "info", set: { tone: "info" } }
        ] },
        { label: "weight", options: [
            { label: "tinted", set: { filled: false } },
            { label: "filled", set: { filled: true } }
        ] },
        { label: "presence", options: [
            { label: "reading", set: { reading: "3", glyph: "", dot: false } },
            { label: "count-120", set: { reading: "120", glyph: "", dot: false } },
            { label: "word", set: { reading: "Connected", glyph: "", dot: false } },
            { label: "glyph-word", set: { reading: "Connected", glyph: "check", dot: false } },
            { label: "long", set: { reading: "Reconnecting to the network", glyph: "", dot: false } },
            { label: "glyph", set: { reading: "", glyph: "check", dot: false } },
            { label: "dot", set: { reading: "", glyph: "", dot: true } },
            { label: "empty", set: { reading: "", glyph: "", dot: false } }
        ] }
    ]
    readonly property var integration: ({
        events: [],
        actions: [],
        observables: {
            tone: () => badge.tone,
            filled: () => badge.filled,
            icon: () => badge.icon,
            dot: () => badge.dot,
            visible: () => badge.visible,
            width: () => badge.width,
            height: () => badge.height
        }
    })
}
