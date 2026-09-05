import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// A boolean that is a STATEMENT, not an action: something else acts on it
// later. If throwing it takes effect immediately, it is a `Switch`.
//
// Three states, not two. `indeterminate` is what a parent row shows when some
// of its children are checked and some are not — without it, a "select all"
// box has to lie in one direction or the other, and whichever it picks is
// wrong half the time.
//
// The mark inside the box is the state; the box's fill only reinforces it.
Item {
    id: root

    property bool checked: false
    // Some, but not all. Outranks `checked` while true.
    property bool indeterminate: false
    property string label: ""
    property color accentColor: Style.accent
    property bool focused: root.activeFocus

    signal toggled(bool checked)

    readonly property real _box: Style.iconSm
    readonly property bool _marked: checked || indeterminate

    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(_box, row.implicitHeight)
    opacity: enabled ? 1 : Style.opacityDisabled

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Style.space2

        Rectangle {
            id: box
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root._box
            implicitHeight: root._box
            radius: Style.radiusXs
            color: root._marked ? root.accentColor : "transparent"
            // The unchecked box has to EXIST before it can be checked, and a
            // transparent square on a boxless surface does not. This is the
            // second place in the library that draws an outline, and for the
            // same reason as the text field: the edge is the affordance.
            border.width: root._marked ? 0 : 1
            border.color: Style.outline

            Behavior on color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }

            SvgIcon {
                anchors.centerIn: parent
                visible: root.checked && !root.indeterminate
                name: "check"
                size: parent.width - Style.spaceTight * 2
                color: Style.background
            }
            // A dash, not a smaller tick: "some" must not read as a faint
            // "yes".
            Rectangle {
                anchors.centerIn: parent
                visible: root.indeterminate
                width: parent.width / 2
                height: Style.markThickness - 1
                radius: height / 2
                color: Style.background
            }
        }

        Prose {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            visible: root.label.length > 0
            role: "label"
            text: root.label
        }
    }

    StateLayer {
        anchors.fill: parent
        // The BOX answers, not the label: a long label scaling under the
        // pointer shoves the rest of the row around.
        target: box
        interactive: root.enabled
        focused: root.focused
        focusRadius: Style.radiusXs
        hoverScale: 1.15
        pressScale: 0.88
        onClicked: root.toggled(!root.checked)
    }

    Keys.onSpacePressed: if (root.enabled) root.toggled(!root.checked)
    Keys.onReturnPressed: if (root.enabled) root.toggled(!root.checked)
}
