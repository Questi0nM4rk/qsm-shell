import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// THE slider. One track, one filled lead, one thumb, either orientation.
//
// There used to be two of these -- a thin horizontal "level" and a fat
// vertical "OSD" one -- which is one concept wearing two names. They differed
// in three numbers and in what the consumer hung off them, and none of that
// is a reason for a second type.
//
// It stands on `T.Slider`, so the template owns the value range, the press
// grab (no drag threshold, unstealable, and a click on the track jumps on
// PRESS), snapping to `stepSize`, `LayoutMirroring`, focus and tab traversal,
// and the accessibility value interface -- which needs no `Accessible` block
// at all, because it duck-types the property names `value`, `from`, `to` and
// `stepSize` off the root.
//
// What is NOT free from Qt and lives here: PageUp/PageDown/Home/End (Qt's
// Slider has no handler for any of them), a wheel that ACCUMULATES rather
// than stepping per event, the five states through `StateLayer`, the three
// slots, and the look.
//
// `value` is host-owned in the sense that matters. Every route writes it
// through Qt's own C++ setter -- the drag, `increase()`, `decrease()` -- which
// leaves a consumer's `value:` binding installed and live, so a level the
// system also changes from elsewhere still lands. Nothing here ever assigns
// `value` from JavaScript: that severs the binding, and the keyboard would
// then quietly behave differently from the pointer.
//
// Staying visible under the pointer is NOT this component's business. It
// reports `hovered`; the surface holding it decides what that means.
T.Slider {
    id: root

    from: 0
    to: 1
    // The unit every non-pointer route walks in, and never 0: at 0 Qt's own
    // arrows fall back to 0.1 VALUE units and the accessibility
    // increase/decrease actions go inert. A host that widens `from`/`to` must
    // widen `stepSize` with it, because Home and End walk the range in units.
    stepSize: Style.sliderStep
    snapMode: T.Slider.SnapAlways
    // A platform style HINT resolves `hoverEnabled` on a bare control, so it
    // is stated rather than inherited: `hovered` is one third of `active`.
    //
    // Tied to `enabled`, because `QQuickControl::hoverEnterEvent` sets
    // `hovered` to whatever `hoverEnabled` says and a disabled item is still
    // delivered hover -- the HoverHandler below turns `acceptHoverEvents` on
    // no matter what this says. Left at `true` a disabled slider reported
    // `hovered` under the pointer, which is a state it cannot answer.
    hoverEnabled: root.enabled
    // Qt's own wheel is proportional but steps by `stepSize` and cannot be
    // switched off per call site. `wheelUnits` below is ours.
    wheelEnabled: false
    opacity: enabled ? 1 : Style.opacityDisabled

    // 0 = no wheel. A seek bar wants a deliberate pointer; a volume bar is
    // something you nudge. Counted in `stepSize` units like every other
    // non-pointer route, so one number means one thing everywhere.
    property int wheelUnits: 0

    property color fill: Style.accent
    // The colour at the LEADING end of the fill -- the end the thumb is at.
    // Left equal to `fill` it is a flat bar; set differently, the lead is a
    // two-stop gradient that is brightest where the thumb is, so a level reads
    // as one channel's identity rather than as a slab of colour.
    property color fillLead: fill
    property color trackColor: Style.surfaceHover
    // What the thumb is. It defaults to the library's rule -- the lightest
    // thing on the surface, which is what makes it read as raised out of the
    // track rather than as a hole cut into it -- and a consumer with a fourth
    // state (a muted channel) states its own.
    property color thumbColor: raised && !active ? Qt.darker(Style.text, 1.4) : Style.text
    // The gap between the track and whatever sits in the end slots.
    property real slotGap: Style.space2

    // The track's short axis, and the thumb that rides it. A call site that
    // wants a fat track says so; the library keeps one default.
    property real thickness: Style.sliderTrackThickness
    property real thumbSize: Style.sliderThumbSize
    // A raised thumb casts a shadow and lifts further while pressed, which is
    // what makes a big thumb read as picked up. A hairline level bar does not
    // want one.
    property bool raised: false
    // The consumer can force the emphasised look while the value is being
    // changed from somewhere other than this control.
    property bool emphasized: false

    readonly property bool active: emphasized || pressed || hovered

    // ── slots ───────────────────────────────────────────────────────────
    // `before` and `after` sit at the ends ALONG the axis and become padding,
    // so the track and the thumb travel in what is left. On a vertical slider
    // `before` is the top, which is the high end. An empty slot takes no
    // space, so a bare slider looks exactly like a bare slider.
    property alias before: beforeSlot.data
    property alias after: afterSlot.data
    // Drawn INSIDE the thumb, so it travels and scales with it.
    property alias thumbContent: thumbSlot.data

    // `moved()` is Qt's and carries no argument: it says a gesture changed the
    // value, and the host reads `value`. `committed` is the END of one -- a
    // release after a change, the release of a key that changed something, and
    // each wheel notch that changed something, because a notch has no release
    // to wait for. A host that writes on every `moved` gets a live level; a
    // host that only wants the final value waits for this.
    signal committed()

    // The value the last gesture left behind. A host that writes on every
    // `moved` never needs it; a host that only acts on a finished gesture
    // compares against it instead of keeping its own copy of the same fact.
    //
    // The private backing property is what makes it honestly read-only: a
    // `readonly property` cannot be assigned from anywhere, and a binding to
    // `value` would make it follow the drag, which is the one thing it must
    // not do. It is set at completion rather than bound, for the same reason.
    readonly property real committedValue: root._committedValue
    property real _committedValue: 0

    Component.onCompleted: root._committedValue = root.value
    onCommitted: root._committedValue = root.value

    // ── one route per action ────────────────────────────────────────────
    // Every non-pointer route ends up here, and it steps by calling Qt's own
    // `increase()`/`decrease()` rather than assigning `value`. That is not
    // style: a JavaScript write severs the consumer's `value:` binding on the
    // first arrow key, so a service that changes the level from elsewhere
    // would stop reaching the control -- and only on the keyboard, which is
    // the kind of split nobody finds. It is also why the tokens count UNITS
    // rather than carrying a fraction: a unit is exactly one `increase()`.
    function stepBy(units: int): bool {
        if (!root.enabled || units === 0)
            return false;

        const before = root.value;
        root._hostDriven = false;
        const count = Math.abs(units);
        for (let i = 0; i < count; i++) {
            if (units > 0)
                root.increase();
            else
                root.decrease();
        }
        Qt.callLater(root._endGesture);
        return root._report(before);
    }

    // Lands on the nearest unit from where the value is now, because a unit is
    // the only distance the routes can walk. It is NOT a promise that the
    // result is on the grid: a host binding writes `value` through the same
    // setter the drag uses, and `SnapAlways` decides where that lands.
    //
    // The distance is rounded with its sign taken off and put back:
    // `Math.round(-0.5)` is `-0`, which `stepBy` reads as no work, so half a
    // step DOWN used to be a silent no-op while half a step up moved.
    function moveTo(target: real): bool {
        if (!root.enabled)
            return false;
        const clamped = Math.max(root.from, Math.min(root.to, target));
        const distance = clamped - root.value;
        return root.stepBy(Math.sign(distance) * Math.round(Math.abs(distance) / root.stepSize));
    }

    // The whole range in units, which is every step either of these can need
    // from anywhere in it. There is no extra unit past the end: `setValue`
    // clamps, so an overshoot cannot help, and it also refuses a write that is
    // `qFuzzyCompare`-equal to the value it already holds, so once a value has
    // landed within 1e-12 of a bound no further step reaches the bound itself
    // (measured: `stepSize` 0.1 saturates at 0.9999999999999999 and stays
    // there, while 0.01 lands on 0 and 1 exactly). A host that needs an exact
    // bound needs a `stepSize` whose multiples can express it.
    readonly property int _unitsInRange: Math.ceil((root.to - root.from) / root.stepSize)
    function toMinimum(): bool { return root.stepBy(-root._unitsInRange); }
    function toMaximum(): bool { return root.stepBy(root._unitsInRange); }

    function _report(before: real): bool {
        if (root.value === before)
            return false;
        root.moved();
        return true;
    }

    // What a consumer's action menu renders. Shortcuts are never set here:
    // which key means what is the surface's call.
    readonly property list<T.Action> actions: [
        T.Action {
            text: "Increase"
            enabled: root.enabled && root.value < root.to
            onTriggered: root.stepBy(Style.sliderKeyboardUnits)
        },
        T.Action {
            text: "Decrease"
            enabled: root.enabled && root.value > root.from
            onTriggered: root.stepBy(-Style.sliderKeyboardUnits)
        },
        T.Action {
            text: "Minimum"
            enabled: root.enabled && root.value > root.from
            onTriggered: root.toMinimum()
        },
        T.Action {
            text: "Maximum"
            enabled: root.enabled && root.value < root.to
            onTriggered: root.toMaximum()
        }
    ]

    // ── responsiveness ──────────────────────────────────────────────────
    // The fill and the thumb bind to this, and it animates ONLY when the
    // change did not come from a gesture. The old component animated fill and
    // thumb at 180ms including DURING the drag, so the thumb trailed the
    // finger. A level the system changed from elsewhere still eases in, so a
    // reading that moved on its own is not mistaken for one a hand moved.
    property real _paintedPosition: root.visualPosition

    // False while a gesture owns the value, and for the frame after one. Every
    // route sets it and hands it back through `Qt.callLater`, which collapses
    // repeated calls to the same function into one.
    property bool _hostDriven: true

    function _endGesture(): void {
        if (!root.pressed)
            root._hostDriven = true;
    }

    Behavior on _paintedPosition {
        // Reduced motion removes this one rather than shortening it. A slider
        // is the one control whose whole job is to sit where it was put, and
        // the library's general rule (shorten, never remove) is overridden
        // here on the owner's ruling -- recorded in docs/components/Slider.md.
        enabled: root._hostDriven && !Style.reducedMotion
        NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing }
    }

    readonly property real _mainSpan: root.vertical ? root.availableHeight : root.availableWidth
    readonly property real _travel: Math.max(0, _mainSpan - root.thumbSize)
    // `visualPosition` already carries both flips -- vertical runs bottom-up,
    // and mirroring swaps the horizontal ends -- so this is one number with no
    // orientation or RTL branch in it.
    readonly property real _thumbOffset: root._paintedPosition * _travel
    readonly property real _fillEnd: _thumbOffset + root.thumbSize / 2

    // At least a comfortable hit target across the axis, whatever the track's
    // thickness is: a 4px track with a 12px thumb still has to be aimable.
    // Slot content can ask for more, and does on the OSD.
    readonly property real _crossSize: Math.max(
        Style.controlHeightSm, root.thickness, root.thumbSize,
        root.vertical
            ? Math.max(beforeSlot.implicitWidth, afterSlot.implicitWidth)
            : Math.max(beforeSlot.implicitHeight, afterSlot.implicitHeight))

    implicitWidth: root.vertical
        ? _crossSize
        : Math.max(Style.sliderLength, leftPadding + rightPadding)
    implicitHeight: root.vertical
        ? Math.max(Style.sliderLengthVertical, topPadding + bottomPadding)
        : _crossSize

    // Padding is where the slots sit, and the template owns the arithmetic
    // from here: the contentItem gets exactly what is left over. The cross
    // axis takes none, so the track keeps the full thickness it asked for.
    leftPadding: root.horizontal && beforeSlot.hasContent
        ? beforeSlot.implicitWidth + root.slotGap : 0
    rightPadding: root.horizontal && afterSlot.hasContent
        ? afterSlot.implicitWidth + root.slotGap : 0
    topPadding: root.vertical && beforeSlot.hasContent
        ? beforeSlot.implicitHeight + root.slotGap : 0
    bottomPadding: root.vertical && afterSlot.hasContent
        ? afterSlot.implicitHeight + root.slotGap : 0

    // Does this slot hold anything? Counting children answered the wrong
    // question, because a `Loader` never gives its footprint back: a Loader
    // that unloads still reports an implicit size with `item` null, so a
    // trailing icon that switched itself off went on reserving its width. A
    // child that loads its content counts once it HAS it; any other child
    // counts by being there.
    //
    // `slot` is untyped on purpose: `children` is a list of `Item`, and
    // neither `sourceComponent` nor `item` is a member of `Item`.
    function _slotHasContent(slot): bool {
        for (let i = 0; i < slot.children.length; i++) {
            const child = slot.children[i];
            if (child.sourceComponent === undefined)
                return true;
            if (child.item !== null)
                return true;
        }
        return false;
    }

    // Geometry, not anchors, and it is not a style preference. A ternary that
    // yields `undefined` does NOT withdraw an anchor: Qt still sees top, left
    // and both centres declared on one item, warns on every run, and resolves
    // the conflict however it likes. Two orientations in one item is exactly
    // the case anchors cannot express, so each item states its own rectangle.
    Item {
        id: beforeSlot
        readonly property bool hasContent: root._slotHasContent(beforeSlot)
        x: root.vertical ? (root.width - width) / 2 : 0
        y: root.vertical ? 0 : (root.height - height) / 2
        implicitWidth: hasContent ? childrenRect.width : 0
        implicitHeight: hasContent ? childrenRect.height : 0
        width: implicitWidth
        height: implicitHeight
    }

    Item {
        id: afterSlot
        readonly property bool hasContent: root._slotHasContent(afterSlot)
        x: root.vertical ? (root.width - width) / 2 : root.width - width
        y: root.vertical ? root.height - height : (root.height - height) / 2
        implicitWidth: hasContent ? childrenRect.width : 0
        implicitHeight: hasContent ? childrenRect.height : 0
        width: implicitWidth
        height: implicitHeight
    }

    Gradient {
        id: fillRamp
        orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
        GradientStop { position: 0; color: root.vertical ? root.fillLead : root.fill }
        GradientStop { position: 1; color: root.vertical ? root.fill : root.fillLead }
    }

    contentItem: Item {
        Rectangle {
            id: track
            objectName: "sliderTrack"
            x: root.vertical ? (parent.width - width) / 2 : 0
            y: root.vertical ? 0 : (parent.height - height) / 2
            width: root.vertical ? root.thickness : parent.width
            height: root.vertical ? parent.height : root.thickness
            radius: (root.vertical ? width : height) / 2
            color: root.trackColor

            // The filled lead ends where the thumb is, on the value side of
            // it: the bottom of a vertical slider, the left of a horizontal
            // one, and the right of a mirrored one. Only the pinned edge
            // branches -- the length is `_fillEnd` either way.
            Rectangle {
                objectName: "sliderFill"
                x: root.vertical ? 0 : (root.mirrored ? root._fillEnd : 0)
                y: root.vertical ? root._fillEnd : 0
                width: root.vertical
                    ? parent.width
                    : (root.mirrored ? parent.width - root._fillEnd : root._fillEnd)
                height: root.vertical ? parent.height - root._fillEnd : parent.height
                radius: parent.radius
                // Flat when the two ends agree, a gradient when they do not.
                color: root.fill
                gradient: root.fill === root.fillLead ? null : fillRamp
            }
        }
    }

    // The handle is positioned in the CONTROL's coordinates, not the content
    // item's, so it carries the padding term the slots created. caelestia's
    // FilledSlider omits it because it has no padding.
    handle: Item {
        id: handle
        objectName: "sliderHandle"
        // Declaration order cannot express this: QQuickSlider completes its
        // handle before QQuickControl completes the contentItem, so the
        // handle is the earlier sibling however the two are written, and the
        // track and the fill painted over the thumb -- the accent line ran
        // straight through it. 1 is a stacking index, not a measurement, so
        // it is not a value a theme could retune; recorded as a deviation
        // from the no-numbers law in docs/components/Slider.md.
        z: 1
        x: root.leftPadding
            + (root.vertical ? (root.availableWidth - width) / 2 : root._thumbOffset)
        y: root.topPadding
            + (root.vertical ? root._thumbOffset : (root.availableHeight - height) / 2)
        implicitWidth: root.thumbSize
        implicitHeight: root.thumbSize
        width: implicitWidth
        height: implicitHeight

        // Inside the handle so it travels and grows with it.
        Rectangle {
            visible: root.raised && root.enabled
            width: parent.width
            height: parent.height
            y: root.pressed ? Style.sliderThumbLift * 2 : Style.sliderThumbLift
            radius: width / 2
            color: Qt.rgba(0, 0, 0, .45)

            Behavior on y {
                NumberAnimation { duration: Motion.press; easing.type: Motion.standardEasing }
            }
        }

        Rectangle {
            anchors.fill: parent
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
    }

    // The five states, owned in one place. Host mode: `hovered`, `pressed`,
    // `visualFocus` and the enabled cascade all come from the template, so
    // there is one source of each. `target: handle` is the growth-not-tint
    // rule applied where it belongs -- the THUMB grows, because growing the
    // whole control would move the track under the finger holding it. The old
    // component withheld growth entirely on the grounds that
    // `StateLayer.pressed` is a tap rather than a sustained drag; in host mode
    // `pressed` IS the sustained drag, so that objection is gone.
    StateLayer {
        objectName: "sliderLayer"
        // Level with the thumb rather than under it: the focus ring follows
        // the control's own edge, which the thumb reaches at either bound,
        // and a thumb painted over the ring is a keyboard user losing the one
        // mark that says where they are. Equal z, later child, so the ring
        // wins without a second number.
        z: handle.z
        anchors.fill: parent
        host: root
        target: handle
        focusRadius: (root.vertical ? width : height) / 2
    }

    // The cursor describes the region under it. A HoverHandler on the ANCESTOR
    // of the slots, not a filling MouseArea: a frontmost hoverEnabled item
    // would eat hover from slot content and its own StateLayer would never
    // grow. Slot content with a StateLayer of its own states its own cursor
    // and wins over this default.
    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    // Captured in `onPressedChanged`, which Qt emits BEFORE it jumps the value
    // to the press position (`mousePressEvent` calls the base class, then
    // `handleMove`), so a click on the track commits too. Do not move this
    // into anything that runs after the jump.
    property real _pressValue: 0
    property bool _keyMoved: false

    onPressedChanged: {
        if (root.pressed) {
            root._pressValue = root.value;
            root._hostDriven = false;
            return;
        }
        Qt.callLater(root._endGesture);
        if (root.value !== root._pressValue)
            root.committed();
    }

    // Qt's own Slider handles the four arrows with `stepSize` as the step, so
    // every arrow branch here MUST accept the event: `Keys` runs
    // `BeforeItem` by default, and leaving one unaccepted means both routes
    // run and a single press moves six units instead of five. Page, Home and
    // End are ours entirely -- Qt has no handler for any of them, on either
    // slider type -- and that is an EXTENSION, not parity, so a consumer
    // should not assume a stock Qt slider does the same.
    //
    // The arrows are on-axis only, which is Qt's rule: a horizontal slider
    // ignores Up and Down, and a vertical one ignores Left and Right, so the
    // surface underneath keeps them. Which arrow increases follows the visual
    // axis, so mirroring swaps the horizontal pair.
    Keys.onPressed: event => {
        if (!root.enabled)
            return;

        const onAxis = root.vertical
            ? (event.key === Qt.Key_Up || event.key === Qt.Key_Down)
            : (event.key === Qt.Key_Left || event.key === Qt.Key_Right);

        if (onAxis) {
            const forward = root.vertical
                ? Qt.Key_Up
                : (root.mirrored ? Qt.Key_Left : Qt.Key_Right);
            const units = event.key === forward
                ? Style.sliderKeyboardUnits
                : -Style.sliderKeyboardUnits;
            if (root.stepBy(units))
                root._keyMoved = true;
            event.accepted = true;
            return;
        }

        switch (event.key) {
        case Qt.Key_PageUp:
            if (root.stepBy(Style.sliderPageUnits))
                root._keyMoved = true;
            event.accepted = true;
            break;
        case Qt.Key_PageDown:
            if (root.stepBy(-Style.sliderPageUnits))
                root._keyMoved = true;
            event.accepted = true;
            break;
        case Qt.Key_Home:
            if (root.toMinimum())
                root._keyMoved = true;
            event.accepted = true;
            break;
        case Qt.Key_End:
            if (root.toMaximum())
                root._keyMoved = true;
            event.accepted = true;
            break;
        }
    }

    // One `committed` per key that actually moved something, however many
    // auto-repeats it fired on the way.
    //
    // It accepts the release of exactly the keys the press dispatcher took, so
    // those never reach `QQuickSlider::keyReleaseEvent`, which clears
    // `pressed` for any key it is given. The release of any OTHER key still
    // reaches it -- widening the accept to swallow every release would take
    // keys away from the surface, which is the opposite of what the on-axis
    // rule above is for.
    Keys.onReleased: event => {
        const ours = root.vertical
            ? (event.key === Qt.Key_Up || event.key === Qt.Key_Down)
            : (event.key === Qt.Key_Left || event.key === Qt.Key_Right);
        if (!ours
            && event.key !== Qt.Key_PageUp && event.key !== Qt.Key_PageDown
            && event.key !== Qt.Key_Home && event.key !== Qt.Key_End)
            return;

        event.accepted = true;
        if (!root._keyMoved)
            return;
        root._keyMoved = false;
        root.committed();
    }

    // 120 is not a design number and deliberately NOT a token: it is the
    // platform's own unit. Qt reports wheel rotation in eighths of a degree
    // and one notch of a physical wheel is 15 degrees, so a theme that could
    // retune this would be changing what a notch MEANS. Recorded as a
    // deviation from the no-numbers law in docs/components/Slider.md.
    readonly property int _wheelNotch: 120
    property int _wheelAccumulator: 0

    // A high-resolution touchpad sends many small deltas for one flick, so a
    // notch is 120 units ACCUMULATED -- the same threshold caelestia's
    // CustomMouseArea uses. The old handler treated any nonzero delta as a
    // full step, which is why one gesture slammed the value. Reversing
    // direction drops what was collected rather than cancelling into it, so a
    // flick back does not start half a notch ahead.
    WheelHandler {
        enabled: root.enabled && root.wheelUnits > 0
        onWheel: event => {
            // On-axis, the same rule the arrows follow: a vertical slider
            // ignores a horizontal wheel entirely, and a horizontal one takes
            // it only when there is no vertical rotation to read. The sign is
            // flipped because Qt reports a POSITIVE `angleDelta.x` when the
            // top of the wheel is moved to the LEFT (QWheelEvent), and left is
            // the decreasing end -- unflipped, scrolling right turned a volume
            // bar down.
            const delta = event.angleDelta.y !== 0
                ? event.angleDelta.y
                : (root.vertical ? 0 : -event.angleDelta.x);
            if (delta === 0)
                return;
            if (Math.sign(delta) !== Math.sign(root._wheelAccumulator))
                root._wheelAccumulator = 0;
            root._wheelAccumulator += delta;

            while (Math.abs(root._wheelAccumulator) >= root._wheelNotch) {
                const up = root._wheelAccumulator > 0;
                root._wheelAccumulator -= up ? root._wheelNotch : -root._wheelNotch;
                if (root.stepBy(up ? root.wheelUnits : -root.wheelUnits))
                    root.committed();
            }
        }
    }
}
