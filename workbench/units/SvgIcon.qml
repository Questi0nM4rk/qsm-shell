import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property string name: "battery-full"
    property int size: Style.iconMd

    readonly property color foreground: {
        switch (root.variant) {
        case "selected": return Style.accent;
        case "danger": return Style.danger;
        case "disabled": return Style.disabled(Style.text);
        default: return Style.text;
        }
    }

    implicitWidth: glyph.width
    implicitHeight: glyph.height
    color: Style.band

    SvgIcon {
        id: glyph
        anchors.centerIn: parent
        name: root.name
        size: root.size
        color: root.foreground
    }

    // The glyph has no pointer and no state of its own: its colour is the
    // owner's decision and its size is the owner's call, so both arrive here.
    readonly property var controls: [
        { label: "foreground", options: [
            { label: "rest", set: { variant: "rest" } },
            { label: "selected", set: { variant: "selected" } },
            { label: "danger", set: { variant: "danger" } },
            { label: "disabled", set: { variant: "disabled" } }
        ] },
        { label: "scale", options: [
            { label: "xs", set: { size: Style.iconXs } },
            { label: "sm", set: { size: Style.iconSm } },
            { label: "md", set: { size: Style.iconMd } },
            { label: "lg", set: { size: Style.iconLg } }
        ] }
    ]
}
