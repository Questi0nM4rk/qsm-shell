pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// THE slider. One track, one fill, one thumb, either orientation, three
// sizes: `sm` is a hairline reading rail, `md` is the everyday control, `lg`
// is a hardware level (volume, brightness) whose thumb rides inside a
// control-height capsule.
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
// than stepping per event, the five states through `StateLayer`, the slots,
// the label, and the look.
//
// `value` is host-owned in the sense that matters. Every route writes it
// through Qt's own C++ setter -- the drag, `increase()`, `decrease()` -- which
// leaves a consumer's `value:` binding installed and live, so a level the
// system also changes from elsewhere still lands. Nothing here ever assigns
// `value` from JavaScript: that severs the binding, and the keyboard would
// then quietly behave differently from the pointer.
//
// Every colour is the host's. The component paints what it is given and dims
// it through `Style.disabled` when unavailable; it never recolours a part to
// say hover or press, because the host may have spent that colour on meaning
// (a muted channel, a clipping level).
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
    // Tied to `enabled`, because `QQuickControl::hoverEnterEvent` sets
    // `hovered` to whatever `hoverEnabled` says and a disabled item is still
    // delivered hover -- the HoverHandler below turns `acceptHoverEvents` on
    // no matter what this says.
    hoverEnabled: root.enabled
    // Qt's own wheel is proportional but steps by `stepSize` and cannot be
    // switched off per call site. `wheelUnits` below is ours.
    wheelEnabled: false

    // 0 = no wheel. A seek bar wants a deliberate pointer; a volume bar is
    // something you nudge. Counted in `stepSize` units like every other
    // non-pointer route, so one number means one thing everywhere.
    property int wheelUnits: 0

    // ── colours, all the host's ────────────────────────────────────────
    property color fill: Style.accent
    property color trackColor: Style.outline
    property color thumbColor: Style.text
    // What paints INSIDE the thumb, over `thumbColor`.
    property color thumbContentColor: Style.background

    // ── shape ──────────────────────────────────────────────────────────
    // sm | md | lg. The preset is only the DEFAULT: `thickness` and
    // `thumbSize` stay the primary API, and a call site that states one keeps
    // it through a later size change.
    property string size: "md"
    readonly property bool _sm: size === "sm"
    readonly property bool _lg: size === "lg"
    // The thumb is never flush with its track: md and lg keep one step of
    // track showing around a circle riding in it.
    property real thumbSize: root._sm ? Style.iconSm : root._lg ? Style.controlHeight : Style.iconLg
    property real thickness: root._sm ? Style.space1 : root.thumbSize - Style.space1

    // circle | pill. A circle rides ON the track and can carry a glyph or a
    // reading; a pill is Material's narrow bar standing in a gap cut through
    // the track, and carries nothing. It stands one spacing step proud of the
    // track, whatever `thumbSize` says, because a bar that only matched the
    // track would vanish into the cut.
    property string thumbStyle: "circle"
    readonly property bool _pill: thumbStyle === "pill"
    readonly property real _thumbCross: root._pill ? root.thickness + Style.space2 : root.thumbSize

    // A raised thumb casts a shadow and lifts further while pressed, which is
    // what makes a big thumb read as picked up out of its capsule. A hairline
    // rail does not want one, and a pill never has one.
    property bool raised: false

    // The gap between the track and whatever sits in the end slots.
    property real slotGap: Style.space2

    // ── content ────────────────────────────────────────────────────────
    // Inside the thumb: a glyph or a reading, never both. Ignored on a pill.
    property string thumbIcon: ""
    property string thumbText: ""
    // Beside the control, on any of its four sides, whatever the orientation:
    // above | below | left | right. The label takes padding on its side, the
    // way a slot does, so the track never moves to make room for it.
    property string labelText: ""
    property string labelIcon: ""
    property string labelPosition: "below"
    // The label is the slider's one action surface. Off, it is a caption and
    // takes no pointer; on, it is a button and the host decides what a click
    // means (mute, reset, open the mixer) in `onLabelClicked`.
    property bool labelClickable: false
    signal labelClicked()
    readonly property bool _hasLabel: labelText !== "" || labelIcon !== ""
    readonly property real _labelAbove: _hasLabel && labelPosition === "above" ? label.implicitHeight + Style.space2 : 0
    readonly property real _labelBelow: _hasLabel && labelPosition === "below" ? label.implicitHeight + Style.space2 : 0
    readonly property real _labelLeft: _hasLabel && labelPosition === "left" ? label.implicitWidth + Style.space2 : 0
    readonly property real _labelRight: _hasLabel && labelPosition === "right" ? label.implicitWidth + Style.space2 : 0

    // `before` and `after` sit at the ends ALONG the axis and become padding,
    // so the track and the thumb travel in what is left. On a vertical slider
    // `before` is the top, which is the high end. An empty slot takes no
    // space, so a bare slider looks exactly like a bare slider.
    property alias before: beforeSlot.data
    property alias after: afterSlot.data

    // `moved()` is Qt's and carries no argument: it says a gesture changed the
    // value, and the host reads `value`. `committed` is the END of one -- a
    // release after a change, the release of a key that changed something, and
    // each wheel notch that changed something, because a notch has no release
    // to wait for.
    signal committed()

    // The value the last gesture left behind. Set at completion rather than
    // bound, because a binding to `value` would make it follow the drag,
    // which is the one thing it must not do.
    readonly property real committedValue: root._committedValue
    property real _committedValue: 0

    Component.onCompleted: root._committedValue = root.value
    onCommitted: root._committedValue = root.value

    // ── one route per action ────────────────────────────────────────────
    // Every non-pointer route steps by calling Qt's own `increase()` /
    // `decrease()` rather than assigning `value`: a JavaScript write severs
    // the consumer's `value:` binding on the first arrow key. It is also why
    // the tokens count UNITS: a unit is exactly one `increase()`.
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

    // Lands on the nearest unit from where the value is now. The distance is
    // rounded with its sign taken off and put back: `Math.round(-0.5)` is
    // `-0`, which `stepBy` reads as no work.
    function moveTo(target: real): bool {
        if (!root.enabled)
            return false;
        const clamped = Math.max(root.from, Math.min(root.to, target));
        const distance = clamped - root.value;
        return root.stepBy(Math.sign(distance) * Math.round(Math.abs(distance) / root.stepSize));
    }

    // The whole range in units. `setValue` clamps, so an overshoot cannot
    // help, and it refuses a write fuzzy-equal to what it holds, so only a
    // `stepSize` whose multiples can express a bound reaches it exactly.
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

    // ── painted colours ────────────────────────────────────────────────
    readonly property color _paintedTrack: root.enabled ? root.trackColor : Style.disabled(root.trackColor)
    readonly property color _paintedFill: root.enabled ? root.fill : Style.disabled(root.fill)
    readonly property color _paintedThumb: root.enabled ? root.thumbColor : Style.disabled(root.thumbColor)
    readonly property color _paintedThumbContent: root.enabled
        ? root.thumbContentColor : Style.disabled(root.thumbContentColor)
    readonly property color _paintedLabel: root.enabled ? Style.textMuted : Style.disabled(Style.textMuted)

    // ── responsiveness ──────────────────────────────────────────────────
    // The fill and the thumb bind to this, and it animates ONLY when the
    // change did not come from a gesture, so the thumb never trails the
    // finger while a level the system changed from elsewhere still eases in.
    //
    // `visualPosition` carries both flips but Qt emits no change signal when
    // the orientation or the mirroring flips, so the two reads below are the
    // binding's missing dependencies, not dead code.
    property real _paintedPosition: {
        root.orientation;
        root.mirrored;
        return root.visualPosition;
    }

    // False while a gesture owns the value, and for the frame after one.
    property bool _hostDriven: true

    function _endGesture(): void {
        if (!root.pressed)
            root._hostDriven = true;
    }

    Behavior on _paintedPosition {
        // Reduced motion REMOVES this one rather than shortening it: a slider
        // is the one control whose whole job is to sit where it was put.
        enabled: root._hostDriven && !Style.reducedMotion
        NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing }
    }

    // ── geometry along the axis ────────────────────────────────────────
    // The thumb's extent ALONG the axis: its diameter as a circle, one step
    // as a pill. Across the axis it is `_thumbCross`.
    readonly property real _thumbMain: root._pill ? Style.space1 : root.thumbSize
    // A pill stands in a gap cut through the track; a circle covers the seam.
    // The cut ends are nearly square (Material's 2dp) so the two segments read
    // as one track with a bar through it, not as two pills.
    readonly property real _gap: root._pill ? Style.space1 : 0
    readonly property real _innerRadius: root._pill ? Style.radiusXs / 2 : root.thickness / 2
    readonly property real _mainSpan: root.vertical ? root.availableHeight : root.availableWidth
    readonly property real _travel: Math.max(0, _mainSpan - root._thumbMain)
    readonly property real _thumbOffset: root._paintedPosition * _travel
    // The track is two segments with the thumb between them. `visualPosition`
    // already runs a vertical slider bottom-up and swaps a mirrored one, so
    // the only orientation branch left is which segment is the VALUE.
    readonly property bool _valueAtStart: root.horizontal && !root.mirrored
    readonly property real _segAEnd: root._pill
        ? root._thumbOffset - root._gap
        : root._thumbOffset + root._thumbMain / 2
    readonly property real _segBStart: root._pill
        ? root._thumbOffset + root._thumbMain + root._gap
        : root._thumbOffset + root._thumbMain / 2
    readonly property real _fillStart: root._valueAtStart ? 0 : root._segBStart
    readonly property real _fillLength: Math.max(0, root._valueAtStart ? root._segAEnd : root._mainSpan - root._segBStart)
    readonly property real _restStart: root._valueAtStart ? root._segBStart : 0
    readonly property real _restLength: Math.max(0, root._valueAtStart ? root._mainSpan - root._segBStart : root._segAEnd)

    // ── geometry across the axis ───────────────────────────────────────
    // How far the thumb grows PER SIDE under the pointer. Reserved at rest as
    // well: reserving it only on hover would move the track under the pointer
    // that is hovering it. A pill grows along its length only, and twice as
    // far because that is the only cue it has.
    readonly property real _hoverGrowth: Style.space1
    readonly property real _crossGrowth: root._hoverGrowth * (root._pill ? 2 : 1)
    // The shadow drops along `y` in BOTH orientations -- it is gravity, not
    // the axis -- so its slack is cross-axis on a horizontal slider and
    // main-axis on a vertical one.
    readonly property real _shadowDrop: root.raised && !root._pill ? Style.sliderThumbLift * 2 : 0
    readonly property real _thumbSpan: root._thumbCross + root._crossGrowth * 2
        + (root.vertical ? 0 : root._shadowDrop * 2)

    // At least a comfortable hit target across the axis, whatever the track's
    // thickness: a 4px track with a 16px thumb still has to be aimable.
    readonly property real _crossSize: Math.max(
        Style.controlHeightSm, root.thickness, root._thumbSpan,
        root.vertical
            ? Math.max(beforeSlot.implicitWidth, afterSlot.implicitWidth)
            : Math.max(beforeSlot.implicitHeight, afterSlot.implicitHeight))

    // The main axis is a constant PLUS what the slots take, so the track keeps
    // its natural length whatever sits at its ends. Sized by content, a slot
    // ate a quarter of the travel.
    implicitWidth: root.vertical
        ? root._crossSize + root.leftPadding + root.rightPadding
        : Style.sliderLength + root.leftPadding + root.rightPadding
    implicitHeight: root.vertical
        ? Style.sliderLengthVertical + root.topPadding + root.bottomPadding
        : root._crossSize + root.topPadding + root.bottomPadding

    // Padding is where the slots and the label sit, and the template owns
    // the arithmetic from here: the contentItem gets exactly what is left.
    // Both ends of the MAIN axis keep `_hoverGrowth`, because at either bound
    // the thumb is flush with the end of the track and its growth has nowhere
    // else to go; the bottom of a vertical one keeps the shadow's drop too.
    // On a mirrored horizontal slider `before` sits at the RIGHT. The label
    // is outermost on its side, then the slot, then the growth.
    readonly property var _startSlot: root.horizontal && root.mirrored ? afterSlot : beforeSlot
    readonly property var _endSlot: root.horizontal && root.mirrored ? beforeSlot : afterSlot

    leftPadding: root._labelLeft + (root.horizontal
        ? (root._startSlot.hasContent ? root._startSlot.implicitWidth + root.slotGap : 0) + root._hoverGrowth
        : 0)
    rightPadding: root._labelRight + (root.horizontal
        ? (root._endSlot.hasContent ? root._endSlot.implicitWidth + root.slotGap : 0) + root._hoverGrowth
        : 0)
    topPadding: root._labelAbove + (root.vertical
        ? (beforeSlot.hasContent ? beforeSlot.implicitHeight + root.slotGap : 0) + root._hoverGrowth
        : 0)
    bottomPadding: root._labelBelow + (root.vertical
        ? (afterSlot.hasContent ? afterSlot.implicitHeight + root.slotGap : 0) + root._hoverGrowth + root._shadowDrop
        : 0)

    // Does this slot hold anything? A `Loader` that unloads still reports an
    // implicit size with `item` null, so a child that loads its content
    // counts once it HAS it; any other child counts by being there.
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

    // Geometry, not anchors: a ternary that yields `undefined` does NOT
    // withdraw an anchor, so an item that works in two orientations states
    // its own rectangle.
    Item {
        id: beforeSlot
        readonly property bool hasContent: root._slotHasContent(beforeSlot)
        readonly property bool atStart: root.vertical || !root.mirrored
        x: root.vertical
            ? root.leftPadding + (root.availableWidth - width) / 2
            : (atStart ? root._labelLeft + root._hoverGrowth : root.width - width - root._labelRight - root._hoverGrowth)
        y: root.vertical
            ? root._labelAbove + root._hoverGrowth
            : root.topPadding + (root.availableHeight - height) / 2
        implicitWidth: hasContent ? childrenRect.width : 0
        implicitHeight: hasContent ? childrenRect.height : 0
        width: implicitWidth
        height: implicitHeight
    }

    Item {
        id: afterSlot
        readonly property bool hasContent: root._slotHasContent(afterSlot)
        readonly property bool atStart: root.horizontal && root.mirrored
        x: root.vertical
            ? root.leftPadding + (root.availableWidth - width) / 2
            : (atStart ? root._labelLeft + root._hoverGrowth : root.width - width - root._labelRight - root._hoverGrowth)
        y: root.vertical
            ? root.height - height - root._labelBelow - root._hoverGrowth - root._shadowDrop
            : root.topPadding + (root.availableHeight - height) / 2
        implicitWidth: hasContent ? childrenRect.width : 0
        implicitHeight: hasContent ? childrenRect.height : 0
        width: implicitWidth
        height: implicitHeight
    }

    // The label, on the side `labelPosition` names, centred on the track
    // along the other axis. A clickable label keeps a hit box at least one
    // large icon tall, whatever its text measures.
    Item {
        id: label
        objectName: "sliderLabel"
        visible: root._hasLabel
        implicitWidth: Math.max(labelRow.implicitWidth, root.labelClickable ? Style.iconLg : 0)
        implicitHeight: Math.max(labelRow.implicitHeight, root.labelClickable ? Style.iconLg : 0)
        width: implicitWidth
        height: implicitHeight
        x: root.labelPosition === "left" ? 0
            : root.labelPosition === "right" ? root.width - width
            : root.leftPadding + (root.availableWidth - width) / 2
        y: root.labelPosition === "above" ? 0
            : root.labelPosition === "below" ? root.height - height
            : root.topPadding + (root.availableHeight - height) / 2

        Row {
            id: labelRow
            anchors.centerIn: parent
            spacing: Style.space1

            Loader {
                active: root.labelIcon !== ""
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: SvgIcon {
                    name: root.labelIcon
                    size: Style.iconSm
                    color: root._paintedLabel
                }
            }
            Prose {
                visible: root.labelText !== ""
                anchors.verticalCenter: parent.verticalCenter
                role: "metadata"
                text: root.labelText
                color: root._paintedLabel
            }
        }

        StateLayer {
            anchors.fill: parent
            target: label
            interactive: root.labelClickable && root.enabled
            focusRadius: Style.radiusSm
            onClicked: root.labelClicked()
        }
    }

    contentItem: Item {
        // The remaining track, on the far side of the thumb.
        Rectangle {
            id: track
            objectName: "sliderTrack"
            x: root.vertical ? (parent.width - width) / 2 : root._restStart
            y: root.vertical ? root._restStart : (parent.height - height) / 2
            width: root.vertical ? root.thickness : root._restLength
            height: root.vertical ? root._restLength : root.thickness
            color: root._paintedTrack
            // The end that faces the thumb is the inner one.
            readonly property bool innerAtEnd: !root._valueAtStart
            radius: root.thickness / 2
            topLeftRadius: innerAtEnd ? radius : root._innerRadius
            bottomRightRadius: innerAtEnd ? root._innerRadius : radius
            topRightRadius: root.horizontal
                ? (innerAtEnd ? root._innerRadius : radius) : (innerAtEnd ? radius : root._innerRadius)
            bottomLeftRadius: root.horizontal
                ? (innerAtEnd ? radius : root._innerRadius) : (innerAtEnd ? root._innerRadius : radius)

            // Material's stop indicator: where the range ends, in the fill's
            // colour, so a pill at 5% still reads as a slider and not a bar.
            Rectangle {
                visible: root._pill && root._restLength > Style.space1 * 3
                width: Style.space1
                height: Style.space1
                radius: Style.space1 / 2
                color: root._paintedFill
                x: root.vertical
                    ? (parent.width - width) / 2
                    : (root._valueAtStart ? parent.width - width - Style.space1 : Style.space1)
                y: root.vertical
                    ? (root._valueAtStart ? parent.height - height - Style.space1 : Style.space1)
                    : (parent.height - height) / 2
            }
        }

        // The value, from the low end to the thumb.
        Rectangle {
            objectName: "sliderFill"
            x: root.vertical ? (parent.width - width) / 2 : root._fillStart
            y: root.vertical ? root._fillStart : (parent.height - height) / 2
            width: root.vertical ? root.thickness : root._fillLength
            height: root.vertical ? root._fillLength : root.thickness
            color: root._paintedFill
            readonly property bool innerAtEnd: root._valueAtStart
            radius: root.thickness / 2
            topLeftRadius: innerAtEnd ? radius : root._innerRadius
            bottomRightRadius: innerAtEnd ? root._innerRadius : radius
            topRightRadius: root.horizontal
                ? (innerAtEnd ? root._innerRadius : radius) : (innerAtEnd ? radius : root._innerRadius)
            bottomLeftRadius: root.horizontal
                ? (innerAtEnd ? radius : root._innerRadius) : (innerAtEnd ? root._innerRadius : radius)
        }
    }

    // The handle is positioned in the CONTROL's coordinates, so it carries
    // the padding term the slots and the label created.
    handle: Item {
        id: handle
        objectName: "sliderHandle"
        // QQuickSlider completes its handle before QQuickControl completes the
        // contentItem, so the handle is the earlier sibling however the two
        // are written, and the track painted over the thumb. A stacking
        // index, not a measurement.
        z: 1
        x: root.leftPadding + (root.vertical ? (root.availableWidth - width) / 2 : root._thumbOffset)
        y: root.topPadding + (root.vertical ? root._thumbOffset : (root.availableHeight - height) / 2)
        implicitWidth: root.vertical ? root._thumbCross : root._thumbMain
        implicitHeight: root.vertical ? root._thumbMain : root._thumbCross
        width: implicitWidth
        height: implicitHeight

        // What the thumb paints across the axis. It GROWS under the pointer by
        // a fixed step per side rather than by a percentage: 8% of a 12px
        // thumb was under a pixel. `pressed` is in the condition as well,
        // because a drag that leaves the control keeps the press.
        property real span: root._thumbCross
            + (layer.hovered || layer.pressed ? root._crossGrowth * 2 : 0)
        // Press is a LIFT, and only a lift; a shrink contradicted it.
        property real lift: root.pressed ? Style.sliderThumbLift * 2 : Style.sliderThumbLift

        Behavior on span {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
        Behavior on lift {
            NumberAnimation { duration: Motion.press; easing.type: Motion.standardEasing }
        }

        Rectangle {
            objectName: "sliderThumbShadow"
            visible: root.raised && !root._pill && root.enabled
            width: handle.span
            height: handle.span
            x: (handle.width - width) / 2
            y: (handle.height - height) / 2 + handle.lift
            radius: width / 2
            color: Qt.rgba(0, 0, 0, .45)
        }

        Rectangle {
            id: thumb
            objectName: "sliderThumb"
            width: root._pill && root.horizontal ? root._thumbMain : handle.span
            height: root._pill && root.vertical ? root._thumbMain : handle.span
            x: (handle.width - width) / 2
            y: (handle.height - height) / 2
            radius: Math.min(width, height) / 2
            color: root._paintedThumb

            Behavior on color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }

            // The glyph fits the thumb with one step of air per side; below
            // the smallest icon there is no glyph a person can read.
            Loader {
                active: !root._pill && root.thumbIcon !== ""
                anchors.centerIn: parent
                sourceComponent: SvgIcon {
                    name: root.thumbIcon
                    size: Math.max(Style.iconXs, root.thumbSize - Style.space2 * 2)
                    color: root._paintedThumbContent
                }
            }

            Loader {
                active: !root._pill && root.thumbIcon === "" && root.thumbText !== ""
                anchors.centerIn: parent
                width: root.thumbSize - Style.space1 * 2
                height: width
                sourceComponent: Text {
                    text: root.thumbText
                    color: root._paintedThumbContent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.textSm
                    font.weight: Style.weightBold
                    fontSizeMode: Text.Fit
                    minimumPixelSize: Style.textXs
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    // The five states, owned in one place. Host mode: `hovered`, `pressed`,
    // `visualFocus` and the enabled cascade all come from the template.
    //
    // It covers the TRACK and the thumb's growth, not the slots or the label:
    // a focus ring drawn around an action sitting in a slot said the action
    // was focused. `target: null` because a scale is the wrong unit here;
    // the thumb grows by pixels off `span` above.
    StateLayer {
        id: layer
        objectName: "sliderLayer"
        // Level with the thumb rather than under it, so the ring wins at the
        // bounds without a second number.
        z: handle.z
        host: root
        target: null
        x: root.horizontal
            ? root.leftPadding - root._hoverGrowth
            : root.leftPadding + (root.availableWidth - root._thumbSpan) / 2
        y: root.horizontal
            ? root.topPadding + (root.availableHeight - root._thumbSpan) / 2
            : root.topPadding - root._hoverGrowth
        width: root.horizontal ? root.availableWidth + root._hoverGrowth * 2 : root._thumbSpan
        height: root.horizontal ? root._thumbSpan : root.availableHeight + root._hoverGrowth * 2
        focusRadius: Math.min(width, height) / 2
    }

    // The cursor describes the region under it. A HoverHandler on the ANCESTOR
    // of the slots, not an item that accepts hover: a frontmost hoverEnabled
    // item would eat hover from slot content.
    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    // Captured in `onPressedChanged`, which Qt emits BEFORE it jumps the value
    // to the press position, so a click on the track commits too.
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
    // every arrow branch here MUST accept the event or both routes run. Page,
    // Home and End are ours entirely -- an EXTENSION, not parity. Arrows are
    // on-axis only, which is Qt's rule, so the surface keeps the other pair.
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
    // auto-repeats it fired. It accepts the release of exactly the keys the
    // press dispatcher took, so those never reach QQuickSlider's release
    // handler, which clears `pressed` for any key it is given.
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

    // 120 is the platform's own unit, not a design number: Qt reports wheel
    // rotation in eighths of a degree and one notch is 15 degrees.
    readonly property int _wheelNotch: 120
    property int _wheelAccumulator: 0

    // A `MouseArea`, NOT a `WheelHandler`: in a live Wayland window on this
    // Qt6 QPA a `WheelHandler` never receives a wheel event at all, while a
    // `MouseArea.onWheel` does; offscreen both work. `acceptedButtons:
    // Qt.NoButton` and no hover: it takes the wheel and nothing else, so Qt's
    // own press grab still starts the drag and slot content keeps its own
    // hover and clicks. A notch is 120 units ACCUMULATED, so a touchpad flick
    // is one step and not one per delta.
    MouseArea {
        anchors.fill: parent
        enabled: root.enabled && root.wheelUnits > 0
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            // On-axis, the same rule the arrows follow. The sign is flipped
            // because Qt reports a POSITIVE `angleDelta.x` when the top of the
            // wheel is moved to the LEFT.
            const delta = event.angleDelta.y !== 0
                ? event.angleDelta.y
                : (root.vertical ? 0 : -event.angleDelta.x);
            // Nothing on this axis to answer: hand the event BACK, or this
            // area silently disables its host's scrolling.
            if (delta === 0) {
                event.accepted = false;
                return;
            }
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
