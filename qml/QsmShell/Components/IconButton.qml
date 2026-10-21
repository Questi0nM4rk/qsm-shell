import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

T.Control {
    id: root

    required property string icon
    property int size: Style.iconMd
    property color color: Style.text
    property string accessibleName: icon
    // play.svg is the polygon 6,3 20,12 6,21 on a 24 box: its centroid is
    // (6 + 20 + 6) / 3 = 10.67, which is (12 - 10.67) / 24 = 1/18 of the box
    // left of centre, so the glyph shifts right by size / 18.
    // Whole pixels, because a fractional offset blurs the triangle's edges.
    property int opticalOffset: root.icon === "play" ? Math.round(root.size / 18) : 0
    readonly property color paintedColor: root.enabled ? root.color : Style.disabled(root.color)
    signal clicked

    focusPolicy: Qt.StrongFocus

    implicitWidth: size + leftPadding + rightPadding
    implicitHeight: size + topPadding + bottomPadding
    padding: Style.space3

    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName

    function activate(): void {
        if (root.enabled)
            root.clicked()
    }

    readonly property list<T.Action> actions: [
        T.Action { text: root.accessibleName; enabled: root.enabled; onTriggered: root.activate() }
    ]

    contentItem: Item {
        implicitWidth: root.size
        implicitHeight: root.size

        SvgIcon {
            id: glyph
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.opticalOffset
            name: root.icon
            size: root.size
            color: root.paintedColor
        }
    }

    // Under the glyph: the hover disc is a body, the glyph stands on it.
    StateLayer {
        z: -1
        anchors.fill: parent
        target: glyph
        hoverTint: true
        pressScale: Motion.pressScale
        focusRadius: height / 2
        onClicked: {
            root.forceActiveFocus()
            root.activate()
        }
    }

    Keys.onReturnPressed: event => { event.accepted = true; root.activate() }
    Keys.onEnterPressed: event => { event.accepted = true; root.activate() }
    Keys.onSpacePressed: event => { event.accepted = true; root.activate() }
}
