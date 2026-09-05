pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Style

// A surface that belongs to another surface: it appears NEXT TO the thing that
// summoned it and it goes away again.
//
// One type covers the tooltip, the hover popout and the click-menu, because
// those differ only in what starts them and what is inside. `trigger` names
// the first; the content slot answers the second. Two components here would
// have been the same placement arithmetic written twice, and placement
// arithmetic is where this gets hard — an anchored panel that is right at the
// centre of the screen and wrong at its edge is wrong.
//
// ── what it owns ─────────────────────────────────────────────────────────
// Where it sits, when it appears, when it starts leaving, and whether it has
// to flip to stay on screen.
//
// ── what it does NOT own ─────────────────────────────────────────────────
// Whether it may close. It reports `dismissRequested` and the surface decides:
// a popout the pointer has moved INTO must not close because the pointer left
// its trigger, and only the surface knows that. A component that closes itself
// has to be told about every surface it might ever sit in.
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
    property int openDelay: Motion.large
    property int closeDelay: Motion.medium

    default property alias content: panel.data

    signal dismissRequested

    // Which side it ACTUALLY landed on, after flipping. A caller drawing a
    // tail or a seam needs this, not the preference.
    readonly property string side: placement === "top" && !_fitsAbove ? "bottom"
        : placement === "bottom" && !_fitsBelow ? "top"
        : placement === "left" && !_fitsLeft ? "right"
        : placement === "right" && !_fitsRight ? "left"
        : placement

    // Anchor rectangle in this item's own coordinates. Recomputed whenever
    // either end moves, because a popover anchored to a scrolling row must
    // travel with it rather than being placed once.
    readonly property rect _anchor: {
        if (!root.anchorItem || !root.parent)
            return Qt.rect(0, 0, 0, 0);
        // Referenced so the binding re-evaluates when the anchor moves; the
        // mapping alone reads no property QML can track.
        void root.anchorItem.x;
        void root.anchorItem.y;
        void root.anchorItem.width;
        void root.anchorItem.height;
        const origin = root.anchorItem.mapToItem(root.parent, 0, 0);
        return Qt.rect(origin.x, origin.y, root.anchorItem.width, root.anchorItem.height);
    }

    readonly property real _boundsWidth: bounds ? bounds.width : 0
    readonly property real _boundsHeight: bounds ? bounds.height : 0

    readonly property bool _fitsAbove: _anchor.y - gap - height >= 0
    readonly property bool _fitsBelow: _anchor.y + _anchor.height + gap + height <= _boundsHeight
    readonly property bool _fitsLeft: _anchor.x - gap - width >= 0
    readonly property bool _fitsRight: _anchor.x + _anchor.width + gap + width <= _boundsWidth

    // Along the anchor's cross axis: start / centre / end, then CLAMPED into
    // the bounds. Clamping after aligning is what keeps a centred popover on
    // a corner control from hanging off the screen.
    function _align(anchorStart: real, anchorSize: real, ownSize: real, limit: real): real {
        const raw = root.alignment === "start" ? anchorStart
            : root.alignment === "end" ? anchorStart + anchorSize - ownSize
            : anchorStart + (anchorSize - ownSize) / 2;
        return Math.max(0, Math.min(raw, Math.max(0, limit - ownSize)));
    }

    x: {
        switch (root.side) {
        case "left": return root._anchor.x - root.gap - root.width;
        case "right": return root._anchor.x + root._anchor.width + root.gap;
        default: return root._align(root._anchor.x, root._anchor.width, root.width, root._boundsWidth);
        }
    }
    y: {
        switch (root.side) {
        case "top": return root._anchor.y - root.gap - root.height;
        case "bottom": return root._anchor.y + root._anchor.height + root.gap;
        default: return root._align(root._anchor.y, root._anchor.height, root.height, root._boundsHeight);
        }
    }

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    visible: opacity > 0
    opacity: open ? 1 : 0
    // It arrives from the side it sits on, by a short step. Far enough to read
    // as arriving, short enough not to read as flying in.
    transform: Translate {
        x: root.open ? 0 : (root.side === "left" ? Style.space2 : root.side === "right" ? -Style.space2 : 0)
        y: root.open ? 0 : (root.side === "top" ? Style.space2 : root.side === "bottom" ? -Style.space2 : 0)

        Behavior on x { NumberAnimation { duration: Motion.medium; easing.type: Motion.emphasizedEasing } }
        Behavior on y { NumberAnimation { duration: Motion.medium; easing.type: Motion.emphasizedEasing } }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Motion.medium
            easing.type: root.open ? Motion.standardEasing : Motion.exitEasing
        }
    }

    Item {
        id: panel
        anchors.fill: parent
    }

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
        onTapped: root.open ? root.dismissRequested() : root.open = true
    }

    Timer {
        id: openTimer
        interval: root.openDelay
        onTriggered: root.open = true
    }
    Timer {
        id: closeTimer
        interval: root.closeDelay
        // Asking rather than closing: the surface may know the pointer is on
        // its way into a nested tier.
        onTriggered: root.dismissRequested()
    }

    readonly property bool _wanted: anchorHover.hovered || selfHover.hovered

    on_WantedChanged: {
        if (root.trigger !== "hover")
            return;
        if (root._wanted) {
            closeTimer.stop();
            if (!root.open)
                openTimer.restart();
        } else {
            openTimer.stop();
            if (root.open)
                closeTimer.restart();
        }
    }

    Keys.onEscapePressed: root.dismissRequested()
}
