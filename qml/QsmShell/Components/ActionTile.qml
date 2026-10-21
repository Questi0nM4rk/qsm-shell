import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// A TILE: an icon over its label, in a box big enough to hit without aiming.
//
// It was called `SessionButton`, after the one surface that happened to use
// it — the tell the library's own laws name. What it actually is: the shape a
// SET of equally-weighted choices takes when they are laid out as a column or
// a grid rather than inline. A `Capsule` is the inline form and this is the
// stacked one, and they are not one type with a layout flag: a tile has a
// fixed footprint so a set of them lines up, and it carries an ARMED state,
// because a grid of consequential choices is exactly where arming belongs.
//
// The host owns which tile is selected and which is armed — the keyboard has
// to be able to fire the selected one, and "which is armed" must have exactly
// one answer across the set.
//
// Three states, each the SAME three marks changing together — fill, glyph,
// label — so the tile never has to be read twice. Selected is a solid fill in
// `accent` with `textOnPrimary` content (spec 08); armed is the same in
// `armedColor`. Armed outranks selected: what happens next matters more than
// what is picked.
T.Control {
    id: root
    required property string icon
    required property string label
    // Text shown while `armed`; when empty the armed state reuses `label`.
    property string confirmLabel: ""
    property bool selected: false
    property bool armed: false
    // The tile's resting glyph and label wear the danger colour: the one
    // action that cannot be undone is named before it is ever armed. Armed and
    // selected still outrank it.
    property bool danger: false
    property color accent: Style.accent
    property color armedColor: Style.danger
    property real buttonWidth: Style.tileWidth
    property real buttonHeight: Style.tileHeight
    // Keyboard focus. Defaults to this item's own, so a control that takes
    // focus rings without wiring; a list that owns focus for its rows binds it.
    property bool focused: root.activeFocus
    signal entered
    signal exited
    signal activated

    implicitWidth: buttonWidth
    implicitHeight: buttonHeight
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true

    Accessible.role: Accessible.Button
    Accessible.name: root.shownLabel

    readonly property bool _filled: armed || selected
    readonly property color _baseColor: _filled ? Style.textOnPrimary : danger ? armedColor : Style.text
    // Disabled dims each painted role through the colour, never through a
    // composite opacity: opacity would dim every child separately and let a
    // translucent glyph show the translucent body through itself.
    readonly property color stateColor: root.enabled ? _baseColor : Style.disabled(_baseColor)
    readonly property string shownLabel: armed && confirmLabel.length > 0 ? confirmLabel : label

    function activate(): void {
        if (root.enabled)
            root.activated()
    }

    readonly property list<T.Action> actions: [
        T.Action { text: root.shownLabel; enabled: root.enabled; onTriggered: root.activate() }
    ]

    // Selected or armed is a solid fill, not a tint; armed wears its own
    // colour. Surface dims the fill when disabled.
    background: Surface {
        enabled: root.enabled
        hovered: stateLayer.hovered
        pressed: stateLayer.pressed
        radius: Style.radiusMd
        base: root.armed ? root.armedColor : root.selected ? root.accent : Style.surface
    }
    contentItem: Item {
        Column {
            anchors.centerIn: parent
            spacing: Style.space1
            SvgIcon { anchors.horizontalCenter: parent.horizontalCenter; name: root.icon; size: Style.iconLg; color: root.stateColor
                Behavior on color { ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }
            }
            Prose {
                anchors.horizontalCenter: parent.horizontalCenter
                // Narrower than the body so ElideRight has a width to act on.
                width: Math.min(implicitWidth, root.buttonWidth - 2 * Style.space1)
                role: "metadata"
                font.pixelSize: Style.textSm
                color: root._filled || root.danger ? root.stateColor : root.enabled ? Style.textMuted : Style.disabled(Style.textMuted)
                text: root.shownLabel
                Behavior on color { ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }
            }
        }
    }
    StateLayer {
        id: stateLayer
        anchors.fill: parent
        pressScale: Motion.pressScale
        interactive: root.enabled
        focused: root.focused
        focusRadius: Style.radiusMd
        onClicked: {
            root.forceActiveFocus()
            root.activate()
        }
        onHoveredChanged: { if (hovered) root.entered(); else root.exited(); }
    }

    // A tile is a button, and a button answers a key. Without these the only
    // way to fire one was the pointer, on a surface a person reaches by
    // keybind. Every route shares `activate()`, so the disabled guard lives
    // in exactly one place.
    Keys.onSpacePressed: event => { event.accepted = true; root.activate() }
    Keys.onReturnPressed: event => { event.accepted = true; root.activate() }
    Keys.onEnterPressed: event => { event.accepted = true; root.activate() }
}
