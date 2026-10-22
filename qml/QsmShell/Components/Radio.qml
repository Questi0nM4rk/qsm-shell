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
    // sm | md | lg -- a preset NAME, resolved through the theme's size table.
    property string size: "md"
    // The one absolute number, the circle's diameter; everything else is a
    // proportion of it.
    property real radioSize: Style.size("Radio", size)
    // One scale per instance: the ratio against md, for a host composing around it.
    readonly property real sizeScale: root.radioSize / Style.size("Radio", "md")
    // The type step a label in the slot reads at, so the text scales with the circle.
    readonly property int labelSize: Style.textNear(Style.textMd * root.sizeScale)
    // Overrides the name read from the label slot's own text.
    property string accessibleName: ""
    default property alias label: labelSlot.data

    signal selectionRequested()

    // Every route is this one call: pointer (clicked), Space (the template
    // clicks on Space), Return and keypad Enter (below), the screen reader and
    // a caller.
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
    Accessible.onPressAction: root.select()

    onClicked: root.select()
    Keys.onReturnPressed: root.select()
    Keys.onEnterPressed: root.select()

    readonly property real _radio: root.radioSize
    readonly property bool _hasLabel: labelSlot.children.length > 0
    readonly property real _gap: root._hasLabel ? Style.rhythm(root._radio * 0.5) : 0

    // The label column is a constant, never content-derived: the row is one
    // `controlWidth` wide at md, so a radio lines up with the fields and bars
    // around it, and a long label elides inside the column.
    property real labelWidth: Math.round(Style.controlWidth * root.sizeScale) - root._radio - root._gap
    implicitWidth: row.implicitWidth
    // The pointer target is the footprint, and the footprint is at least
    // `Style.iconLg` tall (the 24 px floor of WCAG 2.5.8), so the hit zone and
    // the hover zone are one rectangle and nothing overflows it. A shorter
    // circle and label centre in the slack.
    implicitHeight: Math.max(Style.iconLg, row.implicitHeight)
    padding: 0

    // First slotted item that carries text names the control.
    function _labelText(): string {
        for (const item of labelSlot.children) {
            if (typeof item.text === "string" && item.text !== "")
                return item.text;
        }
        return "";
    }

    // The pointing hand over the whole row while enabled.
    HoverHandler {
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    contentItem: RowLayout {
        id: row
        spacing: root._gap

        // The circle is the footprint; the body is what the layer grows, so
        // the dot inside it keeps its size.
        Item {
            id: circle
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root._radio
            implicitHeight: root._radio

            // An unselected radio is an outline (`textMuted`) and selecting it
            // fills the outline in with accent. The ring stays and takes the
            // fill's colour, so selecting is one cross-fade of fill, ring and
            // dot on one clock. The fill is the SAME colour at no alpha when
            // unchecked, not "transparent", so the fade never passes through a
            // dark mix. Hover and press change the colour through the one
            // state matrix (the layer below grows the body; a press only
            // recolours it).
            Rectangle {
                anchors.fill: parent
                anchors.margins: -stateLayer.growth
                radius: Style.radiusPill
                readonly property color _tone: Style.tone(root.checked ? root.accentColor : Style.textMuted,
                    stateLayer.hovered, stateLayer.pressed, false, root.enabled, root.accentColor)
                color: Qt.alpha(_tone, root.checked ? 1 : 0)
                border.width: Style.stroke(Style.indicatorWidth, root)
                border.color: _tone

                Behavior on color {
                    ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                }
                Behavior on border.color {
                    ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                }
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

        // Adjacent content slot: the host provides a label (or anything else)
        // through the default property alias. Disabled colouring is the host's
        // responsibility -- slot content is opaque to the component. An empty
        // slot takes no width and no row gap.
        Item {
            id: labelSlot
            visible: root._hasLabel
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            // The host binds its label's width to this slot's, so a long
            // label elides here instead of growing the control.
            clip: true
            implicitWidth: root.labelWidth
            implicitHeight: childrenRect.height
        }
    }

    StateLayer {
        id: stateLayer
        x: row.x + circle.x
        y: row.y + circle.y
        width: circle.width
        height: circle.height
        host: root
        focusRadius: Style.radiusPill
    }
}
