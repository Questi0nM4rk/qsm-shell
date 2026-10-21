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
// It is a POSITION cue, not a scrollbar. It is not draggable: that promises a
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
    // How deep the fade reaches. Deep enough that the last row is GONE before
    // the boundary, not merely dimmed at it — a half-faded row sliced by an
    // edge reads as a rendering fault.
    property real fadeDepth: Style.space6 * 2

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

    anchors.fill: view
    // The cue reports; it never intercepts. A pointer aimed at a row must not
    // land on the furniture drawn over it.
    enabled: false

    Rectangle {
        // A mark, not a gauge: long enough to see, short enough that it never
        // claims to measure the content.
        readonly property real _thickness: Style.stroke(Style.markThickness, root)
        readonly property real _length: Math.max(Style.space5,
            Math.min(Style.space6 * 2, root._span * root._ratio))
        readonly property real _offset: Math.max(0, Math.min(1,
            root._at / Math.max(0.001, 1 - root._ratio))) * (root._span - _length)

        visible: root.indicator && root.overflows
        x: root.vertical ? root.width - width - Style.spaceTight : _offset
        y: root.vertical ? _offset : root.height - height - Style.spaceTight
        width: root.vertical ? _thickness : _length
        height: root.vertical ? _length : _thickness
        radius: Style.radiusPill
        antialiasing: false
        color: Style.textMuted
        // Present while the list is moving, nearly gone at rest — at rest the
        // shell paints nothing it does not need to.
        opacity: root.view.moving || root.view.flicking
            ? Style.scrollCueActiveOpacity : Style.scrollCueRestOpacity

        Behavior on opacity {
            NumberAnimation { duration: Motion.medium; easing.type: Motion.standardEasing }
        }
    }

    // Each fade is present only while there is content past that edge, so the
    // cue and the truth never disagree; it fades in and out rather than
    // snapping. They sit still while the content moves
    // under them, which is what makes them read as the boundary rather than as
    // part of the list.
    //
    // The gradient reaches FULL opacity before the edge and holds. A linear
    // ramp is still translucent at the boundary, so the last row is visible
    // being cut rather than sinking out of view.
    // The gradient's DIRECTION is set by the Gradient, not by rotating the
    // rectangle. Rotating a `fadeDepth × height` strip 90 degrees about its
    // centre gives `height × fadeDepth` bounds displaced around that centre,
    // which would put the horizontal fades across the middle of the list.
    Rectangle {
        width: root.vertical ? root.width : root.fadeDepth
        height: root.vertical ? root.fadeDepth : root.height
        visible: root.fade && opacity > 0
        opacity: root._at > 0.0001 ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Motion.medium; easing.type: Motion.standardEasing }
        }
        gradient: Gradient {
            orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0; color: root.fadeColor }
            GradientStop { position: 0.3; color: root.fadeColor }
            GradientStop { position: 1; color: "transparent" }
        }
    }
    Rectangle {
        width: root.vertical ? root.width : root.fadeDepth
        height: root.vertical ? root.fadeDepth : root.height
        x: root.vertical ? 0 : root.width - root.fadeDepth
        y: root.vertical ? root.height - root.fadeDepth : 0
        visible: root.fade && opacity > 0
        opacity: root._at + root._ratio < 0.9999 ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Motion.medium; easing.type: Motion.standardEasing }
        }
        gradient: Gradient {
            orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.7; color: root.fadeColor }
            GradientStop { position: 1; color: root.fadeColor }
        }
    }
}
