import QtQuick

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
// label — so the tile never has to be read twice. Armed outranks selected:
// what happens next matters more than what is picked.
Item {
    id: root
    required property string icon
    required property string label
    // Text shown while `armed`; when empty the armed state reuses `label`.
    property string confirmLabel: ""
    property bool selected: false
    property bool armed: false
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
    opacity: enabled ? 1 : Style.opacityDisabled
    readonly property color stateColor: armed ? armedColor : selected ? accent : Style.text
    readonly property string shownLabel: armed && confirmLabel.length > 0 ? confirmLabel : label
    // Armed is a selection wearing the danger colour: the same identity tint,
    // a different accent.
    Surface {
        anchors.fill: parent
        radius: Style.radiusMd
        selected: root.selected || root.armed
        accent: root.armed ? root.armedColor : root.accent
    }
    Column {
        anchors.centerIn: parent
        spacing: Style.space1
        SvgIcon { anchors.horizontalCenter: parent.horizontalCenter; name: root.icon; size: Style.iconLg; color: root.stateColor }
        Prose {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "metadata"
            color: root.armed || root.selected ? root.stateColor : Style.textMuted
            text: root.shownLabel
        }
    }
    StateLayer {
        anchors.fill: parent
        interactive: root.enabled
        focused: root.focused
        focusRadius: Style.radiusMd
        hoverScale: 1.06
        pressScale: .94
        onClicked: root.activated()
        onHoveredChanged: { if (hovered) root.entered(); else root.exited(); }
    }

    // A tile is a button, and a button answers a key. Without these the only
    // way to fire one was the pointer, on a surface a person reaches by
    // keybind.
    Keys.onSpacePressed: if (root.enabled) root.activated()
    Keys.onReturnPressed: if (root.enabled) root.activated()
}
