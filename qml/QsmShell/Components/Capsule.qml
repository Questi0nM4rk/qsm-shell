import QtQuick
import QtQuick.Layouts

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
Card {
    id: root

    property alias icon: icon.name
    property alias label: label.text
    property string detail: ""
    property color accentColor: Style.accent

    // ── the two axes ────────────────────────────────────────────────────
    // ghost | secondary | primary | destructive
    property string variant: "secondary"
    // sm | md | lg
    property string size: "md"

    // ── consumer-owned state ────────────────────────────────────────────
    // The control is ON: a toggle engaged, a filter applied.
    property bool active: false
    // Keyboard focus. Defaults to this item's own, so a Capsule that takes
    // focus rings without wiring; a list that owns focus for its rows binds it.
    property bool focused: root.activeFocus

    signal clicked

    readonly property bool _sm: size === "sm"
    readonly property bool _lg: size === "lg"
    readonly property bool _quiet: variant === "ghost" || variant === "destructive"
    readonly property color _accent: variant === "destructive" ? Style.danger : accentColor
    readonly property color _prose: variant === "destructive" ? Style.danger : Style.text

    // ONE padding value, used by BOTH the width and the content margins. They
    // used to disagree, and every small capsule came out narrower than its own
    // contents asked for.
    readonly property real padding: _sm ? Style.space3 : _lg ? Style.space5 : Style.space4

    implicitHeight: _sm ? Style.controlHeightSm : _lg ? Style.controlHeightLg : Style.controlHeight
    implicitWidth: content.implicitWidth + padding * 2
    radius: Style.radiusPill
    // Unavailable, not invisible: the control still says what it would do.
    opacity: enabled ? 1 : Style.opacityDisabled

    // The state matrix, in one place. Reading down: what the surface is when
    // the control is ON, when it asks loudly, and when it is merely there.
    surfaceColor: {
        const hot = layer.hovered && root.enabled;
        if (root.active)
            return Qt.tint(Style.surfaceRaised,
                Qt.rgba(root._accent.r, root._accent.g, root._accent.b, hot ? 0.2 : 0.14));
        if (root.variant === "primary")
            return Qt.tint(Style.surfaceRaised,
                Qt.rgba(root._accent.r, root._accent.g, root._accent.b, hot ? 0.16 : 0.1));
        return hot ? Style.surfaceHover : Style.surface;
    }
    // A quiet variant at rest paints NOTHING. It is transparent rather than
    // surface-at-90%, which is the difference between a control that sits on
    // the surface and one that is part of it.
    surfaceOpacity: root._quiet && !root.active && !(layer.hovered && root.enabled)
        ? 0
        : Style.surfaceOpacity

    Behavior on color {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }
    Behavior on opacity {
        NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
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
            color: root._accent
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
        hoverScale: 1.04
        pressScale: 0.97
        onClicked: root.clicked()
    }
}
