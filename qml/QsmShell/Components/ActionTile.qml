import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// A TILE: an icon over its label, in a box big enough to hit without aiming.
//
// It is the shape a SET of equally-weighted choices takes when they are laid
// out as a column or a grid rather than inline. A `Capsule` is the inline
// form and this is the stacked one, and they are not one type with a layout
// flag: a tile has a fixed footprint so a set of them lines up, and it carries
// an ARMED state, because a grid of consequential choices is exactly where
// arming belongs.
//
// The host owns which tile is selected and which is armed — the keyboard has
// to be able to fire the selected one, and "which is armed" must have exactly
// one answer across the set.
//
// Three states, each the SAME three marks changing together — fill, glyph,
// label — so the tile never has to be read twice. Selected is a solid fill in
// `accent` with `textOnPrimary` content; armed is the same in
// `armedColor`. Armed outranks selected: what happens next matters more than
// what is picked.
T.Control {
    id: root
    required property string icon
    required property string label
    // Text shown while `armed`; when empty the armed state reuses `label`.
    property string confirmLabel: ""
    // A Control preset name. The footprint is the tile's own (`Style.tileWidth`
    // by `Style.tileHeight` at md) times the preset's share of md, snapped to
    // the rhythm, and the glyph, label and gap follow it.
    property string size: "md"
    property bool selected: false
    property bool armed: false
    // The tile's resting glyph and label wear the danger colour: the one
    // action that cannot be undone is named before it is ever armed. Armed and
    // selected still outrank it.
    property bool danger: false
    property color accent: Style.accent
    property color armedColor: Style.danger
    readonly property real _scale: Style.size("ActionTile", root.size) / Style.size("ActionTile", "md")
    property real buttonWidth: Style.rhythm(Style.tileWidth * root._scale)
    property real buttonHeight: Style.rhythm(Style.tileHeight * root._scale)
    // Keyboard focus. Defaults to this item's own, so a control that takes
    // focus rings without wiring; a list that owns focus for its rows binds it.
    property bool focused: root.activeFocus
    // The most a side may grow on hover, for a set whose tiles sit `gap` apart:
    // pass `Motion.hoverGrowthWithin(gap)`. The focus ring follows the growth,
    // so the room a tile needs is its growth plus the ring.
    property real growthCap: Infinity
    // A key is down: the tile reads as pressed until it is released.
    property bool _keyHeld: false
    signal entered
    signal exited
    signal activated

    implicitWidth: buttonWidth
    implicitHeight: buttonHeight
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true

    Accessible.role: Accessible.Button
    Accessible.name: root.shownLabel
    Accessible.selected: root.selected
    Accessible.onPressAction: root.activate()

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
        x: -stateLayer.growth
        y: -stateLayer.growth
        width: root.width + 2 * stateLayer.growth
        height: root.height + 2 * stateLayer.growth
        enabled: root.enabled
        hovered: stateLayer.hovered
        pressed: stateLayer.pressed
        radius: Style.radiusBody
        base: root.armed ? root.armedColor : root.selected ? root.accent : Style.surface
    }
    contentItem: Item {
        Column {
            anchors.centerIn: parent
            spacing: Style.rhythm(Style.space1 * root._scale)
            SvgIcon { anchors.horizontalCenter: parent.horizontalCenter; name: root.icon; size: Style.iconNear(Style.iconLg * root._scale); color: root.stateColor
                Behavior on color { ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }
            }
            Prose {
                anchors.horizontalCenter: parent.horizontalCenter
                // Narrower than the body so ElideRight has a width to act on.
                width: Math.min(implicitWidth, root.buttonWidth - 2 * Style.space1)
                role: "metadata"
                font.pixelSize: Style.textNear(Style.textSm * root._scale)
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
        focusRadius: Style.radiusBody
        manualPressOverride: root._keyHeld
        growthCap: root.growthCap
        onClicked: {
            root.forceActiveFocus()
            root.activate()
        }
        onHoveredChanged: { if (hovered) root.entered(); else root.exited(); }
    }

    // A tile is a button, and a button answers a key: Space, Return and Enter
    // read as pressed while held and act once on release, and a held key
    // repeats nothing, so one hold can never arm a tile and then confirm it.
    // Every route shares `activate()`, so the disabled guard lives in exactly
    // one place.
    function _isActivationKey(key: int): bool {
        return key === Qt.Key_Space || key === Qt.Key_Return || key === Qt.Key_Enter;
    }
    Keys.onPressed: event => {
        if (!root._isActivationKey(event.key))
            return;
        event.accepted = true;
        root._keyHeld = root.enabled;
    }
    Keys.onReleased: event => {
        if (!root._isActivationKey(event.key) || !root._keyHeld)
            return;
        event.accepted = true;
        root._keyHeld = false;
        root.activate();
    }
    onActiveFocusChanged: if (!root.activeFocus) root._keyHeld = false
}
