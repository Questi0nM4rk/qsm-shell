pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import QtQuick.Window

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
// Position, flipping, clamping, and the delays; on the device grid, so an
// edge never lands between two pixels. The keyboard follows the trigger: a
// press trigger answers the anchor's own activation (a button's Space and
// Return, not only a tap), a hover trigger also opens for an anchor the
// keyboard has reached, and a close with the focus inside hands it back to
// the anchor.
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

    // The pointer is over the anchor (hover trigger only), over the popover
    // itself or over the strip between them: the fact a host would otherwise
    // re-derive to decide on closing.
    readonly property bool hovered: anchorHover.hovered || selfHover.hovered || corridorHover.hovered

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
    //
    // The bounds are sampled in the SAME space as the anchor. Reading only
    // their width and height puts their origin at (0, 0), so a translated
    // bounds item (a panel inset inside a scene, the normal case) would be
    // clamped against the wrong rectangle.
    property rect _anchor: Qt.rect(0, 0, 0, 0)
    property rect _bounds: Qt.rect(0, 0, 0, 0)

    function _rectOf(item: Item): rect {
        const origin = item.mapToItem(root.parent, 0, 0);
        return Qt.rect(origin.x, origin.y, item.width, item.height);
    }

    function resample(): void {
        if (!root.parent)
            return;
        if (root.anchorItem)
            root._anchor = root._rectOf(root.anchorItem);
        if (root.bounds)
            root._bounds = root._rectOf(root.bounds);
    }

    FrameAnimation {
        running: root.open || root.opacity > 0
        onTriggered: root.resample()
    }

    // Does the keyboard sit inside the panel? Asked as it closes, while the
    // content is still laid out, because an item that hides takes its focus
    // with it and leaves the keyboard on nothing.
    function _holdsFocus(): bool {
        for (let item = root.Window.window?.activeFocusItem ?? null; item; item = item.parent) {
            if (item === root)
                return true;
        }
        return false;
    }

    onOpenChanged: {
        if (root.open) {
            root.resample();
        } else if (root.anchorItem && root._holdsFocus()) {
            root.anchorItem.forceActiveFocus();
        }
    }
    Component.onCompleted: root.resample()

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
        return Style.snap(Math.max(origin, Math.min(position, origin + Math.max(0, extent - ownSize))), root);
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

    implicitWidth: Style.snapUp(contentHost.childrenRect.width, root)
    implicitHeight: Style.snapUp(contentHost.childrenRect.height, root)

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
            NumberAnimation { duration: root.open ? Motion.medium : Motion.exit(Motion.medium); easing.type: root.open ? Motion.emphasizedEasing : Motion.exitEasing }
        }
        Behavior on y {
            enabled: !Style.reducedMotion
            NumberAnimation { duration: root.open ? Motion.medium : Motion.exit(Motion.medium); easing.type: root.open ? Motion.emphasizedEasing : Motion.exitEasing }
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: root.open ? Motion.medium : Motion.exit(Motion.medium)
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

    // The path between them. The gap belongs to neither, so a pointer that
    // lingers in it would leave both and close the panel after the grace
    // period; this strip, from the anchor's edge to the panel's across both of
    // their extents, keeps the union whole. It only listens, and only while a
    // hover popover is open.
    Item {
        id: corridor

        readonly property rect _anchor: root._anchor
        readonly property real _left: Math.min(_anchor.x, root.x)
        readonly property real _right: Math.max(_anchor.x + _anchor.width, root.x + root.width)
        readonly property real _top: Math.min(_anchor.y, root.y)
        readonly property real _bottom: Math.max(_anchor.y + _anchor.height, root.y + root.height)
        readonly property rect _strip: {
            switch (root.side) {
            case "top": return Qt.rect(_left, root.y + root.height, _right - _left, _anchor.y - root.y - root.height);
            case "bottom": return Qt.rect(_left, _anchor.y + _anchor.height, _right - _left, root.y - _anchor.y - _anchor.height);
            case "left": return Qt.rect(root.x + root.width, _top, _anchor.x - root.x - root.width, _bottom - _top);
            default: return Qt.rect(_anchor.x + _anchor.width, _top, root.x - _anchor.x - _anchor.width, _bottom - _top);
            }
        }

        x: _strip.x - root.x
        y: _strip.y - root.y
        width: Math.max(0, _strip.width)
        height: Math.max(0, _strip.height)

        HoverHandler {
            id: corridorHover
            enabled: root.trigger === "hover" && root.open
        }
    }

    // A press trigger follows the anchor's own activation when it has one: a
    // button answers Space and Return through `clicked` and a tap handler
    // would never hear them. An anchor with no `clicked` is tapped instead.
    readonly property var _anchorAsVar: root.anchorItem
    readonly property bool _anchorClicks: typeof root._anchorAsVar?.clicked === "function"

    Connections {
        target: root.anchorItem
        enabled: root.trigger === "press" && root._anchorClicks
        ignoreUnknownSignals: true
        function onClicked(): void { root.toggle(); }
    }

    TapHandler {
        enabled: root.trigger === "press" && !root._anchorClicks
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

    // A hover popover is also for the person who cannot hover: an anchor the
    // keyboard has reached asks at once, with no intent delay to wait out.
    readonly property bool _anchorFocused: root.trigger === "hover" && ((root.anchorItem as T.Control)?.visualFocus ?? false)
    readonly property bool _engaged: root.hovered || root._anchorFocused

    on_EngagedChanged: {
        if (root.trigger !== "hover")
            return;
        if (root._engaged) {
            closeTimer.stop();
            if (root.open)
                return;
            if (root._anchorFocused)
                root.openRequested();
            else
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
