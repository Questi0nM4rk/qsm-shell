import QtQuick

import qs.QsmShell.Style

// Vertical value control with optional icon interaction and readout.
Item {
    id: root
    required property string icon
    property real value: 0
    property color color: Style.accent
    property real wheelStep: .05
    property real trackWidth: 40
    property real trackHeight: 140
    property real thumbSize: 32
    property int decimals: 0
    // Empty readout text falls back to the numeric value.
    property string readout: ""
    signal moved(real value)
    signal iconClicked

    readonly property bool active: dragging || hover.hovered
    property bool dragging: false
    readonly property real travel: trackHeight - thumbSize
    readonly property real thumbY: (1 - Math.max(0, Math.min(1, value))) * travel
    readonly property string shownReadout: readout.length > 0
        ? readout
        : String(Math.round(root.value * Math.pow(10, decimals)) / Math.pow(10, decimals))

    implicitWidth: trackWidth
    implicitHeight: trackHeight + Style.space2 + thumbSize

    function setFromY(y: real): void { moved(Math.max(0, Math.min(1, 1 - (y - thumbSize / 2) / travel))); }

    Rectangle {
        id: track
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.trackWidth; height: root.trackHeight; radius: width / 2
        color: Qt.darker(Style.surface, 1.35)
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: parent.height - (root.thumbY + root.thumbSize / 2); radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(root.color, 1.12) }
                GradientStop { position: 1; color: Qt.darker(root.color, 1.15) }
            }
            Behavior on height { NumberAnimation { duration: Motion.fast } }
        }
        Rectangle {
            x: (parent.width - root.thumbSize) / 2; y: root.thumbY + (root.dragging ? 4 : 2)
            width: root.thumbSize; height: width; radius: width / 2
            color: Qt.rgba(0,0,0,.45)
        }
        Rectangle {
            x: (parent.width - root.thumbSize) / 2; y: root.thumbY
            width: root.thumbSize; height: width; radius: width / 2
            color: root.active ? Style.text : Qt.darker(Style.text, 1.4)
            Text {
                anchors.centerIn: parent
                text: root.shownReadout
                color: Style.background
                font.pixelSize: Style.textSm
                font.weight: Style.weightBold
            }
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent; anchors.margins: -Style.space2
            onPressed: event => { root.dragging = true; root.setFromY(event.y - Style.space2); }
            onPositionChanged: event => { if (pressed) root.setFromY(event.y - Style.space2); }
            onReleased: root.dragging = false
            onCanceled: root.dragging = false
        }
        WheelHandler {
            onWheel: event => {
                if (event.angleDelta.y !== 0)
                    root.moved(Math.max(0, Math.min(1, root.value + (event.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep))));
            }
        }
    }
    IconButton {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: track.bottom
        anchors.topMargin: Style.space2
        icon: root.icon
        size: Style.iconMd
        padding: Style.space2
        color: root.active ? root.color : Style.text
        onClicked: root.iconClicked()
    }
}
