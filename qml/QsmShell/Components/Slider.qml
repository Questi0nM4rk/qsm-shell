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

    // The keyboard handlers below need focus, and nothing was giving it: no
    // tab stop, and a drag that never moves focus here. The five states law
    // counts a state the component cannot express as a state it does not have.
    activeFocusOnTab: enabled

    property int orientation: Qt.Horizontal
    readonly property bool vertical: orientation === Qt.Vertical

    property real value: 0
    // 0 disables the wheel. A seek bar wants a deliberate pointer; a volume
    // bar is something you nudge.
    property real wheelStep: 0
    // The keyboard route does not hang off `wheelStep` -- that property means
    // "the wheel is deliberately off" for a surface like a seek bar, and a
    // slider with no wheel still needs a keyboard. Arrow keys move by
    // `keyboardStep`; Page keys move by the larger `keyboardPageStep`.
    property real keyboardStep: Style.sliderKeyboardStep
    property real keyboardPageStep: Style.sliderKeyboardPageStep
    property color fill: Style.accent
    // The colour at the LEADING end of the fill — the end the thumb is at.
    // Left equal to `fill` it is a flat bar; set differently, the lead is a
    // two-stop gradient that is brightest where the thumb is, so a level reads
    // as one channel's identity rather than as a slab of colour.
    property color fillLead: fill
    property color trackColor: Style.surfaceHover
    // What the thumb is. It defaults to the library's rule — the lightest
    // thing on the surface, which is what makes it read as raised out of the
    // track rather than as a hole cut into it — and a consumer with a fourth
    // state (a muted channel) states its own.
    property color thumbColor: raised && !active ? Qt.darker(Style.text, 1.4) : Style.text
    // The gap between the track and whatever sits in the end slots.
    property real slotGap: Style.space2

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
    // Keyboard focus. Defaults to this item's own, the same way every other
    // focusable control in the library does, so a slider that takes focus
    // rings without wiring.
    property bool focused: root.activeFocus

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

    // Geometry, not anchors, and it is not a style preference. A ternary that
    // yields `undefined` does NOT withdraw an anchor: Qt still sees left,
    // right and horizontalCenter all declared on one item, warns about it on
    // every run, and resolves the conflict however it likes. Two orientations
    // in one item is exactly the case anchors cannot express, so the item
    // states its own rectangle.
    Rectangle {
        id: track

        readonly property real _lead: (root.vertical ? beforeSlot.height : beforeSlot.width) > 0
            ? (root.vertical ? beforeSlot.height : beforeSlot.width) + root.slotGap
            : 0
        readonly property real _trail: (root.vertical ? afterSlot.height : afterSlot.width) > 0
            ? (root.vertical ? afterSlot.height : afterSlot.width) + root.slotGap
            : 0

        x: root.vertical ? (root.width - root.thickness) / 2 : _lead
        y: root.vertical ? _lead : (root.height - root.thickness) / 2
        width: root.vertical ? root.thickness : Math.max(0, root.width - _lead - _trail)
        height: root.vertical ? Math.max(0, root.height - _lead - _trail) : root.thickness
        radius: (root.vertical ? width : height) / 2
        color: root.trackColor
        opacity: root.enabled ? 1 : Style.opacityDisabled

        // The filled lead: from the bottom up, or from the left across. Same
        // reason as the track — one item, two orientations, so it states its
        // rectangle instead of declaring anchors it means to withdraw.
        Rectangle {
            x: 0
            y: root.vertical ? parent.height - height : 0
            width: root.vertical ? parent.width : parent.width * root.clampedFraction(root.value)
            height: root.vertical
                ? parent.height * root.clampedFraction(root.value)
                : parent.height
            radius: parent.radius
            // Flat when the two ends agree, a gradient when they do not. The
            // lead colour sits at the thumb's end: the top of a vertical
            // slider, the right of a horizontal one.
            color: root.fill
            gradient: root.fill === root.fillLead ? null : fillRamp
            Behavior on width {
                NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
            }
            Behavior on height {
                NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
            }
        }
    }

    Gradient {
        id: fillRamp
        orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
        GradientStop { position: 0; color: root.vertical ? root.fillLead : root.fill }
        GradientStop { position: 1; color: root.vertical ? root.fill : root.fillLead }
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

        Behavior on x { NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing } }
        Behavior on y { NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing } }
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
        Behavior on x { NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing } }
        Behavior on y { NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing } }
        width: root.thumbSize
        height: width
        radius: width / 2
        color: root.thumbColor

        Behavior on color {
            ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }

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

    HoverHandler { id: hover; enabled: root.enabled; cursorShape: Qt.PointingHandCursor }

    // The five states law again: `StateLayer` owns the focus ring so a
    // keyboard user meets the same mark here as on every other control. It
    // does NOT own hover/press for this one -- `target: null` withholds the
    // scale-growth binding. A slider already answers hover and press through
    // its own `active`/`dragging` (the fill, the thumb colour, the shadow
    // lift), and `StateLayer.pressed` is a TAP, not a sustained drag; routing
    // press through it would have the ring and the thumb disagree mid-drag.
    // See the report for the full reasoning.
    StateLayer {
        anchors.fill: parent
        target: null
        interactive: root.enabled
        focused: root.focused
        focusRadius: (root.vertical ? width : height) / 2
    }

    Keys.onPressed: event => {
        if (!root.enabled)
            return;

        switch (event.key) {
        case Qt.Key_Right:
        case Qt.Key_Up:
            root.moved(root.clampedFraction(root.value + root.keyboardStep));
            event.accepted = true;
            break;
        case Qt.Key_Left:
        case Qt.Key_Down:
            root.moved(root.clampedFraction(root.value - root.keyboardStep));
            event.accepted = true;
            break;
        case Qt.Key_PageUp:
            root.moved(root.clampedFraction(root.value + root.keyboardPageStep));
            event.accepted = true;
            break;
        case Qt.Key_PageDown:
            root.moved(root.clampedFraction(root.value - root.keyboardPageStep));
            event.accepted = true;
            break;
        case Qt.Key_Home:
            root.moved(0);
            event.accepted = true;
            break;
        case Qt.Key_End:
            root.moved(1);
            event.accepted = true;
            break;
        }
    }

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
