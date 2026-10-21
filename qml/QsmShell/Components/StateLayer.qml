import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// THE interaction primitive, and THE place every interaction state is defined.
//
// A control has five states, not one: at rest, under the pointer, pressed,
// carrying keyboard focus, and unavailable. Leaving any of them undefined does
// not remove it — it just means the control answers that state by accident.
//
//   rest        nothing. The shell paints no box around a thing at rest.
//   hover       the affordance grows slightly AND changes colour. Growth is a
//               whole number of DEVICE pixels per side (`growth`), the nearest
//               to what `hoverScale` asks and never less than one while the
//               ratio asks for any, so no edge lands between two device
//               pixels and a body too small for the ratio still answers. The
//               colour is the body's own, through `Style.tone`, or this
//               layer's `hoverTint` disc for a glyph that has no body of its
//               own.
//   press       colour only on a body (`pressScale` is 1 by default); a glyph
//               that has no body to recolour passes its own `pressScale` and
//               pushes in on a faster curve (a negative `growth`), so a click
//               is acknowledged even when the action it starts takes time.
//   focus       an accent ring outside the body (see below), for KEYBOARD
//               focus only. A keyboard user needs to know where they are
//               without anything moving; a pointer user already knows. A text
//               field's caret is its own focus mark.
//   disabled    the host dims itself BY COLOUR -- every painted role through
//               `Style.disabled(colour)`, never `opacity` on the composite,
//               which would dim each child separately and let a translucent
//               thumb show the translucent fill through it. The layer simply
//               stops answering, and stops offering a hand it will not shake.
//
// The layer moves nothing. It reports `growth`, and the host applies it to the
// body it paints: a body's own margins (or its x, y, width and height) change
// by `growth` on every side while its content stays a sibling at its own size,
// so nothing is resampled, and a side that joins a neighbour stays flush. A
// bare glyph grows through its `size`. A Scale transform would put the content
// of a body between two device pixels, which is why there is none.
Item {
    id: root

    // A template host (T.Control and friends) already owns hovered, pressed,
    // visualFocus and enabled. Given one, the layer READS those and stops
    // running handlers of its own, so a control has one source of every
    // state. `var`, not `Item`: the properties live on the control subclass
    // and a typed Item would make every read a qmllint warning.
    property var host: null
    readonly property bool _hosted: host !== null && host !== undefined

    property bool interactive: _hosted ? host.enabled : true
    // A hover-only trigger still answers pointer arrival, but must not offer a
    // press or emit a click for an action it deliberately does not own.
    property bool clickable: true
    property int gesturePolicy: TapHandler.DragThreshold
    property bool manualHoverOverride: false
    property bool manualPressOverride: false
    // The smaller side of the body AT REST, which `hoverScale` is a ratio of. It
    // is the layer's own by default; a host whose layer spans more than its body
    // (a row, a hit area) or whose body is the very item that grows states it,
    // as a number that does not depend on `growth`.
    property real extent: Math.min(root.width, root.height)
    // How much the body should grow, as a ratio of `extent`; `growth` is the
    // whole-device-pixel answer to it.
    property real hoverScale: Motion.hoverScale
    // The most a side may grow, in logical px, for a host whose neighbours sit
    // `gap` away (`Motion.hoverGrowthWithin`). Rounded down to whole device
    // pixels, so the cap holds at any ratio; 0 keeps a host that cannot grow
    // (a row in a clipping list) still.
    property real growthCap: Infinity
    // 1: a press recolours a body and never resizes it. A bare glyph with no
    // body passes `Motion.pressScale` (or its own) to push in.
    property real pressScale: 1
    // Paints a `Style.tone` disc at `focusRadius` over the layer while hovered
    // or pressed, grown by `growth` on every side, for a bare glyph that has no
    // body to recolour.
    property bool hoverTint: false

    // Keyboard focus, which is when the ring shows. Hosted, Qt's `visualFocus`
    // (tab, backtab, shortcut) says it; a plain item says it when its parent
    // holds the active focus (it has no `visualFocus`). A host whose focus lives on a DESCENDANT (a text input, a slider
    // thumb) sets this itself: a `T.Control` is not a focus scope, so its own
    // `visualFocus` stays false while the descendant holds the focus. A host
    // that passes `activeFocus` here gets the ring on a click too, unless the
    // click came through this layer's own tap, which `_pointerFocus` hides
    // until focus is lost.
    property bool focused: _hosted ? (host.visualFocus ?? false)
        : (root.parent as T.Control) ? ((root.parent as T.Control).visualFocus ?? false)
        : (root.parent?.activeFocus ?? false)
    property bool _pointerFocus: false
    onFocusedChanged: if (!root.focused) root._pointerFocus = false
    // The corner the ring follows. The host states it, because `parent` is a
    // plain Item as far as the type system is concerned and probing it for a
    // radius is a warning plus a guess.
    property real focusRadius: 0
    property color focusColor: Style.focus

    readonly property bool pointerHovered: enabled && interactive && (_hosted ? host.hovered : hover.hovered)
    readonly property bool hovered: enabled && interactive && (pointerHovered || manualHoverOverride)
    readonly property bool pressed: enabled && interactive && ((_hosted ? (host.pressed ?? false) : tap.pressed) || manualPressOverride)
    signal clicked
    readonly property list<T.Action> actions: [
        T.Action {
            text: "Activate"
            enabled: root.enabled && root.interactive && root.clickable && !root._hosted
            onTriggered: root.activate()
        }
    ]

    function activate(): bool {
        if (!root.enabled || !root.interactive || !root.clickable || root._hosted)
            return false
        root.clicked()
        return true
    }

    // A hover-enter that is allowed to CLAIM the selection. A list binds its
    // cursor to this rather than to `hovered`, and then a pointer that never
    // moved cannot take the selection from the keyboard — see
    // Interaction.pointerSelects, which the consumer owns.
    signal hoveredEntered

    onPointerHoveredChanged: {
        if (root.pointerHovered && Interaction.pointerSelects)
            root.hoveredEntered();
    }

    // 1 at rest. Exposed as a number, not merely applied, so a host can drive
    // something more apt than scale with it while still following one curve.
    property real response: pressed ? pressScale : hovered ? hoverScale : 1

    Rectangle {
        anchors.fill: parent
        anchors.margins: -root.growth
        radius: Math.max(0, root.focusRadius + root.growth)
        color: Style.tone(Style.surface, root.hovered, root.pressed, false, true, Style.accent)
        opacity: root.hoverTint && (root.hovered || root.pressed) ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }

    Behavior on response {
        NumberAnimation {
            duration: root.pressed ? Motion.press : Motion.micro
            easing.type: Motion.standardEasing
        }
    }

    readonly property real _dpr: root.Window.window?.devicePixelRatio ?? 1

    // Per side, in whole DEVICE pixels: what `response` asks of `extent`,
    // rounded to the pixel grid, at least one pixel while it asks for anything,
    // and held under `growthCap`. A fractional scale puts an edge between two
    // pixels and resamples what is inside, so growth is a size change in
    // pixels, never a ratio on the painted item. Negative while pressed in.
    function _growthAt(response: real): real {
        const wanted = root.extent * (response - 1) / 2;
        if (wanted === 0)
            return 0;
        const pixels = Math.max(1, Math.round(Math.abs(wanted) * root._dpr));
        const snapped = Math.sign(wanted) * pixels / root._dpr;
        return Math.min(snapped, Math.floor(root.growthCap * root._dpr) / root._dpr);
    }
    readonly property real growth: root._growthAt(root.response)
    // What a full hover would grow a side by: the room a container must keep
    // for the host's body.
    readonly property real maxGrowth: root._growthAt(root.hoverScale)

    // One implementation of the focus ring, so a keyboard user meets the same
    // mark on every control instead of whatever each surface remembered to
    // draw. Outside the painted body, never inside it: a ring on the body's own
    // edge vanishes on a full accent fill. Gap and stroke are both
    // `spaceTight` in whole device pixels; the outer radius is the body's plus
    // both, the reverse of `Style.childRadius`, so the ring stays concentric.
    // The gap is measured from THIS LAYER's edge, so a layer sized to its body
    // (not outset from it) is what puts the ring a half step clear.
    Rectangle {
        readonly property real _stroke: Style.stroke(Style.indicatorWidth, root)
        readonly property real _reach: _stroke * 2
        anchors.fill: parent
        anchors.margins: -_reach
        z: -1
        // Hidden only once the fade has finished, so a ring leaves as it came.
        visible: opacity > 0
        color: "transparent"
        radius: root.focusRadius + _reach
        border.width: _stroke
        border.color: root.focusColor
        opacity: root.focused && !root._pointerFocus && root.enabled && root.interactive ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }

    HoverHandler {
        id: hover
        enabled: !root._hosted
        cursorShape: root.interactive && root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        id: tap
        enabled: root.interactive && root.clickable && !root._hosted
        gesturePolicy: root.gesturePolicy
        onTapped: root.activate()
        // A pointer press that takes focus must not ring it; a press on a host
        // that already holds focus keeps its ring. Released without taking
        // focus, the mark is cleared so a later Tab still rings.
        onPressedChanged: {
            if (pressed)
                root._pointerFocus = !root.focused;
            else
                Qt.callLater(() => { if (!root.focused) root._pointerFocus = false; });
        }
    }
}
