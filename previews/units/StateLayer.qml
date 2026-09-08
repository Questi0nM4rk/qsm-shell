import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property alias interactive: stateLayer.interactive
    implicitWidth: Style.space6 * 10
    implicitHeight: Style.space6 * 3

    Rectangle {
        id: target
        anchors.fill: parent
        radius: Style.radiusLg
        color: Style.surfaceRaised
        activeFocusOnTab: true
    }

    StateLayer {
        id: stateLayer
        anchors.fill: parent
        target: target
        interactive: root.variant !== "disabled"
        focused: target.activeFocus
        focusRadius: Style.radiusLg
    }

    Prose {
        anchors.centerIn: parent
        role: "metadata"
        text: "StateLayer / " + root.variant
    }

    readonly property var controls: [
        { label: "state", options: [
            { label: "enabled", set: { interactive: true } },
            { label: "disabled", set: { interactive: false } }
        ]}
    ]
}
