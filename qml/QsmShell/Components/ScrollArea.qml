import QtQuick

import qs.QsmShell.Style

// Content that is taller (or wider) than the room it has.
//
// WHY it is a component: eight surfaces in the one consuming shell each built
// this by hand — a Flickable, a clip, a thin bar somebody drew, a fade
// somebody else drew — and no two of them agreed on the bar's width, the
// fade's depth, or whether either appeared when there was nothing to scroll.
// A scroll cue that shows on content that fits is the interface claiming there
// is more, which is the one thing a scroll cue must never do.
//
// The indicator is a POSITION cue, not a scrollbar: it says where you are and
// how much there is, and it is not draggable. A draggable bar promises a
// precision nobody uses on a 300px list, and it takes a hit area away from the
// rows underneath.
//
// It fades in on interaction and out afterwards, because at rest the shell
// paints nothing it does not need to.
Flickable {
    id: root

    property int orientation: Qt.Vertical
    // Soften the cut edge, so a row sliced by the boundary reads as continuing
    // rather than as ending.
    property bool fade: true
    // What the fade fades TO. It defaults to the library surface; a consumer
    // scrolling over a different ground states its own, because a gradient
    // toward the wrong colour is more visible than no gradient at all.
    property color fadeColor: Style.surface
    property bool indicator: true

    readonly property bool vertical: orientation === Qt.Vertical
    readonly property real _fadeDepth: Style.space5
    readonly property bool _overflows: vertical
        ? contentHeight > height
        : contentWidth > width

    clip: true
    flickableDirection: vertical ? Flickable.VerticalFlick : Flickable.HorizontalFlick
    contentWidth: vertical ? width : contentItem.childrenRect.width
    contentHeight: vertical ? contentItem.childrenRect.height : height
    boundsBehavior: Flickable.StopAtBounds

    // ── position cue ────────────────────────────────────────────────────
    Rectangle {
        id: thumb

        readonly property real _span: root.vertical ? root.height : root.width
        readonly property real _content: root.vertical ? root.contentHeight : root.contentWidth
        readonly property real _length: Math.max(Style.space5, _span * (_span / Math.max(1, _content)))
        readonly property real _offset: (root.vertical ? root.contentY : root.contentX)
            / Math.max(1, _content - _span) * (_span - _length)

        visible: root.indicator && root._overflows
        x: root.vertical ? root.width - width - Style.spaceTight : _offset
        y: root.vertical ? _offset : root.height - height - Style.spaceTight
        width: root.vertical ? Style.markThickness : _length
        height: root.vertical ? _length : Style.markThickness
        radius: Style.markThickness / 2
        color: Style.textMuted
        opacity: root.moving || root.flicking ? 0.6 : 0.2

        Behavior on opacity {
            NumberAnimation { duration: Motion.medium; easing.type: Motion.standardEasing }
        }
    }

    // ── edge fades ──────────────────────────────────────────────────────
    // Each is visible only while there is content past that edge, so the cue
    // and the truth never disagree.
    Rectangle {
        width: root.vertical ? root.width : root._fadeDepth
        height: root.vertical ? root._fadeDepth : root.height
        x: root.vertical ? 0 : root.contentX
        y: root.vertical ? root.contentY : 0
        visible: root.fade && (root.vertical ? root.contentY > 0 : root.contentX > 0)
        rotation: root.vertical ? 0 : 90
        transformOrigin: Item.Center
        gradient: Gradient {
            GradientStop { position: 0; color: root.fadeColor }
            GradientStop { position: 1; color: "transparent" }
        }
    }
    Rectangle {
        width: root.vertical ? root.width : root._fadeDepth
        height: root.vertical ? root._fadeDepth : root.height
        x: root.vertical ? 0 : root.contentX + root.width - root._fadeDepth
        y: root.vertical ? root.contentY + root.height - root._fadeDepth : 0
        visible: root.fade && (root.vertical
            ? root.contentY < root.contentHeight - root.height
            : root.contentX < root.contentWidth - root.width)
        rotation: root.vertical ? 180 : 270
        transformOrigin: Item.Center
        gradient: Gradient {
            GradientStop { position: 0; color: root.fadeColor }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
