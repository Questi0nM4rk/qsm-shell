import QtQuick

import qs.QsmShell.Style

// THE slider. One track, one filled lead, one thumb, either orientation.
//
// There used to be two of these — a thin horizontal "level" and a fat vertical
// "OSD" one — which is one concept wearing two names. They differ in three
// numbers and in what the consumer hangs off them, and none of that is a
// reason for a second component: a library that grows a type per call site
// stops being a library.
//
// Three slots, because a slider is rarely only a slider. `before` and `after`
// sit at its ends (an icon under a volume track, a label over a warmth one),
// and `thumbContent` is drawn INSIDE the thumb. An empty slot takes no space,
// so a bare slider looks exactly like a bare slider.
//
// `value` is 0..1 and the HOST owns it: this emits `moved` and never writes
// its own value, so a level the system can also change from elsewhere never
// fights the control that shows it.
//
// Staying visible under the pointer is NOT this component's business. It
// reports `hovered`; the surface holding it decides what that means, the same
// way a menu does.
Item {
    id: root

    property int orientation: Qt.Horizontal
    readonly property bool vertical: orientation === Qt.Vertical

    property real value: 0
    // 0 disables the wheel. A seek bar wants a deliberate pointer; a volume
    // bar is something you nudge.
    property real wheelStep: 0
    property color fill: Style.accent
    property color trackColor: Style.surfaceHover

    // The track's short axis, and the thumb that rides it. A call site that
    // wants a fat track says so; the library keeps one default rather than a
    // token per surface that ever needed one.
    property real thickness: Style.sliderTrackThickness
    property real thumbSize: Style.sliderThumbSize
    // A raised thumb casts a shadow and lifts further while dragged, which is
    // what makes a big thumb read as picked up. A hairline level bar does not
    // want one.
    property bool raised: false
    property bool showThumb: true

    // The consumer can force the emphasised look while the value is being
    // changed from somewhere other than this control.
    property bool emphasized: false

    // ── slots ───────────────────────────────────────────────────────────
    property alias before: beforeSlot.data
    property alias after: afterSlot.data
    property alias thumbContent: thumbSlot.data

    readonly property bool hovered: hover.hovered
    readonly property bool active: emphasized || dragging || hovered
    property bool dragging: false

    signal moved(real value)

    function clampedFraction(fraction: real): real {
        return Math.max(0, Math.min(1, fraction));
    }

    readonly property real _span: vertical ? track.height : track.width
    readonly property real _travel: Math.max(0, _span - thumbSize)
    // Vertical runs bottom-up: full is at the top, which is where a person
    // expects "more" to be.
    readonly property real _thumbOffset:
        (vertical ? 1 - clampedFraction(value) : clampedFraction(value)) * _travel

    implicitWidth: vertical
        ? Math.max(thickness, thumbSize, beforeSlot.width, afterSlot.width)
        : 0
    implicitHeight: vertical
        ? beforeSlot.height + afterSlot.height + _slotGaps
        : Math.max(thickness, thumbSize, beforeSlot.height, afterSlot.height)
    readonly property real _slotGaps: (beforeSlot.height > 0 ? Style.space2 : 0)
        + (afterSlot.height > 0 ? Style.space2 : 0)

    function _setFrom(position: real): void {
        const raw = (position - thumbSize / 2) / Math.max(1, _travel);
        moved(clampedFraction(vertical ? 1 - raw : raw));
    }

    // An empty slot has no size, so the layout closes up around it.
    Item {
        id: beforeSlot
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.top: root.vertical ? parent.top : undefined
        anchors.left: root.vertical ? undefined : parent.left
        width: children.length > 0 ? childrenRect.width : 0
        height: children.length > 0 ? childrenRect.height : 0
    }

    Rectangle {
        id: track

        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.top: root.vertical ? beforeSlot.bottom : undefined
        anchors.topMargin: root.vertical && beforeSlot.height > 0 ? Style.space2 : 0
        anchors.bottom: root.vertical ? afterSlot.top : undefined
        anchors.bottomMargin: root.vertical && afterSlot.height > 0 ? Style.space2 : 0
        anchors.left: root.vertical ? undefined : beforeSlot.right
        anchors.leftMargin: !root.vertical && beforeSlot.width > 0 ? Style.space2 : 0
        anchors.right: root.vertical ? undefined : afterSlot.left
        anchors.rightMargin: !root.vertical && afterSlot.width > 0 ? Style.space2 : 0

        width: root.vertical ? root.thickness : undefined
        height: root.vertical ? undefined : root.thickness
        radius: (root.vertical ? width : height) / 2
        color: root.trackColor
        opacity: root.enabled ? 1 : Style.opacityDisabled

        // The filled lead: from the bottom up, or from the left across.
        Rectangle {
            anchors.left: parent.left
            anchors.right: root.vertical ? parent.right : undefined
            anchors.bottom: root.vertical ? parent.bottom : undefined
            anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
            width: root.vertical ? undefined : parent.width * root.clampedFraction(root.value)
            height: root.vertical
                ? parent.height * root.clampedFraction(root.value)
                : parent.height
            radius: parent.radius
            color: root.fill
            Behavior on width {
                NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
            }
            Behavior on height {
                NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
            }
        }
    }

    // Shadow under a raised thumb, lifted further while dragging.
    Rectangle {
        visible: root.showThumb && root.raised && root.enabled
        x: root.vertical
            ? track.x + (track.width - root.thumbSize) / 2
            : track.x + root._thumbOffset
        y: (root.vertical ? track.y + root._thumbOffset : track.y + (track.height - root.thumbSize) / 2)
            + (root.dragging ? Style.sliderThumbLift * 2 : Style.sliderThumbLift)
        width: root.thumbSize
        height: width
        radius: width / 2
        color: Qt.rgba(0, 0, 0, .45)
    }

    Rectangle {
        id: thumb
        visible: root.showThumb && root.enabled
        x: root.vertical
            ? track.x + (track.width - root.thumbSize) / 2
            : track.x + root._thumbOffset
        y: root.vertical
            ? track.y + root._thumbOffset
            : track.y + (track.height - root.thumbSize) / 2
        width: root.thumbSize
        height: width
        radius: width / 2
        color: root.raised && !root.active ? Qt.darker(Style.text, 1.4) : Style.text

        Item {
            id: thumbSlot
            anchors.fill: parent
        }
    }

    Item {
        id: afterSlot
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.bottom: root.vertical ? parent.bottom : undefined
        anchors.right: root.vertical ? undefined : parent.right
        width: children.length > 0 ? childrenRect.width : 0
        height: children.length > 0 ? childrenRect.height : 0
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

    // A grab area reaching well past a track that may be only a few pixels
    // thick.
    MouseArea {
        anchors.fill: track
        anchors.margins: -Style.space2
        cursorShape: Qt.PointingHandCursor
        onPressed: event => {
            root.dragging = true;
            root._setFrom((root.vertical ? event.y : event.x) - Style.space2);
        }
        onPositionChanged: event => {
            if (pressed)
                root._setFrom((root.vertical ? event.y : event.x) - Style.space2);
        }
        onReleased: root.dragging = false
        onCanceled: root.dragging = false
    }

    WheelHandler {
        enabled: root.wheelStep > 0
        onWheel: event => {
            if (event.angleDelta.y !== 0)
                root.moved(root.clampedFraction(root.value
                    + (event.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep)));
        }
    }
}
