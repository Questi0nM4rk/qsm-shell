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
            color: !root.enabled
                ? (root.checked ? Style.disabled(root.accentColor) : "transparent")
                : (root.checked ? root.accentColor : "transparent")
            border.width: root.checked ? 0 : Style.spaceTight
            border.color: root.enabled ? Style.outline : Style.disabled(Style.outline)

            Behavior on color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.4
                height: width
                radius: width / 2
                visible: root.checked
                color: root.enabled ? Style.background : Style.disabled(Style.background)
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
        x: circle.x - Style.spaceTight
        y: circle.y - Style.spaceTight
        width: circle.width + Style.spaceTight * 2
        height: circle.height + Style.spaceTight * 2
        host: root
        target: circle
        focusRadius: width / 2
        hoverScale: 1.15
        pressScale: 0.88
    }
}
