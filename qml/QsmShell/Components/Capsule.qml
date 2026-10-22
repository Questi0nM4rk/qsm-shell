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
// keyboard and its own unavailability, because "no box at rest" is no reason
// to leave those undefined.
T.Control {
    id: root

    property alias icon: icon.name
    property alias label: label.text
    property string detail: ""
    property color accentColor: Style.accent
    // The rung the body rests on: `surface` over the band, `overlay` when the
    // capsule sits on a surface card (a body the colour of its ground is no
    // body at all).
    property color base: Style.surface
    // One control radius across a row of controls; only a glyph-only capsule
    // is a pill.
    property real radius: root._glyphOnly ? Style.radiusPill : Style.radiusBody

    // ghost | secondary | primary | destructive
    property string variant: "secondary"
    // A Control preset name: xs | sm | md | lg
    property string size: "md"

    // The control is ON: a toggle engaged, a filter applied.
    property bool active: false
    // The host marks a capsule that is a toggle, so a screen reader hears
    // "checked" / "not checked" for `active` and not a plain button. A capsule
    // whose `active` is a status (a scan running) stays a button.
    property bool checkable: false
    // The name a screen reader speaks when there is no label. A glyph-only
    // capsule must carry one; the label wins when it exists.
    property string accessibleName: ""
    // What a host would otherwise have to derive. (`hovered` and `visualFocus`
    // are the control's own.)
    readonly property bool pressed: stateLayer.pressed

    signal clicked

    // T.Control and not T.AbstractButton: the button template owns `icon` as a
    // group property, and the glyph here is its name.
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true

    Accessible.role: Accessible.Button
    Accessible.name: root._name
    Accessible.checkable: root.checkable
    Accessible.checked: root.checkable && root.active
    Accessible.onPressAction: root.activate()

    readonly property string _name: root.label.length > 0 ? root.label : root.accessibleName
    Component.onCompleted: {
        if (root._name.length === 0)
            console.warn("Capsule: no label and no accessibleName -- a screen reader hears an unnamed button")
    }

    readonly property real _box: Style.size("Capsule", root.size)
    // One scale per instance: every measurement is md's times this.
    readonly property real _s: root._box / Style.size("Capsule", "md")
    readonly property bool _glyphOnly: root.label.length === 0 && root.detail.length === 0
    readonly property bool _quiet: variant === "ghost" || variant === "destructive"
    readonly property bool _primary: variant === "primary"
    readonly property color _accent: variant === "destructive" ? Style.danger : accentColor

    // What the content sits on. A quiet capsule at rest paints no body, so its
    // ground is the host's: the band, which is also what `disabled` blends to.
    readonly property bool _bodyShown: !root._quiet || root.active || stateLayer.hovered || stateLayer.pressed
    readonly property color _ground: root._bodyShown ? body._fill : Style.band

    // Selected is identity (AGENTS.md, surface ladder): the accent tint on the
    // body AND accent content. A ghost rests muted and brightens under the
    // pointer; primary is the one filled action, `textOnPrimary` on `primary`.
    // A reading is supporting information, never the accent.
    readonly property color _proseBase: _primary ? Style.textOnPrimary
        : variant === "destructive" ? Style.danger : active ? _accent
        : variant === "ghost" && !stateLayer.hovered ? Style.textMuted : Style.text
    readonly property color _readingBase: _primary ? Style.textOnPrimary : Style.textMuted
    // The label settles with the body's fill, or it would land before it.
    property color _prose: root.enabled ? Style.legible(root._proseBase, root._ground) : Style.disabled(root._proseBase)
    Behavior on _prose {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    // ONE padding value, used by BOTH the width and the content margins, so a
    // small capsule is never narrower than its own contents ask for. A
    // glyph-only capsule is the box itself, its glyph centred.
    readonly property real contentInset: root._glyphOnly ? 0 : Style.rhythm(Style.space4 * root._s)

    implicitHeight: root._box
    // A label longer than a control is wide elides; a host may set `width` for less.
    implicitWidth: root._glyphOnly ? root._box
        : Math.min(content.implicitWidth + leftPadding + rightPadding, Style.controlWidth)
    leftPadding: contentInset
    rightPadding: contentInset

    function activate(): void {
        if (root.enabled)
            root.clicked()
    }

    readonly property list<T.Action> actions: [
        T.Action { text: root._name; enabled: root.enabled; onTriggered: root.activate() }
    ]

    // Hover grows the capsule (StateLayer) AND lifts its colour; a press only
    // recolours it. A quiet variant at rest paints nothing, so it is part of
    // the surface that holds it; the body fades rather than the colour, so the
    // colour never passes through a translucent black.
    background: Surface {
        id: body
        x: -stateLayer.growth
        y: -stateLayer.growth
        width: root.width + 2 * stateLayer.growth
        height: root.height + 2 * stateLayer.growth
        base: root._primary ? Style.primary : root.base
        accent: root._accent
        hovered: stateLayer.hovered
        pressed: stateLayer.pressed
        selected: root.active && !root._primary
        radius: root.radius
        opacity: root._bodyShown ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }

    // The group sits centred in a capsule wider than its content, and a
    // narrower one shrinks the label to an ellipsis.
    contentItem: Item {
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        RowLayout {
            id: content
            x: Math.max(0, Math.round((parent.width - width) / 2))
            width: Math.min(implicitWidth, parent.width)
            height: parent.height
            spacing: Style.space2

            // Every child spans the row and centres its own content in it: a
            // RowLayout aligns text on its BASELINE and an icon has none, which
            // sat the label half a pixel below the pill's centre.
            SvgIcon {
                id: icon
                // A layout skips an invisible child AND its spacing, so a
                // text-only pill closes up around the missing glyph.
                visible: icon.name.length > 0
                Layout.alignment: Qt.AlignVCenter
                size: Style.glyphBeside(root._box)
                color: root._prose
            }
            Prose {
                id: label
                visible: label.text.length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
                role: "label"
                color: root._prose
                // The label scales with the box: a small control with a
                // body-sized label is not a small control.
                font.pixelSize: Style.textNear(Style.textSm * root._s)
            }
            Prose {
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
                visible: root.detail.length > 0
                // A value, so the technical face; supporting, so not bold.
                role: "metadata"
                technical: true
                color: root.enabled ? root._readingBase : Style.disabled(root._readingBase)
                text: root.detail
            }
        }
    }

    // Growth and press come from the layer, which owns the one response curve.
    // A pill this wide takes a smaller step than an icon does.
    StateLayer {
        id: stateLayer
        anchors.fill: parent
        interactive: root.enabled
        focusRadius: root.radius
        hoverScale: Motion.capsuleHoverScale
        bodyGrows: true
        manualPressOverride: keys.held
        onClicked: {
            root.forceActiveFocus()
            root.activate()
        }
    }

    // A held key acts once, on release: a toggle would flicker at the
    // key-repeat rate.
    ActivationKeys {
        id: keys
        available: root.enabled
        onActivated: root.activate()
    }
    Keys.forwardTo: [keys]
}
