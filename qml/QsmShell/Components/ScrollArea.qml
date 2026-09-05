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
// precision nobody uses on a 300px list, and takes a hit area away from the
// rows underneath. It fades in on interaction and out afterwards, because at
// rest the shell paints nothing it does not need to.
//
// ── why this is an Item wrapping a Flickable, not a Flickable ─────────────
// A Flickable's declared children become children of its `contentItem`, which
// means they SCROLL — and worse, they count toward `childrenRect`, which is
// what sizes the content. The first version of this component put the
// indicator inside, so the indicator's height fed the content height fed the
// indicator's height: a binding loop, invisible to `qmllint` and caught the
// first time anything actually ran it. Chrome is a sibling of the viewport,
// never a passenger in it.
Item {
    id: root

    // The scrolled content. It goes into an explicit host inside the viewport
    // rather than straight onto the Flickable: `contentData` is not aliasable,
    // and a named host is where the content size comes from anyway.
    default property alias content: host.data

    property int orientation: Qt.Vertical
    // Soften the cut edge, so a row sliced by the boundary reads as continuing
    // rather than as ending.
    property bool fade: true
    // What the fade fades TO. It defaults to the library surface; a consumer
    // scrolling over a different ground states its own, because a gradient
    // toward the wrong colour is more visible than no gradient at all.
    property color fadeColor: Style.surface
    property bool indicator: true

    // The viewport, for a consumer that needs to drive the position itself
    // (scroll a selection into view, jump to the top on a new query).
    readonly property alias viewport: view

    readonly property bool vertical: orientation === Qt.Vertical
    readonly property real _fadeDepth: Style.space5
    readonly property real _span: vertical ? view.height : view.width
    readonly property real _content: vertical ? view.contentHeight : view.contentWidth
    readonly property real _position: vertical ? view.contentY : view.contentX
    readonly property bool _overflows: _content > _span

    Flickable {
        id: view

        anchors.fill: parent
        clip: true
        flickableDirection: root.vertical ? Flickable.VerticalFlick : Flickable.HorizontalFlick
        contentWidth: root.vertical ? width : host.childrenRect.width
        contentHeight: root.vertical ? host.childrenRect.height : height
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: host
            // The free axis matches the viewport, so content that fills the
            // width does not have to be told how wide the viewport is.
            width: root.vertical ? view.width : childrenRect.width
            height: root.vertical ? childrenRect.height : view.height
        }
    }

    // ── position cue ────────────────────────────────────────────────────
    Rectangle {
        readonly property real _length: Math.max(Style.space5,
            root._span * (root._span / Math.max(1, root._content)))
        readonly property real _offset: root._position
            / Math.max(1, root._content - root._span) * (root._span - _length)

        visible: root.indicator && root._overflows
        x: root.vertical ? root.width - width - Style.spaceTight : _offset
        y: root.vertical ? _offset : root.height - height - Style.spaceTight
        width: root.vertical ? Style.markThickness : _length
        height: root.vertical ? _length : Style.markThickness
        radius: Style.markThickness / 2
        color: Style.textMuted
        opacity: view.moving || view.flicking ? 0.6 : 0.2

        Behavior on opacity {
            NumberAnimation { duration: Motion.medium; easing.type: Motion.standardEasing }
        }
    }

    // ── edge fades ──────────────────────────────────────────────────────
    // Each is visible only while there is content past that edge, so the cue
    // and the truth never disagree. They sit still while the content moves
    // under them, which is what makes them read as the boundary rather than
    // as part of the list.
    Rectangle {
        width: root.vertical ? root.width : root._fadeDepth
        height: root.vertical ? root._fadeDepth : root.height
        visible: root.fade && root._position > 0
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
        x: root.vertical ? 0 : root.width - root._fadeDepth
        y: root.vertical ? root.height - root._fadeDepth : 0
        visible: root.fade && root._position < root._content - root._span
        rotation: root.vertical ? 180 : 270
        transformOrigin: Item.Center
        gradient: Gradient {
            GradientStop { position: 0; color: root.fadeColor }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
