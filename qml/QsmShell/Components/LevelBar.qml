import QtQuick

import qs.QsmShell.Style

Item {
    id: root

    property real value: 0
    property real wheelStep: 0
    property color fill: Style.accent
    signal moved(real value)

    implicitHeight: Style.levelThumbSize

    function clampedFraction(fraction: real): real {
        return Math.max(0, Math.min(1, fraction));
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: Style.levelTrackHeight
        radius: height / 2
        color: Style.surfaceHover
        opacity: root.enabled ? 1 : Style.opacityDisabled

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * root.clampedFraction(root.value)
            height: parent.height
            radius: parent.radius
            color: root.fill
        }
    }

    Rectangle {
        width: Style.levelThumbSize
        height: width
        radius: width / 2
        color: Style.text
        visible: root.enabled
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(root.width - width,
            root.width * root.clampedFraction(root.value) - width / 2))
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -Style.space2
        cursorShape: Qt.PointingHandCursor
        onPressed: event => root.moved(root.clampedFraction((event.x - Style.space2) / root.width))
        onPositionChanged: event => {
            if (pressed)
                root.moved(root.clampedFraction((event.x - Style.space2) / root.width));
        }
    }

    WheelHandler {
        enabled: root.wheelStep > 0
        onWheel: event => {
            if (event.angleDelta.y !== 0)
                root.moved(root.clampedFraction(root.value
                    + (event.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep)));
        }
    }
}
