pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Style

// A surface that belongs to another surface: it appears NEXT TO the thing that
// summoned it and it goes away again.
//
// It is the PLACEMENT, not a finished control. Where an anchored panel sits,
// which way it has to flip to stay on screen, and how long a pointer has to
// linger before anything happens. That arithmetic is where anchored surfaces
// actually go wrong — a panel that is right in the middle of a screen and
// wrong at its edge is wrong — and it is the same arithmetic for a tooltip, a
// hover popout and a click menu.
//
// It is NOT all three of those. They differ in focus entry and return, in
// keyboard activation, and in whether their content can be reached at all,
// and a component claiming to be all of them would be none of them properly.
// Compose the control you need over this; do not expect this to be it.
//
// ── what it owns ─────────────────────────────────────────────────────────
// Position, flipping, clamping, and the delays.
//
// ── what it does NOT own ─────────────────────────────────────────────────
// Whether it is open. It REQUESTS — `openRequested` when a trigger has been
// held long enough, `dismissRequested` when the pointer has been gone long
// enough — and the surface decides. A popout the pointer has moved INTO must
// not close because the pointer left its trigger; a menu guarding an armed
// action must not close on a stray move. Only the surface knows, and a
// component that opens and closes itself has to be told about every surface it
// might ever sit in.
Item {
    id: root

    // What it points at. Coordinates are read through this item's scene
    // position, so the anchor may live anywhere in the tree.
    required property Item anchorItem
    // top | bottom | left | right — the side of the anchor it prefers.
    property string placement: "bottom"
    // start | center | end — where along that side it lines up.
    property string alignment: "center"
    property real gap: Style.space2
    // The box it must stay inside. Defaults to this item's parent, which is
    // the surface hosting the popover.
    property Item bounds: root.parent

    // hover | press | manual
    property string trigger: "manual"
    property bool open: false
    // A tooltip that appears instantly is a tooltip that appears while the
    // pointer is only passing through.
    property int openDelay: Motion.hoverIntent
    property int closeDelay: Motion.hoverGrace

    // Content goes straight in. An intermediate host that fills the popover
    // cannot also be what the popover sizes itself from: `implicitWidth:
    // panel.implicitWidth` over an `anchors.fill` Item is 0 forever.
    default property alias content: contentHost.data

    signal openRequested
    signal dismissRequested

    // The one route to open or close by request. The press TapHandler calls it,
    // and so does a host's key handler on the anchor: a pointer and a keyboard
    // never get two implementations of the same decision.
    function toggle(): void {
        if (root.open)
            root.dismissRequested();
        else
            root.openRequested();
    }

    // The pointer is over the anchor (hover trigger only) or over the popover
    // itself: the fact a host would otherwise re-derive to decide on closing.
    readonly property bool hovered: anchorHover.hovered || selfHover.hovered

    // Which side it ACTUALLY landed on, after flipping. A caller drawing a
    // tail or a seam needs this, not the preference.
    // The preferred side if it fits; otherwise the side with MORE room, not
    // simply the opposite one. Flipping blind is how a panel with too little
    // space on both sides ends up off the other edge instead of this one.
    readonly property string side: {
        switch (placement) {
        case "top": return _fitsAbove ? "top" : (_roomBelow > _roomAbove ? "bottom" : "top");
        case "bottom": return _fitsBelow ? "bottom" : (_roomAbove > _roomBelow ? "top" : "bottom");
        case "left": return _fitsLeft ? "left" : (_roomRight > _roomLeft ? "right" : "left");
        default: return _fitsRight ? "right" : (_roomLeft > _roomRight ? "left" : "right");
        }
    }

    // Anchor rectangle in this item's own coordinates.
    //
    // It is SAMPLED, not bound, and that is not laziness. An item's scene
    // position changes whenever any ancestor moves, and Qt Quick emits no
    // signal for that — a binding that reads `anchorItem.x` re-fires when the
    // anchor moves inside its own parent and stays silent when the parent
    // scrolls out from under it: a popover anchored to a row in a scrolling
    // list would sit where the row used to be.
    //
    // So it is resampled every frame while OPEN, and never while closed. The
    // assignment is a no-op when nothing moved, so a still popover costs one
    // `mapToItem` per frame and no bindings at all.
    property rect _anchor: Qt.rect(0, 0, 0, 0)

    function resample(): void {
        if (!root.anchorItem || !root.parent)
            return;
        const origin = root.anchorItem.mapToItem(root.parent, 0, 0);
        const next = Qt.rect(origin.x, origin.y, root.anchorItem.width, root.anchorItem.height);
        if (next !== root._anchor)
            root._anchor = next;
    }

    FrameAnimation {
        running: root.open || root.opacity > 0
        onTriggered: {
            root.resample();
            root.resampleBounds();
        }
    }

    onOpenChanged: if (root.open) { root.resample(); root.resampleBounds(); }
    Component.onCompleted: { root.resample(); root.resampleBounds(); }

    // The bounds rectangle in the SAME space as the anchor. Reading only its
    // width and height puts its origin at (0, 0), so a translated bounds item
    // (a panel inset inside a scene, the normal case) would be clamped
    // against the wrong rectangle.
    property rect _bounds: Qt.rect(0, 0, 0, 0)

    function resampleBounds(): void {
        if (!root.bounds || !root.parent)
            return;
        const origin = root.bounds.mapToItem(root.parent, 0, 0);
        const next = Qt.rect(origin.x, origin.y, root.bounds.width, root.bounds.height);
        if (next !== root._bounds)
            root._bounds = next;
    }

    // Room on each side, as a number rather than a yes/no. A flip that only
    // asks "does the preferred side fit" will happily flip to a side that does
    // not fit either; asking WHICH side has more room cannot.
    readonly property real _roomAbove: _anchor.y - _bounds.y - gap
    readonly property real _roomBelow: _bounds.y + _bounds.height - (_anchor.y + _anchor.height) - gap
    readonly property real _roomLeft: _anchor.x - _bounds.x - gap
    readonly property real _roomRight: _bounds.x + _bounds.width - (_anchor.x + _anchor.width) - gap

    readonly property bool _fitsAbove: _roomAbove >= height
    readonly property bool _fitsBelow: _roomBelow >= height
    readonly property bool _fitsLeft: _roomLeft >= width
    readonly property bool _fitsRight: _roomRight >= width

    // Along the anchor's cross axis: start / centre / end, then CLAMPED into
    // the bounds. Clamping after aligning is what keeps a centred popover on
    // a corner control from hanging off the screen.
    function _align(anchorStart: real, anchorSize: real, ownSize: real,
            origin: real, extent: real): real {
        const raw = root.alignment === "start" ? anchorStart
            : root.alignment === "end" ? anchorStart + anchorSize - ownSize
            : anchorStart + (anchorSize - ownSize) / 2;
        return root._clamp(raw, origin, extent, ownSize);
    }

    // Both axes end in a clamp. The cross axis is aligned then clamped; the
    // main axis is placed then clamped, because a side that does not fit still
    // has to put the panel somewhere a person can see it.
    function _clamp(position: real, origin: real, extent: real, ownSize: real): real {
        return Math.max(origin, Math.min(position, origin + Math.max(0, extent - ownSize)));
    }

    x: {
        switch (root.side) {
        case "left":
            return root._clamp(root._anchor.x - root.gap - root.width,
                root._bounds.x, root._bounds.width, root.width);
        case "right":
            return root._clamp(root._anchor.x + root._anchor.width + root.gap,
                root._bounds.x, root._bounds.width, root.width);
        default:
            return root._align(root._anchor.x, root._anchor.width, root.width,
                root._bounds.x, root._bounds.width);
        }
    }
    y: {
        switch (root.side) {
        case "top":
            return root._clamp(root._anchor.y - root.gap - root.height,
                root._bounds.y, root._bounds.height, root.height);
        case "bottom":
            return root._clamp(root._anchor.y + root._anchor.height + root.gap,
                root._bounds.y, root._bounds.height, root.height);
        default:
            return root._align(root._anchor.y, root._anchor.height, root.height,
                root._bounds.y, root._bounds.height);
        }
    }

    implicitWidth: contentHost.childrenRect.width
    implicitHeight: contentHost.childrenRect.height

    visible: opacity > 0
    opacity: open ? 1 : 0
    // It arrives from the side it sits on, by a short step. Far enough to read
    // as arriving, short enough not to read as flying in.
    // Under reduced motion there is no offset to travel: a one-shot position
    // animation is removed, not shortened.
    readonly property real _step: Style.reducedMotion ? 0 : Style.space2
    transform: Translate {
        x: root.open ? 0 : (root.side === "left" ? root._step : root.side === "right" ? -root._step : 0)
        y: root.open ? 0 : (root.side === "top" ? root._step : root.side === "bottom" ? -root._step : 0)

        Behavior on x {
            enabled: !Style.reducedMotion
            NumberAnimation { duration: Motion.medium; easing.type: root.open ? Motion.emphasizedEasing : Motion.exitEasing }
        }
        Behavior on y {
            enabled: !Style.reducedMotion
            NumberAnimation { duration: Motion.medium; easing.type: root.open ? Motion.emphasizedEasing : Motion.exitEasing }
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Motion.medium
            easing.type: root.open ? Motion.standardEasing : Motion.exitEasing
        }
    }

    // Deliberately unsized. `childrenRect` measures the bounding box of the
    // children regardless of the host's own size, so the popover can take its
    // size FROM the content — and giving the host a size taken from the
    // popover would close that circle into a binding loop.
    //
    // So the content states its own size, which is what a popover's content
    // does anyway: the panel decides how big it is and the popover wraps it.
    Item { id: contentHost }

    // ── triggering ──────────────────────────────────────────────────────
    // The popover watches the anchor, so a consumer using `hover` or `press`
    // wires nothing at all. `manual` leaves `open` entirely to the consumer.
    HoverHandler {
        id: anchorHover
        enabled: root.trigger === "hover"
        // Attached to the ANCHOR, not to this item: a popover that only knows
        // its own hover cannot open, because it is not there yet.
        parent: root.anchorItem
    }
    // Hovering the popover itself keeps it alive. A menu you cannot move the
    // pointer into is a menu you cannot use.
    HoverHandler { id: selfHover }

    TapHandler {
        enabled: root.trigger === "press"
        parent: root.anchorItem
        onTapped: root.toggle()
    }

    Timer {
        id: openTimer
        interval: root.openDelay
        // Asking, not opening. The surface may be holding a different tier
        // open on the same edge, and two surfaces on one hotspot is the
        // collision this component must not cause.
        onTriggered: root.openRequested()
    }
    Timer {
        id: closeTimer
        interval: root.closeDelay
        // Asking rather than closing: the surface may know the pointer is on
        // its way into a nested tier.
        onTriggered: root.dismissRequested()
    }

    onHoveredChanged: {
        if (root.trigger !== "hover")
            return;
        if (root.hovered) {
            closeTimer.stop();
            if (!root.open)
                openTimer.restart();
        } else {
            openTimer.stop();
            if (root.open)
                closeTimer.restart();
        }
    }

    // Escape closes from anywhere in the window while open, so a keyboard
    // user who opened it from a focused trigger is not stranded: this item is
    // not focusable and a key handler on it only hears its own descendants. A
    // shortcut outranks a focused child's key handler; a child that needs
    // Escape for itself (a nested menu, an editor) accepts it in
    // Keys.onShortcutOverride.
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        context: Qt.WindowShortcut
        onActivated: root.dismissRequested()
    }
}
