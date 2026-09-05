import QtQuick

import qs.QsmShell.Style

// Generic two-state confirm control (icon + label, with consumer-owned armed
// confirmation state). The confirmation text and the accent/feedback colors
// are injected; no product session confirmation or service policy remains.
Item {
    id: root
    required property string icon
    required property string label
    // Text shown while `armed`; when empty the armed state reuses `label`.
    property string confirmLabel: ""
    property bool selected: false
    property bool armed: false
    property color accent: Style.accent
    property color armedColor: Style.danger
    property real buttonWidth: 96
    property real buttonHeight: 72
    // Keyboard focus. Defaults to this item's own, so a control that takes
    // focus rings without wiring; a list that owns focus for its rows binds it.
    property bool focused: root.activeFocus
    signal entered
    signal exited
    signal activated

    implicitWidth: buttonWidth
    implicitHeight: buttonHeight
    readonly property color stateColor: armed ? armedColor : selected ? accent : Style.text
    readonly property string shownLabel: armed && confirmLabel.length > 0 ? confirmLabel : label
    Rectangle {
        anchors.fill: parent
        radius: Style.radiusMd
        color: root.armed ? Qt.rgba(root.armedColor.r, root.armedColor.g, root.armedColor.b, .25)
            : root.selected ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, .22)
            : Qt.rgba(Style.surfaceHover.r, Style.surfaceHover.g, Style.surfaceHover.b, .5)
        Behavior on color { ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }
    }
    Column {
        anchors.centerIn: parent
        spacing: Style.space1
        SvgIcon { anchors.horizontalCenter: parent.horizontalCenter; name: root.icon; size: Style.iconLg; color: root.stateColor }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.shownLabel
            color: root.armed || root.selected ? root.stateColor : Style.textMuted
            font.family: Style.fontFamily
            font.pixelSize: Style.textXs
        }
    }
    StateLayer {
        anchors.fill: parent
        focused: root.focused
        focusRadius: Style.radiusMd
        hoverScale: 1.06
        pressScale: .94
        onClicked: root.activated()
        onHoveredChanged: { if (hovered) root.entered(); else root.exited(); }
    }
}
