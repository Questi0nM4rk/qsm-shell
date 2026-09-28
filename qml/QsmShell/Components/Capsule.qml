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
//   size    — sm / md / lg, off the one control-height scale. Not a
//             proportional zoom: a smaller control gets disproportionately
//             tighter padding and a smaller label, because scaling everything
//             by one factor reads as a zoom rather than as a different control.
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
    property real surfaceOpacity
    property real radius: Style.radiusPill

    // ── the two axes ────────────────────────────────────────────────────
    // ghost | secondary | primary | destructive
    property string variant: "secondary"
    // sm | md | lg
    property string size: "md"

    // ── consumer-owned state ────────────────────────────────────────────
    // The control is ON: a toggle engaged, a filter applied.
    property bool active: false
    readonly property bool focused: root.activeFocus

    signal clicked

    focusPolicy: Qt.StrongFocus

    Accessible.role: Accessible.Button
    Accessible.name: root.label

    readonly property bool _sm: size === "sm"
    readonly property bool _lg: size === "lg"
    readonly property bool _quiet: variant === "ghost" || variant === "destructive"
    readonly property color _accent: variant === "destructive" ? Style.danger : accentColor
    // Selected is identity (AGENTS.md, surface ladder): the accent tint on the
    // body AND accent content. Tint alone left an ON capsule telling only by
    // a shade of its surface.
    readonly property color _proseBase: variant === "destructive" ? Style.danger : active ? _accent : Style.text
    readonly property color _prose: root.enabled ? _proseBase : Style.disabled(_proseBase)

    // ONE padding value, used by BOTH the width and the content margins. They
    // used to disagree, and every small capsule came out narrower than its own
    // contents asked for.
    readonly property real contentInset: _sm ? Style.space3 : _lg ? Style.space5 : Style.space4

    implicitHeight: _sm ? Style.controlHeightSm : _lg ? Style.controlHeightLg : Style.controlHeight
    implicitWidth: content.implicitWidth + leftPadding + rightPadding
    leftPadding: contentInset
    rightPadding: contentInset

    function activate(): void {
        if (root.enabled)
            root.clicked()
    }

    readonly property list<T.Action> actions: [
        T.Action { text: root.label; enabled: root.enabled; onTriggered: root.activate() }
    ]

    // The state matrix is the ladder's (`Style.tone`): ON and "asks loudly"
    // are both the accent's identity over the surface, hover lifts a step.
    // Disabled dims each role through the state matrix; opacity would make the
    // card, glyph and text show through one another as a composite.
    surfaceColor: Style.tone(Style.surface, layer.hovered, false,
        root.active || root.variant === "primary", root.enabled, root._accent)
    // A quiet variant at rest paints NOTHING. It is transparent rather than
    // surface-at-90%, which is the difference between a control that sits on
    // the surface and one that is part of it.
    surfaceOpacity: root._quiet && !root.active && !(layer.hovered && root.enabled)
        ? 0
        : Style.surfaceOpacity

    Behavior on surfaceColor {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }
    Behavior on surfaceOpacity {
        NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    background: Card {
        radius: root.radius
        surfaceColor: root.surfaceColor
        surfaceOpacity: root.surfaceOpacity
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
            size: root._sm ? Style.iconSm : root._lg ? Style.iconLg : Style.iconMd
            color: root._prose
        }
        Prose {
            id: label
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            role: "label"
            color: root._prose
            // The label is the one place a size axis still reads through to
            // type: a small control with a body-sized label is not a small
            // control. Everything else about the role stays the role's.
            font.pixelSize: root._sm ? Style.textXs : root._lg ? Style.textMd : Style.textSm
        }
        Prose {
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            visible: root.detail.length > 0
            role: "reading"
            font.pixelSize: Style.textXs
            color: root.enabled ? root._accent : Style.disabled(root._accent)
            text: root.detail
        }
    }

    // Growth and press come from the layer, which owns the one response curve.
    // A pill this wide takes a smaller step than an icon does.
    StateLayer {
        id: layer
        anchors.fill: parent
        interactive: root.enabled
        focused: root.focused
        focusRadius: root.radius
        hoverScale: Motion.capsuleHoverScale
        pressScale: Motion.microPopScale
        onClicked: {
            root.forceActiveFocus()
            root.activate()
        }
    }

    Keys.onReturnPressed: event => { event.accepted = true; root.activate() }
    Keys.onEnterPressed: event => { event.accepted = true; root.activate() }
    Keys.onSpacePressed: event => { event.accepted = true; root.activate() }
}
