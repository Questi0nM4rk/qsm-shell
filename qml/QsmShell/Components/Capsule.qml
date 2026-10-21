import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import qs.QsmShell.Style

// THE button. An icon, a label, an optional reading, and every state a control
// actually has.
//
// Two axes, and only two, because a third is how a component library turns
// into a catalogue nobody can hold in their head:
//
//   variant — how loudly it asks. ghost < secondary < primary, plus
//             destructive, which is not louder but different in kind.
//   size    — a Control preset (xs, sm, md, lg). The box is the preset and
//             the glyph, the label and the inset are derived from it, so a
//             capsule of one size matches a field or a segmented bar of the
//             same name.
//
// The states are the point. `ghost` paints nothing at rest, which is this
// shell's resting law — and it still answers the pointer, the press, the
// keyboard and its own unavailability, because "no box at rest" was never a
// reason to leave those undefined.
T.Control {
    id: root

    property alias icon: icon.name
    property alias label: label.text
    property string detail: ""
    property color accentColor: Style.accent
    property color surfaceColor
    // One control radius across a row of controls; only a glyph-only capsule
    // is a pill.
    property real radius: root.label.length === 0 ? Style.radiusPill : Style.radiusBody

    // ── the two axes ────────────────────────────────────────────────────
    // ghost | secondary | primary | destructive
    property string variant: "secondary"
    // A Control preset name: xs | sm | md | lg
    property string size: "md"

    // ── consumer-owned state ────────────────────────────────────────────
    // The control is ON: a toggle engaged, a filter applied.
    property bool active: false
    // The host marks a capsule that is a toggle, so a screen reader hears
    // "checked" / "not checked" for `active` and not a plain button. A capsule
    // whose `active` is a status (a scan running) stays a button.
    property bool checkable: false
    // The name a screen reader speaks when there is no label. A glyph-only
    // capsule must carry one; the label wins when it exists.
    property string accessibleName: ""
    readonly property bool focused: root.activeFocus

    signal clicked

    focusPolicy: Qt.StrongFocus

    Accessible.role: Accessible.Button
    Accessible.name: root._name
    Accessible.checkable: root.checkable
    Accessible.checked: root.checkable && root.active

    readonly property string _name: root.label.length > 0 ? root.label : root.accessibleName
    Component.onCompleted: {
        if (root._name.length === 0)
            console.warn("Capsule: no label and no accessibleName -- a screen reader hears an unnamed button")
    }

    readonly property real _box: Style.size("Capsule", root.size)
    // One scale per instance: every measurement is md's times this.
    readonly property real _s: root._box / Style.size("Capsule", "md")
    readonly property bool _quiet: variant === "ghost" || variant === "destructive"
    readonly property color _accent: variant === "destructive" ? Style.danger : accentColor
    // Selected is identity (AGENTS.md, surface ladder): the accent tint on the
    // body AND accent content. Tint alone left an ON capsule telling only by
    // a shade of its surface.
    // A quiet capsule paints no body at rest and shows one under the pointer
    // (`_bodyOpacity` below), so hover and press are visible on every variant.
    // A ghost also rests muted and brightens its label on hover. Primary is the
    // one filled action: its body is `primary` and its content `textOnPrimary`.
    readonly property bool _primary: variant === "primary"
    readonly property color _proseBase: _primary ? Style.textOnPrimary
        : variant === "destructive" ? Style.danger : active ? _accent
        : variant === "ghost" && !stateLayer.hovered ? Style.textMuted : Style.text
    readonly property color _prose: root.enabled ? _proseBase : Style.disabled(_proseBase)
    // A reading is supporting information, never the accent: that is for
    // focus, selection and the primary action.
    readonly property color _reading: _primary ? Style.textOnPrimary : Style.textMuted

    // ONE padding value, used by BOTH the width and the content margins. They
    // used to disagree, and every small capsule came out narrower than its own
    // contents asked for.
    readonly property real contentInset: Style.rhythm(Style.space4 * root._s)

    implicitHeight: root._box
    implicitWidth: content.implicitWidth + leftPadding + rightPadding
    leftPadding: contentInset
    rightPadding: contentInset

    function activate(): void {
        if (root.enabled)
            root.clicked()
    }

    readonly property list<T.Action> actions: [
        T.Action { text: root._name; enabled: root.enabled; onTriggered: root.activate() }
    ]

    // The state matrix is the ladder's (`Style.tone`): ON and "asks loudly"
    // are both the accent's identity over the surface. Hover grows the
    // capsule (StateLayer) AND lifts its colour; a press only recolours it.
    // Disabled dims each role through the state matrix; opacity would make the
    // card, glyph and text show through one another as a composite.
    surfaceColor: Style.tone(root._primary ? Style.primary : Style.surface, stateLayer.hovered,
        stateLayer.pressed, root.active && !root._primary, root.enabled, root._accent)
    // A quiet variant at rest paints NOTHING, which is the difference between
    // a control that sits on the surface and one that is part of it. Under the
    // pointer it takes the lifted surface, so the colour answers hover and
    // press as well as the growth. The body fades rather than the colour, so
    // the colour never passes through a translucent black.
    property real _bodyOpacity: root._quiet && !root.active && !stateLayer.hovered && !stateLayer.pressed ? 0 : 1

    Behavior on surfaceColor {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }
    Behavior on _bodyOpacity {
        NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    // Flat: a button's growth is its depth, not a shadow and an edge line.
    background: Card {
        glow: false
        shadow: false
        radius: root.radius
        surfaceColor: root.surfaceColor
        opacity: root._bodyOpacity
    }

    contentItem: RowLayout {
        id: content
        spacing: Style.space2

        // Every child spans the row and centres its own content in it.
        //
        // WHY, and it is not obvious: a RowLayout aligns text on its BASELINE
        // by default, and an icon has no baseline to share. Left to that, the
        // label sat half a pixel below the centre of the pill while the icon
        // sat exactly on it — measured, not guessed — and half a pixel is
        // enough to read as "the text is not centred". Filling the height and
        // centring inside it takes both the baseline rule and the rounding of
        // each item's implicit height out of the answer.
        SvgIcon {
            id: icon
            // A layout skips an invisible child AND its spacing, so a
            // text-only pill closes up around the missing glyph instead of
            // carrying an icon-sized hole and a gap.
            visible: icon.name.length > 0
            Layout.alignment: Qt.AlignVCenter
            size: Style.glyphBeside(root._box)
            color: root._prose
        }
        Prose {
            id: label
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            role: "label"
            color: root._prose
            // The label scales with the box: a small control with a body-sized
            // label is not a small control. Everything else about the role
            // stays the role's.
            font.pixelSize: Style.textNear(Style.textSm * root._s)
        }
        Prose {
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            visible: root.detail.length > 0
            role: "reading"
            font.pixelSize: Style.textXs
            color: root.enabled ? root._reading : Style.disabled(root._reading)
            text: root.detail
        }
    }

    // Growth and press come from the layer, which owns the one response curve.
    // A pill this wide takes a smaller step than an icon does.
    StateLayer {
        id: stateLayer
        anchors.fill: parent
        interactive: root.enabled
        focused: root.focused
        focusRadius: root.radius
        hoverScale: Motion.capsuleHoverScale
        onClicked: {
            root.forceActiveFocus()
            root.activate()
        }
    }

    Keys.onReturnPressed: event => { event.accepted = true; root.activate() }
    Keys.onEnterPressed: event => { event.accepted = true; root.activate() }
    Keys.onSpacePressed: event => { event.accepted = true; root.activate() }
}
