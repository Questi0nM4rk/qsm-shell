import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import qs.QsmShell.Style

// A single-choice option: selecting is an intent the host answers. The host
// owns `checked` and group exclusivity, so selecting an already checked radio
// does nothing and this control never deselects itself.
T.AbstractButton {
    id: root

    property color accentColor: Style.accent
    property string size: "md"
    property real radioSize: Style.size("Radio", size)
    readonly property real _s: root.radioSize / Style.size("Radio", "md")
    readonly property real sizeScale: root._s
    property string accessibleName: ""
    default property alias label: labelSlot.data

    signal selectionRequested()

    function select(): void {
        if (root.enabled && !root.checked)
            root.selectionRequested();
    }

    readonly property list<T.Action> actions: [
        T.Action { text: "Select"; enabled: root.enabled && !root.checked; onTriggered: root.select() }
    ]

    checkable: false
    activeFocusOnTab: enabled
    hoverEnabled: true
    Accessible.role: Accessible.RadioButton
    Accessible.checkable: true
    Accessible.checked: root.checked
    Accessible.name: root.accessibleName

    readonly property real _radio: root.radioSize
    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(_radio, row.implicitHeight)
    padding: 0

    onClicked: root.select()
    Keys.onReturnPressed: root.select()

    contentItem: RowLayout {
        id: row
        anchors.fill: parent
        spacing: Style.rhythm(root._radio * 0.5)

        Rectangle {
            id: circle
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root._radio
            implicitHeight: root._radio
            radius: width / 2
            // Hover and press change the colour through the one state matrix
            // (the layer below grows the circle; a press only recolours it).
            color: root.checked
                ? Style.tone(root.accentColor, stateLayer.hovered, stateLayer.pressed, false, root.enabled, root.accentColor)
                : "transparent"
            border.width: root.checked ? 0 : Style.spaceTight
            border.color: Style.tone(Style.textMuted, stateLayer.hovered, stateLayer.pressed, false, root.enabled, root.accentColor)

            Behavior on color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }

            // The dot is 2/5 of the circle: the M3 ratio, which leaves a ring
            // of accent wider than the dot's own radius at every size. A
            // proportion of the circle, so it scales with it, not a token.
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.4
                height: width
                radius: width / 2
                visible: root.checked
                color: root.enabled ? Style.textOnPrimary : Style.disabled(Style.textOnPrimary)
            }
        }

        Item {
            id: labelSlot
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }

    StateLayer {
        id: stateLayer
        x: circle.x - Style.spaceTight
        y: circle.y - Style.spaceTight
        width: circle.width + Style.spaceTight * 2
        height: circle.height + Style.spaceTight * 2
        host: root
        target: circle
        focusRadius: width / 2
        hoverScale: 1.15
    }
}
