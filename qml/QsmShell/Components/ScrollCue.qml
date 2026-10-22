import QtQuick

import qs.QsmShell.Style

// The furniture that says "there is more this way", for a viewport that
// already exists.
//
// WHY it is separate from `ScrollArea`: a list long enough to need scrolling
// is usually long enough to need a `ListView`, and a ListView IS the
// Flickable — it cannot be put inside one. So the chrome has to be able to
// attach to a viewport the consumer built, and `ScrollArea` is that same
// chrome plus a plain Flickable for the static case. One implementation, two
// ways in.
//
// It is a POSITION cue, not a scrollbar: the edge fade is the cue, and the mark
// is the cue only where the fade is off (one idiom, never both beside each
// other). It is not draggable: that promises a
// precision nobody uses on a 300px list and takes a hit area away from the
// rows underneath. And the mark's LENGTH is capped, so it stays a mark —
// uncapped, a three-item list gets a thumb nearly as tall as the viewport,
// which reads as a gauge reporting "you are seeing most of it" rather than as
// "you are here".
//
// Nothing here appears when the content fits. A scroll cue on content that
// fits is the interface claiming there is more, which is the one thing it must
// never do.
Item {
    id: root

    required property Flickable view
    property bool fade: true
    // What the fade fades TO. It defaults to the library surface; a consumer
    // scrolling over a different ground states its own, because a gradient
    // toward the wrong colour is more visible than no gradient at all.
    property color fadeColor: Style.surface
    property bool indicator: true
    property int orientation: Qt.Vertical
    // The deepest a fade reaches; `startFade` and `endFade` are what it paints.
    property real fadeDepth: Style.space6

    readonly property bool vertical: orientation === Qt.Vertical
    readonly property real _span: vertical ? view.height : view.width

    // `visibleArea` is the canonical scroll fraction and raw `contentY`
    // arithmetic is not: a ListView's content origin moves as delegates are
    // created and destroyed above the viewport, so a thumb positioned from
    // contentY drifts and eventually runs past the end. Measured, and it cost
    // a round of "the bar goes off the bottom".
    readonly property real _ratio: vertical
        ? view.visibleArea.heightRatio
        : view.visibleArea.widthRatio
    readonly property real _at: vertical
        ? view.visibleArea.yPosition
        : view.visibleArea.xPosition

    readonly property bool overflows: _ratio < 1

    // A fade is bounded three ways, so a short list is never eaten by its own
    // cue: by `fadeDepth`; by a sixth of the viewport, which leaves two thirds
    // of it clear with both edges faded; and by the content actually hidden
    // past that edge, so it grows from nothing as the content leaves and is
    // gone when the edge is reached. A side with nothing hidden paints none.
    readonly property real _reach: Math.min(fadeDepth, _span / 6)
    readonly property real _content: _span / Math.max(_ratio, 0.0001)
    // Painted depth at the start (top, left) and end (bottom, right), in px.
    readonly property real startFade: overflows ? Math.min(_reach, Math.max(0, _at * _content)) : 0
    readonly property real endFade: overflows
        ? Math.min(_reach, Math.max(0, (1 - _at - _ratio) * _content)) : 0

    anchors.fill: view
    // The cue reports; it never intercepts. A pointer aimed at a row must not
    // land on the furniture drawn over it.
    enabled: false

    Rectangle {
        // A mark, not a gauge: long enough to see, short enough that it never
        // claims to measure the content.
        readonly property real _thickness: Style.stroke(Style.markThickness, root)
        readonly property real _length: Math.min(root._span, Math.max(Style.space5,
            Math.min(Style.space6 * 2, root._span * root._ratio)))
        readonly property real _offset: Math.max(0, Math.min(1,
            root._at / Math.max(0.001, 1 - root._ratio))) * (root._span - _length)

        visible: root.indicator && root.overflows && !root.fade
        x: root.vertical ? root.width - width - Style.spaceTight : _offset
        y: root.vertical ? _offset : root.height - height - Style.spaceTight
        width: root.vertical ? _thickness : _length
        height: root.vertical ? _length : _thickness
        radius: Style.radiusPill
        antialiasing: false
        color: Style.textMuted
        // Brighter while the list is moving; at rest it still clears the 3:1
        // floor of a non-text mark on the band, because it may be the only
        // cue to content past an edge.
        opacity: root.view.moving || root.view.flicking
            ? Style.scrollCueActiveOpacity : Style.scrollCueRestOpacity

        Behavior on opacity {
            NumberAnimation { duration: Motion.medium; easing.type: Motion.standardEasing }
        }
    }

    // The fades sit still while the content moves under them, which is what
    // makes them read as the boundary rather than as part of the list. The
    // gradient is the fade colour at the edge and clear at its inner end, and
    // is steepest at the edge, so the row being cut dissolves instead of being
    // sliced.
    // Its DIRECTION is set by the Gradient, not by rotating the rectangle:
    // rotating a `depth × height` strip 90 degrees about its centre gives
    // bounds displaced around that centre, which would put the horizontal
    // fades across the middle of the list.
    Rectangle {
        width: root.vertical ? root.width : root.startFade
        height: root.vertical ? root.startFade : root.height
        visible: root.fade && root.startFade > 0
        gradient: Gradient {
            orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0; color: root.fadeColor }
            GradientStop { position: 0.4; color: Qt.alpha(root.fadeColor, 0.36) }
            GradientStop { position: 1; color: Qt.alpha(root.fadeColor, 0) }
        }
    }
    Rectangle {
        width: root.vertical ? root.width : root.endFade
        height: root.vertical ? root.endFade : root.height
        x: root.vertical ? 0 : root.width - root.endFade
        y: root.vertical ? root.height - root.endFade : 0
        visible: root.fade && root.endFade > 0
        gradient: Gradient {
            orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(root.fadeColor, 0) }
            GradientStop { position: 0.6; color: Qt.alpha(root.fadeColor, 0.36) }
            GradientStop { position: 1; color: root.fadeColor }
        }
    }
}
