import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import qs.QsmShell.Style

// A boolean that is a STATEMENT, not an action: something else acts on it
// later. If throwing it takes effect immediately, it is a `Switch`.
//
// Three states, not two. `indeterminate` is what a parent row shows when some
// of its children are checked and some are not -- without it, a "select all"
// box has to lie in one direction or the other, and whichever it picks is
// wrong half the time.
//
// The mark inside the box is the state; the box's fill only reinforces it.
//
// The HOST owns `checked`: this emits `toggleRequested` and never writes its
// own state, so a selection the system can also change from elsewhere never
// fights the control that shows it. Hence `T.AbstractButton` with
// `checkable: false`, not `T.CheckBox`: a template checkbox writes `checked`
// itself on click (a tristate one cycles all three states), which takes the
// state away from the host.
T.AbstractButton {
    id: root

    // Some, but not all. Outranks `checked` while true.
    property bool indeterminate: false
    property color accentColor: Style.accent
    // sm | md | lg -- a preset NAME, resolved through the theme's size table.
    property string size: "md"
    // The one absolute number; everything else is a proportion of it. The
    // preset is only the DEFAULT: a host that wants a checkbox across a
    // screen or inside a dense row states its own.
    property real boxSize: Style.size("Checkbox", size)
    // One scale per instance: the mark, the row gap and the label (provided
    // by the host through the default slot) are derived from this ratio
    // against md, so it is the one number a host composing around it needs.
    readonly property real _s: root.boxSize / Style.size("Checkbox", "md")
    readonly property real sizeScale: root._s

    // Short string for screen readers; does not render visible content.
    property string accessibleName: ""
    default property alias label: labelSlot.data

    signal toggleRequested(bool checked)

    // Every route is this one call: pointer (clicked), Space (the template
    // clicks on Space), Return (below) and a caller.
    function flip(): void {
        if (root.enabled)
            root.toggleRequested(!root.checked);
    }

    readonly property list<T.Action> actions: [
        T.Action { text: "Toggle"; enabled: root.enabled; onTriggered: root.flip() }
    ]

    checkable: false
    activeFocusOnTab: enabled
    hoverEnabled: true
    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: root.checked && !root.indeterminate
    Accessible.checkStateMixed: root.indeterminate
    Accessible.name: root.accessibleName
    Accessible.onPressAction: root.flip()
    Accessible.onToggleAction: root.flip()

    // A constant, never content-derived: a long label elides inside it.
    property real labelWidth: Style.rhythm(Style.controlWidth * root._s)
    readonly property bool _hasLabel: labelSlot.children.length > 0
    readonly property real _box: root.boxSize
    readonly property real _markRatio: 0.75
    readonly property bool _marked: root.checked || root.indeterminate
    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(_box, row.implicitHeight)
    padding: 0

    // The pointer hits the footprint plus a square of at least `iconLg` around
    // the box, so a bare sm or md box is not a smaller target than the floor.
    // The overflow is hit area only: the natural size above is untouched.
    containmentMask: QtObject {
        function contains(point: point): bool {
            if (point.x >= 0 && point.y >= 0 && point.x < root.width && point.y < root.height)
                return true;
            const c = box.mapToItem(root, box.width / 2, box.height / 2);
            const reach = Math.max(root._box, Style.iconLg) / 2;
            return Math.abs(point.x - c.x) <= reach && Math.abs(point.y - c.y) <= reach;
        }
    }

    onClicked: root.flip()
    Keys.onReturnPressed: root.flip()

    contentItem: RowLayout {
        id: row
        anchors.fill: parent
        spacing: root._hasLabel ? Style.rhythm(root._box * 0.5) : 0

        Rectangle {
            id: box
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root._box
            implicitHeight: root._box
            radius: Style.radiusXs
            // The unchecked box has to EXIST before it can be checked, and a
            // transparent square on a boxless surface does not. This is the
            // second place in the library that draws an outline, and for the
            // same reason as the text field: the edge is the affordance.
            // Disabled dims every role BY COLOUR, never by opacity on the
            // composite, which would show the fill through the mark.
            // Hover and press change the colour through the one state matrix
            // (the layer below grows the box; a press only recolours it).
            color: root._marked
                ? Style.tone(root.accentColor, stateLayer.hovered, stateLayer.pressed, false, root.enabled, root.accentColor)
                : "transparent"
            border.width: root._marked ? 0 : 1
            border.color: Style.tone(Style.textMuted, stateLayer.hovered, stateLayer.pressed, false, root.enabled, root.accentColor)

            Behavior on color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }

            // The check rides at 3:4 of the box (`_markRatio`) -- the inner
            // eighth stays air at every size, the ratio M3 draws its mark at.
            // Snapping it to the icon scale would land a 12px glyph inside the
            // 12px sm box, so it is a proportion of the box, not a token.
            SvgIcon {
                anchors.centerIn: parent
                visible: root.checked && !root.indeterminate
                name: "check"
                size: root._box * root._markRatio
                // Content on the accent is the background, as the Switch knob.
                // Style.disabled(background) is the identity blend, written
                // explicitly so every role passes through the same function.
                color: root.enabled ? Style.textOnPrimary : Style.disabled(Style.textOnPrimary)
            }
            // A dash, not a smaller tick: "some" must not read as a faint
            // "yes".
            Rectangle {
                anchors.centerIn: parent
                visible: root.indeterminate
                width: parent.width / 2
                height: Style.spaceTight
                radius: height / 2
                color: root.enabled ? Style.textOnPrimary : Style.disabled(Style.textOnPrimary)
            }
        }

        // Adjacent content slot: the host provides a label (or anything else)
        // through the default property alias. Disabled colouring is the host's
        // responsibility -- slot content is opaque to the component.
        Item {
            id: labelSlot
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            // The host binds its label's width to this slot's, so a long
            // label elides here instead of growing the control.
            clip: true
            implicitWidth: root._hasLabel ? root.labelWidth : 0
            implicitHeight: childrenRect.height
        }
    }

    // The layer is the box's own geometry: StateLayer's ring already reaches
    // `spaceTight` clear of it, a half step, on the box alone -- not the label.
    // Pointer clicking still covers the row and the hit square above.
    StateLayer {
        id: stateLayer
        x: box.x
        y: box.y
        width: box.width
        height: box.height
        host: root
        target: box
        focusRadius: Style.radiusXs
        hoverScale: 1.15
    }
}
