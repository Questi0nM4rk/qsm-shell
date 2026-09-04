import QtQuick

import qs.QsmShell.Style

Item {
    id: root

    required property string icon
    property int size: Style.iconMd
    property color color: Style.text
    property int padding: Style.space3
    signal clicked

    implicitWidth: size + padding * 2
    implicitHeight: size + padding * 2
    opacity: enabled ? 1 : Style.opacityDisabled

    Behavior on opacity {
        NumberAnimation { duration: Motion.micro }
    }

    SvgIcon {
        id: glyph
        anchors.centerIn: parent
        name: root.icon
        size: root.size
        color: root.color
    }

    StateLayer {
        anchors.fill: parent
        target: glyph
        interactive: root.enabled
        hoverScale: 1.15
        pressScale: 0.86
        onClicked: root.clicked()
    }
}
