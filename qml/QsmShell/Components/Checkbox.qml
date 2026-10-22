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
    readonly property real sizeScale: root.boxSize / Style.size("Checkbox", "md")
    // The type step a label in the slot reads at, so the text scales with the box.
    readonly property int labelSize: Style.textNear(Style.textMd * root.sizeScale)

    // Overrides the name read from the label slot's own text.
    property string accessibleName: ""
    default property alias label: labelSlot.data

    signal toggleRequested(bool checked)

    // Every route is this one call: pointer (clicked), Space, Return and
    // keypad Enter (ActivationKeys, once on release), the screen reader and a
    // caller.
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
    Accessible.name: root.accessibleName !== "" ? root.accessibleName : labelSlot.text
    Accessible.onPressAction: root.flip()
    Accessible.onToggleAction: root.flip()

    onClicked: root.flip()
    ActivationKeys {
        id: keys
        available: root.enabled
        onActivated: root.flip()
    }
    Keys.forwardTo: [keys]

    readonly property real _box: root.boxSize
    readonly property bool _hasLabel: labelSlot.hasContent
    readonly property real _gap: root._hasLabel ? Style.rhythm(root._box * 0.5) : 0
    readonly property bool _marked: root.checked || root.indeterminate
    // The mark rides at 3:4 of the box -- the inner eighth stays air at every
    // size, the ratio M3 draws its mark at. Snapping it to the icon scale would
    // land a 12px glyph inside the 12px sm box, so it is a proportion of the
    // box, not a token.
    readonly property real _markSize: root._box * 0.75

    // The label column is a constant, never content-derived: the row is one
    // `controlWidth` wide at md, so a checkbox lines up with the fields and
    // bars around it, and a long label elides inside the column.
    property real labelWidth: Math.round(Style.controlWidth * root.sizeScale) - root._box - root._gap
    implicitWidth: row.implicitWidth
    // The pointer target is the footprint, and the footprint is at least
    // `Style.targetFloor` tall (WCAG 2.5.8), so the hit zone and
    // the hover zone are one rectangle and nothing overflows it. A shorter box
    // and label centre in the slack.
    implicitHeight: Math.max(Style.targetFloor, row.implicitHeight)
    padding: 0

    // The pointing hand over the whole row while enabled.
    HoverHandler {
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    contentItem: RowLayout {
        id: row
        spacing: root._gap

        // The box is the footprint; the body is what the layer grows, so the
        // mark inside it keeps its size.
        Item {
            id: box
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root._box
            implicitHeight: root._box

            // The unchecked box has to EXIST before it can be checked, and a
            // transparent square on a boxless surface does not: an empty toggle
            // is an outline (`textMuted`), and checking it fills the outline in
            // with accent. The ring stays and takes the fill's colour, so
            // checking is one cross-fade of fill and ring on one clock. The
            // fill is the SAME colour at no alpha when unmarked, not
            // "transparent", so the fade never passes through a dark mix.
            // Hover and press change the colour through the one state matrix
            // (the layer below grows the body; a press only recolours it).
            // Disabled dims every role BY COLOUR, never by opacity on the
            // composite, which would show the fill through the mark.
            Rectangle {
                anchors.fill: parent
                anchors.margins: -stateLayer.growth
                radius: Style.radiusXs
                readonly property color _tone: Style.tone(root._marked ? root.accentColor : Style.textMuted,
                    stateLayer.hovered, stateLayer.pressed, false, root.enabled, root.accentColor)
                color: Qt.alpha(_tone, root._marked ? 1 : 0)
                border.width: Style.stroke(Style.indicatorWidth, root)
                border.color: _tone

                Behavior on color {
                    ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                }
                Behavior on border.color {
                    ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                }
            }

            // Content on the accent is the background, as the Switch knob.
            SvgIcon {
                anchors.centerIn: parent
                visible: root.checked && !root.indeterminate
                name: "check"
                size: root._markSize
                color: root.enabled ? Style.textOnPrimary : Style.disabled(Style.textOnPrimary)
            }
            // A dash, not a smaller tick: "some" must not read as a faint "yes".
            // A straight line is a radius-0 rectangle a whole number of device
            // pixels thick, never a glyph that smears over two rows; its weight
            // is the check's stroke (2 on a 24 grid) and its length the check's
            // width, so "some" weighs what "yes" does at every size.
            Rectangle {
                anchors.centerIn: parent
                visible: root.indeterminate
                width: root._markSize * 2 / 3
                height: Style.stroke(root._markSize / 12, root)
                radius: Style.radiusPill
                antialiasing: false
                color: root.enabled ? Style.textOnPrimary : Style.disabled(Style.textOnPrimary)
            }
        }

        // Adjacent content slot: the host provides a label (or anything else)
        // through the default property alias. Disabled colouring is the host's
        // responsibility -- slot content is opaque to the component.
        LabelSlot {
            id: labelSlot
            columnWidth: root.labelWidth
        }
    }

    // The layer is the box's own geometry: StateLayer's ring already reaches
    // `spaceTight` clear of it, a half step, on the box alone -- not the label.
    // Pointer clicking still covers the whole row.
    StateLayer {
        id: stateLayer
        x: row.x + box.x
        y: row.y + box.y
        width: box.width
        height: box.height
        host: root
        focusRadius: Style.radiusXs
        bodyGrows: true
        manualPressOverride: keys.held
    }
}
