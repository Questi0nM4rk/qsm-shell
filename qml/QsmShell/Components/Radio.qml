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
    // Overrides the name read from the label slot's own text.
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
    Accessible.name: root.accessibleName !== "" ? root.accessibleName : root._labelText()

    readonly property real _radio: root.radioSize
    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(_radio, row.implicitHeight)
    padding: 0

    // First slotted item that carries text names the control.
    function _labelText(): string {
        for (const item of labelSlot.children) {
            if (typeof item.text === "string" && item.text !== "")
                return item.text;
        }
        return "";
    }

    onClicked: root.select()
    Keys.onReturnPressed: event => { event.accepted = true; root.select() }
    Keys.onEnterPressed: event => { event.accepted = true; root.select() }

    contentItem: RowLayout {
        id: row
        anchors.fill: parent
        spacing: Style.rhythm(root._radio * 0.5)

        Rectangle {
            id: circle
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root._radio
            implicitHeight: root._radio
            radius: Style.radiusPill
            // Hover and press change the colour through the one state matrix
            // (the layer below grows the circle; a press only recolours it).
            color: root.checked
                ? Style.tone(root.accentColor, stateLayer.hovered, stateLayer.pressed, false, root.enabled, root.accentColor)
                : "transparent"
            // The ring stays and takes the fill's colour when checked, so
            // selecting is one cross-fade of fill, ring and dot on one clock.
            border.width: Style.stroke(Style.indicatorWidth, root)
            border.color: Style.tone(root.checked ? root.accentColor : Style.textMuted, stateLayer.hovered, stateLayer.pressed, false, root.enabled, root.accentColor)

            Behavior on color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }
            Behavior on border.color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }

            // The dot is 2/5 of the circle: the M3 ratio, which leaves a ring
            // of accent wider than the dot's own radius at every size. A
            // proportion of the circle, so it scales with it, not a token.
            Rectangle {
                anchors.centerIn: parent
                width: Math.round(parent.width * 0.4)
                height: width
                radius: Style.radiusPill
                visible: opacity > 0
                opacity: root.checked ? 1 : 0
                color: root.enabled ? Style.textOnPrimary : Style.disabled(Style.textOnPrimary)

                Behavior on opacity {
                    NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                }
            }
        }

        Item {
            id: labelSlot
            // An empty slot takes no space, and no row gap.
            visible: children.length > 0
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }

    StateLayer {
        id: stateLayer
        x: circle.x
        y: circle.y
        width: circle.width
        height: circle.height
        host: root
        target: circle
        focusRadius: Style.radiusPill
    }
}
