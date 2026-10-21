pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// THE slider. One track, one fill, one or two thumbs, either orientation,
// three sizes: `sm` is a hairline reading rail, `md` is the everyday control,
// `lg` is a hardware level (volume, brightness) whose thumb rides inside a
// control-height capsule. `range: true` adds a second thumb and the fill
// runs between the two; a plain slider is the same type with one thumb.
//
// It stands on `T.RangeSlider`, because that is the one template that can
// carry two thumbs, and a single-value slider is a range slider whose low
// thumb is parked at `from`. That parking is the one special case in the
// file and it shows up in four places -- the press router, the low thumb's
// size, which thumb the keys drive, and the virtual track edge -- each
// marked `range`. The template owns the value range, the press
// grab (no drag threshold, unstealable, a click jumps on PRESS), snapping to
// `stepSize`, `LayoutMirroring`, focus and tab traversal, and keeps
// `first.value <= second.value`, which is the one rule a range needs.
//
// What is NOT free from Qt and lives here: which thumb a press in a
// single-value slider grabs (Qt picks the nearest by VALUE, which would be
// the parked low thumb for the whole lower half, so the high thumb is moved
// to the press point first), PageUp/PageDown/Home/End, a wheel that
// ACCUMULATES rather than stepping per event, the five states through
// `StateLayer`, the label, and the look.
//
// `value` and `lowValue` are host-owned in the sense that matters: they are
// aliases of the nodes' own values, and every route writes them through Qt's
// C++ setters (the drag, `increase()`, `decrease()`, `setValues()`), which
// leaves a consumer's binding installed and live. Nothing here assigns them
// from JavaScript: that severs the binding, and the keyboard would then
// quietly behave differently from the pointer.
//
// Every colour is the host's. The component paints what it is given and dims
// it through `Style.disabled` when unavailable; it never recolours a part to
// say hover or press, because the host may have spent that colour on meaning
// (a muted channel, a clipping level).
T.RangeSlider {
    id: root

    Accessible.role: Accessible.Slider
    Accessible.name: root.accessibleName

    from: 0
    to: 1
    first.value: root.from
    // The unit every non-pointer route walks in, and never 0: at 0 Qt's own
    // arrows fall back to 0.1 VALUE units and the accessibility
    // increase/decrease actions go inert. A host that widens `from`/`to` must
    // widen `stepSize` with it, because Home and End walk the range in units.
    stepSize: Style.sliderStep
    snapMode: T.RangeSlider.SnapAlways
    // Tied to `enabled`, because `QQuickControl::hoverEnterEvent` sets
    // `hovered` to whatever `hoverEnabled` says and a disabled item is still
    // delivered hover -- the HoverHandler below turns `acceptHoverEvents` on
    // no matter what this says.
    hoverEnabled: root.enabled
    // Qt's own wheel is proportional but steps by `stepSize` and cannot be
    // switched off per call site. `wheelUnits` below is ours.
    wheelEnabled: false

    // ── values ─────────────────────────────────────────────────────────
    // Two thumbs and a fill between them. Off, the low thumb is parked at
    // `from` and never drawn, and the fill runs from `from` to `value`.
    property bool range: false
    property alias value: root.second.value
    property alias lowValue: root.first.value

    // 0 = no wheel. A seek bar wants a deliberate pointer; a volume bar is
    // something you nudge. Counted in `stepSize` units like every other
    // non-pointer route, so one number means one thing everywhere.
    property int wheelUnits: 0
    signal keyPressed(var event)
    property int decreaseKey: Interaction.sliderDecreaseKey
    property int increaseKey: Interaction.sliderIncreaseKey

    // ── colours, all the host's ────────────────────────────────────────
    property color fill: Style.primary
    property color trackColor: Style.overlay
    property color thumbColor: Style.text
    // A thin cut-out around a circle thumb. The thumb straddles the fill and
    // the track, and a light thumb on a light accent fill is 1.6:1 against it;
    // the ring is dark against the fill and the thumb is light against the
    // ring, so the thumb's edge reads on either side of the join.
    property color thumbRingColor: Style.band
    // What paints INSIDE the thumb, over `thumbColor`.
    property color thumbContentColor: Style.textOnPrimary

    // ── shape ──────────────────────────────────────────────────────────
    // A preset NAME, resolved through the theme's size table. The preset is
    // only the DEFAULT: `thickness` and `thumbSize` stay the primary API, and
    // a call site that states one keeps it through a later size change. The
    // thumb is never flush with its track: md and lg keep one step of track
    // showing around a circle.
    property string size: "md"
    // The theme's number for the CURRENT preset name, independent of
    // `thumbSize` once a call site has pinned that separately -- `thickness`
    // below tracks this, not `thumbSize`, or a pinned thumb would drag its
    // track's hairline/chunky split along with it.
    readonly property real _presetSize: Style.size("Slider", root.size)
    // One scale per instance: the preset's own ratio against md, not
    // `thumbSize` -- a call site that pins `thumbSize` separately keeps its
    // track's hairline/chunky split rather than dragging it along.
    readonly property real _s: root._presetSize / Style.size("Slider", "md")
    readonly property real sizeScale: root._s
    property real thumbSize: root._presetSize
    // Below the sm preset's own size: a hairline, one spacing unit, whatever
    // the preset. Above it: two thirds of the preset, on the rhythm. The
    // ratio is geometry, not taste. The fill's rounded end sits at the
    // thumb's centre and its shoulders are 0.707 x thickness from it, so the
    // thumb hides them only while thickness < 0.7 x thumb; "thumb minus one
    // unit" gave 0.83 at md (barely visible) and 0.9 at lg (a second pill
    // peeking out beside the thumb, owner's live finding). Two thirds keeps
    // every preset under the line and the bigger the control, the calmer
    // the join reads.
    property real thickness: root._presetSize <= Style.size("Slider", "sm")
        ? Style.space1 : Style.rhythm(root._presetSize * 2 / 3)

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

    // ── content ────────────────────────────────────────────────────────
    // Inside the high thumb: a glyph or a reading, never both. Ignored on a
    // pill; the low thumb of a range stays plain.
    property string thumbIcon: ""
    property string thumbText: ""
    // The glyph's edge. Defaults to the thumb less one step of air per side.
    property real thumbIconSize: Style.iconNear(Math.max(Style.iconXs, root.thumbSize - Style.space2 * 2))
    // A press that lands on the thumb grabs it and moves nothing: the value
    // only changes once the pointer does. Off, a press anywhere jumps the
    // value to the pointer, the thumb included.
    property bool grabThumb: false
    // Beside the control, on any of its four sides, whatever the orientation:
    // above | below | left | right. The label takes padding on its side, so
    // the track never moves to make room for it.
    property string labelText: ""
    property string labelIcon: ""
    property string labelAccessibleName: labelText
    // What a screen reader calls the slider and its thumbs. The label's own
    // action has `labelAccessibleName` (a mute button is not the slider).
    property string accessibleName: labelText
    property string labelPosition: "below"
    // The label is the slider's one action surface. Off, it is a caption and
    // takes no pointer; on, it is a button and the host decides what a click
    // means (mute, reset, open the mixer) in `onLabelClicked`.
    property bool labelClickable: false
    readonly property Item labelItem: label
    signal labelClicked()
    readonly property bool _hasLabel: labelText !== "" || labelIcon !== ""
    function activateLabel(): bool {
        if (!root.enabled || !root.labelClickable || !root._hasLabel)
            return false
        root.labelClicked()
        return true
    }
    readonly property real _labelGap: Style.rhythm(Style.space2 * root._s)
    readonly property real _labelAbove: _hasLabel && labelPosition === "above" ? label.implicitHeight + _labelGap : 0
    readonly property real _labelBelow: _hasLabel && labelPosition === "below" ? label.implicitHeight + _labelGap : 0
    readonly property real _labelLeft: _hasLabel && labelPosition === "left" ? label.implicitWidth + _labelGap : 0
    readonly property real _labelRight: _hasLabel && labelPosition === "right" ? label.implicitWidth + _labelGap : 0

    // ── events ─────────────────────────────────────────────────────────
    // `moved()` says a gesture changed a value, and the host reads `value` or
    // `lowValue`. `committed` is the END of one -- a release after a change,
    // the release of a key that changed something, and each wheel notch that
    // changed something, because a notch has no release to wait for.
    signal moved()
    signal committed()
    // A double-click that landed on the high thumb (a host's mute, say). A
    // double-click on the bare track is two jumps and never this.
    signal thumbDoubleClicked()
    first.onMoved: root.moved()
    second.onMoved: root.moved()

    // The template has no `pressed` of its own; one thumb held is the control
    // held. `StateLayer` reads it from the host.
    // A thumb held through the thumb's own drag handler (below) counts too.
    readonly property bool pressed: root.first.pressed || root.second.pressed || root._thumbHeld
    property bool _thumbHeld: false

    // The values the last gesture left behind. Set at completion rather than
    // bound, because a binding would make them follow the drag, which is the
    // one thing they must not do.
    readonly property real committedValue: root._committedValue
    readonly property real committedLowValue: root._committedLow
    property real _committedValue: 0
    property real _committedLow: 0

    function _capture(): void {
        root._committedValue = root.value;
        root._committedLow = root.lowValue;
    }
    Component.onCompleted: root._capture()
    onCommitted: root._capture()

    // ── one route per action ────────────────────────────────────────────
    // Every non-pointer route acts on ONE thumb: the last one a pointer
    // grabbed, or the high thumb when there is only one. It steps by calling
    // Qt's own `increase()` / `decrease()` on that node rather than assigning
    // a value: a JavaScript write severs the consumer's binding on the first
    // arrow key. It is also why the tokens count UNITS: a unit is exactly one
    // `increase()`. Qt clamps the low thumb at the high one and back, so a
    // range's thumbs never cross.
    property bool _lowActive: false
    readonly property var _active: root.range
        && (lowThumb.activeFocus || (root._lowActive && !highThumb.activeFocus))
        ? root.first : root.second

    function stepBy(units: int): bool {
        if (!root.enabled || units === 0)
            return false;

        const node = root._active;
        const before = node.value;
        root._hostDriven = false;
        const count = Math.abs(units);
        for (let i = 0; i < count; i++) {
            if (units > 0)
                node.increase();
            else
                node.decrease();
        }
        Qt.callLater(root._endGesture);
        return root._report(node, before);
    }

    // Lands on the nearest unit from where the active thumb is now. The
    // distance is rounded with its sign taken off and put back:
    // `Math.round(-0.5)` is `-0`, which `stepBy` reads as no work.
    function moveTo(target: real): bool {
        if (!root.enabled)
            return false;
        const clamped = Math.max(root.from, Math.min(root.to, target));
        const distance = clamped - root._active.value;
        return root.stepBy(Math.sign(distance) * Math.round(Math.abs(distance) / root.stepSize));
    }

    // The whole range in units. `setValue` clamps, so an overshoot cannot
    // help, and it refuses a write fuzzy-equal to what it holds, so only a
    // `stepSize` whose multiples can express a bound reaches it exactly.
    readonly property int _unitsInRange: Math.ceil((root.to - root.from) / root.stepSize)
    function toMinimum(): bool { return root.stepBy(-root._unitsInRange); }
    function toMaximum(): bool { return root.stepBy(root._unitsInRange); }

    function _report(node, before: real): bool {
        if (node.value === before)
            return false;
        root.moved();
        return true;
    }

    // What a consumer's action menu renders. Shortcuts are never set here:
    // which key means what is the surface's call.
    readonly property bool _canRaise: root.enabled && root._active.value < root.to
    readonly property bool _canLower: root.enabled && root._active.value > root.from
    readonly property list<T.Action> actions: [
        T.Action {
            objectName: "increase"
            text: "Increase"
            enabled: root._canRaise
            onTriggered: root.stepBy(Style.sliderKeyboardUnits)
        },
        T.Action {
            objectName: "decrease"
            text: "Decrease"
            enabled: root._canLower
            onTriggered: root.stepBy(-Style.sliderKeyboardUnits)
        },
        T.Action {
            objectName: "minimum"
            text: "Minimum"
            enabled: root._canLower
            onTriggered: root.toMinimum()
        },
        T.Action {
            objectName: "maximum"
            text: "Maximum"
            enabled: root._canRaise
            onTriggered: root.toMaximum()
        },
        T.Action {
            objectName: "activate-label"
            text: root.labelAccessibleName
            enabled: root.enabled && root.labelClickable && root._hasLabel
            onTriggered: root.activateLabel()
        }
    ]

    // ── painted colours ────────────────────────────────────────────────
    readonly property color _paintedTrack: root.enabled ? root.trackColor : Style.disabled(root.trackColor)
    readonly property color _paintedFill: root.enabled ? root.fill : Style.disabled(root.fill)
    readonly property color _paintedThumb: root.enabled ? root.thumbColor : Style.disabled(root.thumbColor)
    readonly property color _paintedThumbContent: root.enabled
        ? root.thumbContentColor : Style.disabled(root.thumbContentColor)

    // ── responsiveness ──────────────────────────────────────────────────
    // The fill and the thumbs bind to these, and they animate ONLY when the
    // change did not come from a gesture, so a thumb never trails the finger
    // while a level the system changed from elsewhere still eases in.
    //
    // `visualPosition` carries both flips but Qt emits no change signal when
    // the orientation or the mirroring flips, so the two reads here are the
    // bindings' missing dependencies, not dead code.
    function _painted(node): real {
        root.orientation;
        root.mirrored;
        return node.visualPosition;
    }
    property real _paintedHigh: root._painted(root.second)
    property real _paintedLow: root._painted(root.first)

    // False while a gesture owns a value, and for the frame after one.
    property bool _hostDriven: true

    function _endGesture(): void {
        if (!root.pressed)
            root._hostDriven = true;
    }

    // Reduced motion REMOVES these rather than shortening them: a slider is
    // the one control whose whole job is to sit where it was put.
    Behavior on _paintedHigh {
        enabled: root._hostDriven && !Style.reducedMotion
        NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing }
    }
    Behavior on _paintedLow {
        enabled: root._hostDriven && !Style.reducedMotion
        NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing }
    }

    // ── geometry along the axis ────────────────────────────────────────
    // A thumb's extent ALONG the axis: its diameter as a circle, one step as
    // a pill. Across the axis it is `_thumbCross`.
    // A circle never travels less than the track is thick: its centre rides
    // the track's own end caps, so at either bound the fill's round end is
    // concentric with the track's.
    readonly property real _thumbMain: root._pill ? Style.space1 : Math.max(root.thumbSize, root.thickness)
    // A pill stands in a gap cut through the track; a circle covers the seam.
    // The cut ends are nearly square (Material's 2dp) so the segments read as
    // one track with a bar through it, not as separate pills.
    readonly property real _gap: root._pill ? Style.space1 : 0
    // The fill's end at a thumb is a full round cap in a circle's case and
    // the rest of the track butts square UNDER it (the fill paints above), so
    // the boundary is one arc and never a notch between two caps.
    readonly property real _fillInnerRadius: root._pill ? Style.radiusXs / 2 : root.thickness / 2
    readonly property real _restInnerRadius: root._pill ? Style.radiusXs / 2 : 0
    // How far the fill runs past a circle's centre. A track thinner than its
    // thumb ends the fill AT the centre and the thumb hides the round cap. A
    // track thicker than its thumb would show that cap's shoulders and a
    // crescent, so the fill runs on to a cap CONCENTRIC with the thumb: a
    // ring of fill colour around the thumb, no straight edge, and at either
    // bound the ring is the track's own end cap.
    readonly property real _capReach: !root._pill && root.thickness > root.thumbSize ? root.thickness / 2 : 0
    readonly property real _mainSpan: root.vertical ? root.availableHeight : root.availableWidth
    readonly property real _travel: Math.max(0, _mainSpan - root._thumbMain)
    readonly property real _highOffset: root._paintedHigh * _travel
    readonly property real _lowOffset: root._paintedLow * _travel

    // The track is three segments -- rest, fill, rest -- around two thumb
    // edges, A nearer the start and B nearer the end. `visualPosition`
    // already runs a vertical slider bottom-up and swaps a mirrored one, so
    // the one orientation branch left is which end the VALUE sits at, and it
    // only matters for a single thumb: there the missing thumb is a virtual
    // edge of no extent at the value-side end, and the segment beyond it has
    // no length.
    readonly property bool _valueAtStart: root.horizontal && !root.mirrored
    readonly property bool _aIsThumb: root.range || !root._valueAtStart
    readonly property bool _bIsThumb: root.range || root._valueAtStart
    readonly property real _aOffset: root.range
        ? Math.min(root._lowOffset, root._highOffset)
        : (root._valueAtStart ? 0 : root._highOffset)
    readonly property real _bOffset: root.range
        ? Math.max(root._lowOffset, root._highOffset)
        : (root._valueAtStart ? root._highOffset : root._mainSpan)
    // Where a thumb's edges sit relative to its offset: a circle's segments
    // meet under its centre, a pill's stand one gap off either side of it.
    readonly property real _leadInset: root._pill ? -root._gap : root._thumbMain / 2
    readonly property real _trailInset: root._pill ? root._thumbMain + root._gap : root._thumbMain / 2
    readonly property real _restStartEnd: root._aIsThumb ? root._aOffset + root._leadInset : 0
    readonly property real _fillStart: root._aIsThumb ? root._aOffset + root._trailInset - root._capReach : 0
    readonly property real _fillEnd: root._bIsThumb ? root._bOffset + root._leadInset + root._capReach : root._mainSpan
    readonly property real _restEndStart: root._bIsThumb ? root._bOffset + root._trailInset : root._mainSpan

    // ── geometry across the axis ───────────────────────────────────────
    // How far a thumb grows PER SIDE under the pointer. Growth and the
    // shadow's drop OVERFLOW into the gap around the control and are never
    // added to its layout size, so the visible gap between two sliders is
    // the gap the host declared. It is not capped: a cap at the room the
    // cross extent leaves made a lg circle (thumb = cross extent) never grow.
    // A pill grows along its length only, and twice as far because that is
    // the only cue it has.
    readonly property real _hoverGrowth: Style.rhythm(Style.space1 * root._s)
    readonly property real _crossGrowth: root._hoverGrowth * (root._pill ? 2 : 1)

    // At least a comfortable hit target across the axis, whatever the track's
    // thickness: a 4px track with a 16px thumb still has to be aimable.
    readonly property real _crossSize: Math.max(Style.controlHeightSm, root.thickness, root._thumbCross)

    // The main axis is a constant PLUS what the label takes, so the track
    // keeps its natural length whatever sits beside it.
    implicitWidth: root.vertical
        ? root._crossSize + root.leftPadding + root.rightPadding
        : Style.sliderLength + root.leftPadding + root.rightPadding
    implicitHeight: root.vertical
        ? Style.sliderLengthVertical + root.topPadding + root.bottomPadding
        : root._crossSize + root.topPadding + root.bottomPadding

    // Padding is where the label sits, and the template owns the arithmetic
    // from here: the contentItem gets exactly what is left.
    leftPadding: root._labelLeft
    rightPadding: root._labelRight
    topPadding: root._labelAbove
    bottomPadding: root._labelBelow

    // The label, on the side `labelPosition` names, centred on the track
    // along the other axis. The same element `Field` puts above a text box.
    ControlLabel {
        id: label
        objectName: "sliderLabel"
        text: root.labelText
        icon: root.labelIcon
        accessibleName: root.labelAccessibleName
        clickable: root.labelClickable
        enabled: root.enabled
        sizeScale: root._s
        onClicked: root.activateLabel()
        width: implicitWidth
        height: implicitHeight
        x: root.labelPosition === "left" ? 0
            : root.labelPosition === "right" ? root.width - width
            : root.leftPadding + (root.availableWidth - width) / 2
        y: root.labelPosition === "above" ? 0
            : root.labelPosition === "below" ? root.height - height
            : root.topPadding + (root.availableHeight - height) / 2
    }

    // One track segment: a run along the axis, full radius at an end that
    // is the track's own end, nearly square at an end that faces a thumb.
    component Segment: Rectangle {
        property real start: 0
        property real length: 0
        property bool innerAtStart: false
        property bool innerAtEnd: false
        property real innerRadius: root._restInnerRadius
        readonly property real startRadius: innerAtStart ? innerRadius : radius
        readonly property real endRadius: innerAtEnd ? innerRadius : radius
        x: root.vertical ? (parent.width - width) / 2 : start
        y: root.vertical ? start : (parent.height - height) / 2
        width: root.vertical ? root.thickness : Math.max(0, length)
        height: root.vertical ? Math.max(0, length) : root.thickness
        visible: length > 0
        radius: root.thickness / 2
        topLeftRadius: startRadius
        bottomRightRadius: endRadius
        topRightRadius: root.horizontal ? endRadius : startRadius
        bottomLeftRadius: root.horizontal ? startRadius : endRadius
    }

    // Material's stop indicator: a dot in the fill's colour at each end of
    // the track a pill has left uncovered, so a pill at 5% still reads as a
    // slider and not a bar. Only when there is track to put it on.
    component StopDot: Rectangle {
        property real at: 0
        property bool shown: false
        visible: root._pill && shown
        width: Style.space1
        height: Style.space1
        radius: Style.space1 / 2
        color: root._paintedFill
        x: root.vertical ? (parent.width - width) / 2 : at
        y: root.vertical ? at : (parent.height - height) / 2
    }

    contentItem: Item {
        // Below both thumbs whatever Qt does to them: on every press it
        // raises the grabbed handle to z 1 and drops the other to z 0, and a
        // handle at 0 painted under a track at 0 that was the later sibling.
        // The template's `background` slot sits at -1 for the same reason; the
        // track lives here instead because it needs the padding inset.
        z: -1
        Segment {
            objectName: "sliderTrackStart"
            start: 0
            length: root._restStartEnd
            innerAtEnd: true
            color: root._paintedTrack
        }
        Segment {
            objectName: "sliderFill"
            z: 1
            innerRadius: root._fillInnerRadius
            start: root._fillStart
            length: root._fillEnd - root._fillStart
            innerAtStart: root._aIsThumb
            innerAtEnd: root._bIsThumb
            color: root._paintedFill
        }
        Segment {
            objectName: "sliderTrack"
            start: root._restEndStart
            length: root._mainSpan - root._restEndStart
            innerAtStart: true
            color: root._paintedTrack
        }
        StopDot {
            at: Style.space1
            shown: root._restStartEnd > Style.space1 * 3
        }
        StopDot {
            at: root._mainSpan - Style.space1 * 2
            shown: root._mainSpan - root._restEndStart > Style.space1 * 3
        }
    }

    // A thumb, positioned in the CONTROL's coordinates so it carries the
    // padding the label created. What it paints GROWS under
    // the pointer by a fixed step per side rather than by a percentage: 8% of
    // a 12px thumb was under a pixel. `pressed` is in the condition as well,
    // because a drag that leaves the control keeps the press. Press is a
    // LIFT, and only a lift; a shrink contradicted it.
    //
    // A `T.Control`, because keyboard focus lives ON a RangeSlider's handle:
    // Qt makes each handle a tab stop and `focusInEvent` on the control hands
    // focus to one (taking the stops away sends that hand-off in a circle
    // until the stack is gone).
    component Thumb: T.Control {
        id: thumb
        required property var node
        required property real offset
        property bool carriesContent: false
        property string thumbName: "sliderThumb"
        Accessible.role: Accessible.Slider
        // Tab is handled by this focused control before it can bubble to the slider.
        Keys.onPressed: event => root.keyPressed(event)
        // Qt owns the handles' z from the first press on (the grabbed one
        // rises above the other); the track sits at -1 so neither ever drops
        // under it.
        x: root.leftPadding + (root.vertical ? (root.availableWidth - width) / 2 : offset)
        y: root.topPadding + (root.vertical ? offset : (root.availableHeight - height) / 2)
        implicitWidth: root.vertical ? root._thumbCross : root._thumbMain
        implicitHeight: root.vertical ? root._thumbMain : root._thumbCross
        // A hidden thumb has NO size: Qt hit-tests a handle's geometry whether
        // or not it is visible, and a parked handle with a size caught every
        // press at the low end.
        width: visible ? implicitWidth : 0
        height: visible ? implicitHeight : 0

        readonly property bool active: root.enabled && (node.hovered || node.pressed || held)
        property real span: root._thumbCross + (active ? root._crossGrowth * 2 : 0)
        property real lift: node.pressed || held ? Style.sliderThumbLift * 2 : Style.sliderThumbLift

        // Set by the slider's one pointer path below while this thumb is grabbed.
        property bool held: false

        Behavior on span {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
        Behavior on lift {
            enabled: root.raised && !root._pill
            NumberAnimation { duration: Motion.press; easing.type: Motion.standardEasing }
        }

        Rectangle {
            objectName: thumb.thumbName + "Shadow"
            visible: root.raised && !root._pill && root.enabled
            width: thumb.span
            height: thumb.span
            x: (thumb.width - width) / 2
            y: (thumb.height - height) / 2 + thumb.lift
            radius: width / 2
            color: Qt.rgba(Style.shadow.r, Style.shadow.g, Style.shadow.b, Style.thumbShadowOpacity)
        }

        Rectangle {
            visible: !root._pill
            width: thumb.span + Style.spaceTight * 2
            height: width
            x: (thumb.width - width) / 2
            y: (thumb.height - height) / 2
            radius: width / 2
            color: root.thumbRingColor
        }

        Rectangle {
            objectName: thumb.thumbName
            width: root._pill && root.horizontal ? root._thumbMain : thumb.span
            height: root._pill && root.vertical ? root._thumbMain : thumb.span
            x: (thumb.width - width) / 2
            y: (thumb.height - height) / 2
            radius: Math.min(width, height) / 2
            color: root._paintedThumb

            Behavior on color {
                ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }

            // The glyph fits the thumb with one step of air per side; below
            // the smallest icon there is no glyph a person can read.
            Loader {
                active: thumb.carriesContent && !root._pill && root.thumbIcon !== ""
                anchors.centerIn: parent
                sourceComponent: SvgIcon {
                    name: root.thumbIcon
                    size: root.thumbIconSize
                    color: root._paintedThumbContent
                }
            }

            Loader {
                active: thumb.carriesContent && !root._pill && root.thumbIcon === "" && root.thumbText !== ""
                anchors.centerIn: parent
                // The whole thumb is the slot: "100" must fit at the same size
                // as "7", so the digits never shrink as the value grows.
                width: root.thumbSize
                height: width
                sourceComponent: Prose {
                    role: "reading"
                    text: root.thumbText
                    color: root._paintedThumbContent
                    font.pixelSize: Style.textXs
                    font.weight: Style.weightBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    second.handle: Thumb {
        id: highThumb
        objectName: "sliderHandle"
        Accessible.name: root.range ? root.accessibleName + " maximum" : root.accessibleName
        node: root.second
        offset: root._highOffset
        carriesContent: true
    }

    // Parked at `from` and hidden when there is one thumb. It stays a real
    // handle: `first.handle: null` would send the template's focus hand-off
    // into a null handle.
    first.handle: Thumb {
        id: lowThumb
        objectName: "sliderLowHandle"
        thumbName: "sliderLowThumb"
        Accessible.name: root.accessibleName + " minimum"
        node: root.first
        offset: root._lowOffset
        visible: root.range
    }

    // The five states, owned in one place. Host mode: `hovered`, `pressed`,
    // `activeFocus` and the enabled cascade all come from the template.
    //
    // It covers the TRACK and the RESTING thumbs, not the label: a focus ring
    // drawn around the label's action said the action was focused. `target:
    // null` because a scale is the wrong unit here; the thumbs grow by pixels
    // off `span` above.
    //
    // The ring is the TRACK's outline at a half-step, not the thumb's: sized
    // to the thumb it floated off the bar by the thumb's overhang and read as
    // a mistake, and flush on the track it vanished on a full accent bar
    // (WCAG 2.4.13 wants 3:1 against the adjacent colour; M3 and Radix keep
    // the indicator outside the component with a gap for the same reason).
    // Concentric with the track: `Style.childRadius` is inner = outer minus
    // inset, so outside it is outer = inner plus gap. The ring is BELOW both
    // thumbs and above the track, and a thumb, resting or grown, stands on it
    // and covers its own stretch. Qt juggles the handles between z 0 and 1 on
    // every press, hence the half step rather than a whole one.
    StateLayer {
        id: layer
        objectName: "sliderLayer"
        z: -0.5
        host: root
        target: null
        // Focus lives on a thumb, and a `T.Control` is not a focus scope:
        // measured, the control's own `activeFocus` stays false while a
        // descendant holds it, so the thumbs are read by name.
        focused: root.visualFocus || highThumb.visualFocus || lowThumb.visualFocus
        // The layer is the track's own box: the ring it draws stands off it
        // by `spaceTight` itself.
        x: root.horizontal
            ? root.leftPadding
            : root.leftPadding + (root.availableWidth - root.thickness) / 2
        y: root.horizontal
            ? root.topPadding + (root.availableHeight - root.thickness) / 2
            : root.topPadding
        width: root.horizontal ? root.availableWidth : root.thickness
        height: root.horizontal ? root.thickness : root.availableHeight
        focusRadius: root.thickness / 2
    }

    // The value under a point `along` the main axis, measured in the control's
    // own coordinates and snapped to `stepSize`. The track jump and the thumb
    // drag both land through it.
    function _valueAtAlong(along: real): real {
        const start = root.vertical ? root.topPadding : root.leftPadding;
        const visual = Math.max(0, Math.min(1, root._travel > 0 ? (along - start - root._thumbMain / 2) / root._travel : 0));
        const raw = root.valueAt(root._valueAtStart ? visual : 1 - visual);
        const snapped = root.from + Math.round((raw - root.from) / root.stepSize) * root.stepSize;
        return Math.max(root.from, Math.min(root.to, snapped));
    }

    // Which thumb a press grabs. Qt picks the node nearest the press BY
    // VALUE, which is right for a range and wrong for a single thumb: the low
    // node parked at `from` would win the whole lower half of the track. So
    // with one thumb, the high node is moved to the press point FIRST, through
    // Qt's own setter and snapped to the grid, and then the press is handed
    // on to the template, whose nearest node is now the high one at distance
    // zero. Presses on the label never come here (the label sits in the padding). `accepted = false` is what hands the press on. (A containment
    // mask on the high handle would also make Qt pick it, but at the cost of
    // the press jump and of the thumb growing on whole-track hover.)
    // ONE pointer path for the single-thumb slider, above the thumbs: a press
    // on the thumb grabs it (with `grabThumb`, keeping the pointer's offset
    // so the grab moves nothing), a press on the bare track jumps, and the
    // drag follows the pointer until release. Qt's own press never runs, so
    // nothing fights the drag on release: two drivers of one value (Qt's
    // handleRelease and a DragHandler) snapped the thumb back where the press
    // began. A host's handler on the thumb (a TapHandler) would also have
    // taken the press from Qt; double-click is reported from here instead.
    MouseArea {
        id: pointerPath
        enabled: !root.range && root.enabled
        acceptedButtons: Qt.LeftButton
        // The control's whole cross band, not the track's thickness: every
        // press the control reserves for aiming takes this one path.
        x: root.leftPadding
        y: root.topPadding
        width: root.availableWidth
        height: root.availableHeight
        z: 2
        property real _grab: 0
        // Whether this press and the one before it landed on the thumb: a
        // track press jumps the thumb under the pointer, so the second press
        // of a track double-click would otherwise read as a thumb one.
        property bool _pressedThumb: false
        property bool _previousPressedThumb: false
        function _along(mouse): real {
            const p = mapToItem(root, mouse.x, mouse.y);
            return root.horizontal ? p.x : p.y;
        }
        function _onThumb(mouse): bool {
            return highThumb.visible && highThumb.contains(mapToItem(highThumb, mouse.x, mouse.y));
        }
        onPressed: mouse => {
            // The commit compares against the value BEFORE the gesture, and
            // a track jump is already part of it.
            root._pressValue = root.second.value;
            root._preJumped = true;
            root._hostDriven = false;
            const along = _along(mouse);
            _previousPressedThumb = _pressedThumb;
            _pressedThumb = _onThumb(mouse);
            if (root.grabThumb && _pressedThumb) {
                const centre = root.mapFromItem(highThumb, highThumb.width / 2, highThumb.height / 2);
                _grab = along - (root.horizontal ? centre.x : centre.y);
            } else {
                _grab = 0;
                root.setValues(root.first.value, root._valueAtAlong(along));
                if (root.second.value !== root._pressValue)
                    root.moved();
            }
            highThumb.held = true;
            root._thumbHeld = true;
            root._pressChanged(root.second, false, true);
            if (root.focusPolicy & Qt.ClickFocus)
                highThumb.forceActiveFocus(Qt.MouseFocusReason);
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            const before = root.second.value;
            root.setValues(root.first.value, Math.max(root._valueAtAlong(_along(mouse) - _grab), root.first.value));
            if (root.second.value !== before)
                root.moved();
        }
        onReleased: {
            highThumb.held = false;
            root._thumbHeld = false;
            root._pressChanged(root.second, false, false);
        }
        onCanceled: {
            highThumb.held = false;
            root._thumbHeld = false;
            root._pressChanged(root.second, false, false);
        }
        onDoubleClicked: mouse => {
            if (_pressedThumb && _previousPressedThumb)
                root.thumbDoubleClicked();
        }
    }

    // The cursor describes the region under it. A HoverHandler on the
    // ANCESTOR, not an item that accepts hover: a frontmost hoverEnabled item
    // would eat hover from the label's action.
    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    // Captured when a node's `pressed` flips on, which Qt emits BEFORE it
    // jumps the value to the press position, so a click on the track commits
    // too. The last node grabbed is the one every keyboard route steps.
    property real _pressValue: 0
    property bool _preJumped: false
    property bool _keyMoved: false
    property var _customKeyGestures: ({})

    function _customKeyAllowed(event): bool {
        return event.key !== 0
            && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            && label.activeFocus !== true
    }

    function _customBinding(key: int): int {
        if (root.decreaseKey === root.increaseKey)
            return 0
        if (key !== 0 && key === root.decreaseKey)
            return -1
        if (key !== 0 && key === root.increaseKey)
            return 1
        return 0
    }

    function _pressChanged(node, low: bool, down: bool): void {
        if (down) {
            root._lowActive = low;
            if (!root._preJumped)
                root._pressValue = node.value;
            root._preJumped = false;
            root._hostDriven = false;
            return;
        }
        Qt.callLater(root._endGesture);
        if (node.value !== root._pressValue)
            root.committed();
    }
    first.onPressedChanged: root._pressChanged(root.first, true, root.first.pressed)
    second.onPressedChanged: root._pressChanged(root.second, false, root.second.pressed)

    // Qt's own RangeSlider handles the four arrows for the handle that has
    // focus; every branch here accepts its event first, from the focused
    // handle bubbling up, so the dispatcher below is the only keyboard route. Page, Home and End
    // are ours entirely -- an EXTENSION, not parity. Arrows are on-axis only,
    // so the surface keeps the other pair.
    Keys.onPressed: event => {
        if (!root.enabled)
            return;
        if (root.activeFocus || label.activeFocus)
            root.keyPressed(event);
        if (event.accepted)
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

        const standardKey = event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown
            || event.key === Qt.Key_Home || event.key === Qt.Key_End;
        const custom = !standardKey && root._customKeyAllowed(event)
            ? root._customBinding(event.key) : 0;
        if (custom !== 0) {
            let gesture = root._customKeyGestures[event.key];
            if (!gesture) {
                gesture = { moved: false };
                root._customKeyGestures[event.key] = gesture;
            }
            if (root.stepBy(custom * Style.sliderKeyboardUnits))
                gesture.moved = true;
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
    // press dispatcher took; the release of any other key still reaches the
    // template and the surface.
    Keys.onReleased: event => {
        const customGesture = root._customKeyGestures[event.key];
        if (customGesture) {
            event.accepted = true;
            if (event.isAutoRepeat)
                return;
            delete root._customKeyGestures[event.key];
            if (customGesture.moved)
                root.committed();
            return;
        }
        const ours = root.vertical
            ? (event.key === Qt.Key_Up || event.key === Qt.Key_Down)
            : (event.key === Qt.Key_Left || event.key === Qt.Key_Right);
        if (!ours
            && event.key !== Qt.Key_PageUp && event.key !== Qt.Key_PageDown
            && event.key !== Qt.Key_Home && event.key !== Qt.Key_End)
            return;

        event.accepted = true;
        if (event.isAutoRepeat || !root._keyMoved)
            return;
        root._keyMoved = false;
        root.committed();
    }

    // A gesture that moved a value and loses its release (focus, availability
    // or visibility gone) still ends: `committed` is the end of every gesture.
    function _clearKeyGestures(): void {
        const moved = root._keyMoved
            || Object.values(root._customKeyGestures).some(gesture => gesture.moved)
        root._customKeyGestures = ({})
        root._keyMoved = false
        if (moved)
            root.committed()
    }

    function _clearKeyGesturesWhenBlurred(): void {
        if (!root.activeFocus && !highThumb.activeFocus && !lowThumb.activeFocus)
            root._clearKeyGestures()
    }

    onActiveFocusChanged: if (!root.activeFocus) root._clearKeyGestures()
    onEnabledChanged: if (!root.enabled) root._clearKeyGestures()
    onVisibleChanged: if (!root.visible) root._clearKeyGestures()
    Connections {
        target: highThumb
        function onActiveFocusChanged(): void { root._clearKeyGesturesWhenBlurred() }
    }
    Connections {
        target: lowThumb
        function onActiveFocusChanged(): void { root._clearKeyGesturesWhenBlurred() }
    }

    // 120 is the platform's own unit, not a design number: Qt reports wheel
    // rotation in eighths of a degree and one notch is 15 degrees.
    readonly property int _wheelNotch: 120
    property int _wheelAccumulator: 0

    // A `MouseArea`, NOT a `WheelHandler`: in a live Wayland window on this
    // Qt6 QPA a `WheelHandler` never receives a wheel event at all, while a
    // `MouseArea.onWheel` does; offscreen both work. `acceptedButtons:
    // Qt.NoButton` and no hover: it takes the wheel and nothing else, so Qt's
    // own press grab still starts the drag and the label keeps its own hover
    // and clicks. A notch is 120 units ACCUMULATED, so a touchpad flick
    // is one step and not one per delta.
    MouseArea {
        anchors.fill: parent
        enabled: root.enabled && root.wheelUnits > 0
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            // A vertical wheel drives either orientation: a mouse has no other
            // axis, and `wheelUnits > 0` is the host's opt-in, so a host that
            // wants the scroller beneath the slider leaves it 0. A sideways
            // wheel drives a horizontal slider only. The sign is flipped
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
