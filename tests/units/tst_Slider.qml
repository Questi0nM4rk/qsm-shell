import QtQuick
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style

// `value` is written by Qt itself now -- the drag, increase() and decrease()
// all go through the template's C++ setter -- so none of these sliders wires
// `moved` back into its own value the way the hand-rolled one needed. What the
// C++ setter does NOT do is sever a QML binding on `value`, which is the whole
// reason the keyboard and wheel routes step through increase()/decrease()
// instead of assigning: `sliderBound` below is that contract, kept.
//
// Every case drives a REAL pointer, wheel or key event; qmllint cannot see any
// of this. `moved()` carries no argument and means "a gesture changed a
// value"; `committed()` means "the gesture ended".
TestCase {
    id: probe

    name: "Slider"
    width: 400
    height: 760
    visible: true
    when: windowShown

    readonly property real keyStep: Style.sliderKeyboardUnits * Style.sliderStep
    readonly property real pageStep: Style.sliderPageUnits * Style.sliderStep

    Slider {
        id: sliderH
        x: 100; y: 20; width: 200; height: 32
        value: 0.5
    }
    SignalSpy { id: movedSpyH; target: sliderH; signalName: "moved" }
    SignalSpy { id: committedSpyH; target: sliderH; signalName: "committed" }

    Slider {
        id: sliderWheel
        x: 100; y: 90; width: 200; height: 32
        value: 0.5
        wheelUnits: Style.sliderKeyboardUnits
    }
    SignalSpy { id: committedSpyWheel; target: sliderWheel; signalName: "committed" }

    Slider {
        id: sliderVert
        x: 340; y: 60; width: 32; height: 200
        orientation: Qt.Vertical
        value: 0.5
    }

    Slider {
        id: sliderDisabled
        x: 100; y: 130; width: 200; height: 32
        value: 0.5
        wheelUnits: Style.sliderKeyboardUnits
        enabled: false
    }
    SignalSpy { id: movedSpyDisabled; target: sliderDisabled; signalName: "moved" }

    Slider {
        id: sliderKeyboard
        x: 100; y: 180; width: 200; height: 32
        value: 0.5
    }
    SignalSpy { id: movedSpyKeyboard; target: sliderKeyboard; signalName: "moved" }
    SignalSpy { id: committedSpyKeyboard; target: sliderKeyboard; signalName: "committed" }

    // Left unwired on purpose: a direct write is not a gesture.
    Slider {
        id: sliderProg
        x: 100; y: 230; width: 200; height: 32
        value: 0.5
    }
    SignalSpy { id: movedSpyProg; target: sliderProg; signalName: "moved" }

    // The consumer's shape: `value` bound to something the host owns. Every
    // consumer call site looks like this, and none of them writes value back.
    property real hostSource: 0.3
    Slider {
        id: sliderBound
        x: 100; y: 270; width: 200; height: 32
        value: probe.hostSource
    }

    Slider {
        id: sliderRtl
        x: 100; y: 320; width: 200; height: 32
        LayoutMirroring.enabled: true
        LayoutMirroring.childrenInherit: true
        value: 0.5
    }

    // No height: the cross axis is whatever the control asks for, so a
    // thickness written here has to grow the control rather than be clipped
    // by it.
    Slider {
        id: sliderFat
        x: 100; y: 370; width: 200
        value: 0.5
    }

    // Two thumbs. `lowValue` is bound, the way a host binds it.
    property real rangeLow: 0.2
    Slider {
        id: sliderRange
        x: 100; y: 420; width: 200; height: 32
        range: true
        value: 0.8
        lowValue: probe.rangeLow
    }

    // Built HORIZONTAL and flipped at runtime, which is what every unit in a
    // preview does: the host writes `variant` through `onLoaded`, after the
    // scene was constructed. Sized for the vertical life it ends up in.
    Slider {
        id: sliderFlip
        x: 340; y: 320; width: 40; height: 200
        value: 0.82
    }

    // Never gestured and never written by any case here, which is what makes
    // it the one instance that can answer what `committedValue` starts as.
    Slider {
        id: sliderFresh
        x: 100; y: 470; width: 200; height: 32
        value: 0.35
    }

    // The size presets, and the explicit override that has to outlive a
    // preset change. No height: the cross axis is whatever the preset asks
    // for.
    Slider {
        id: sliderSize
        x: 100; y: 510; width: 200
        value: 0.5
    }

    // Raised and VERTICAL: the case where the shadow drops along the MAIN
    // axis, which is the one nothing padded.
    Slider {
        id: sliderVertRaised
        x: 310; y: 500; width: 60; height: 200
        orientation: Qt.Vertical
        raised: true
        value: 0.5
    }

    // Hover and press growth, clear of every other case so no stray pointer
    // move can leave it hovered.
    Slider {
        id: sliderHover
        x: 100; y: 600; width: 200
        value: 0.5
        raised: true
    }

    function test_dragging_the_thumb_follows_the_pointer_and_changes_value() {
        sliderH.value = 0.5;
        movedSpyH.clear();

        mousePress(sliderH, 40, 16);
        const afterPress = sliderH.value;
        mouseMove(sliderH, 90, 16);
        const afterFirstMove = sliderH.value;
        mouseMove(sliderH, 140, 16);
        const afterSecondMove = sliderH.value;
        mouseMove(sliderH, 190, 16);
        const afterThirdMove = sliderH.value;
        mouseRelease(sliderH, 190, 16);

        verify(movedSpyH.count > 0, "moved never fired while dragging the thumb");
        verify(afterPress < afterFirstMove,
            "value did not increase as the pointer kept moving right (press -> first move)");
        verify(afterFirstMove < afterSecondMove,
            "value did not increase as the pointer kept moving right (first -> second move)");
        verify(afterSecondMove < afterThirdMove,
            "value did not increase as the pointer kept moving right (second -> third move) -- "
            + "a drag that stops changing value partway through the track is a jump to a fixed step, not a follow");
    }

    function test_dragging_past_either_end_clamps_exactly_to_the_bound() {
        sliderH.value = 0.5;

        mousePress(sliderH, 100, 16);
        mouseMove(sliderH, -50, 16);
        verify(sliderH.value === sliderH.from, "dragging past the left end did not clamp exactly to `from`");

        mouseMove(sliderH, 250, 16);
        verify(sliderH.value === sliderH.to, "dragging past the right end did not clamp exactly to `to`");

        mouseRelease(sliderH, 250, 16);
    }

    // The handle is where visualPosition says it is IN THE SAME TURN as the
    // move event. No tryCompare and no wait on purpose: the 180ms Behavior
    // that used to run during the drag is exactly the lag this rebuild
    // removes, and a tryCompare would wait it out and call it a pass.
    function test_the_handle_reaches_the_pointer_in_the_same_frame() {
        sliderH.value = 0.5;

        mousePress(sliderH, 40, 16);
        compare(sliderH._hostDriven, false, "a press did not switch the animation off");

        mouseMove(sliderH, 170, 16);
        const expected = sliderH.leftPadding
            + sliderH.second.visualPosition * (sliderH.availableWidth - sliderH.second.handle.width);
        fuzzyCompare(sliderH.second.handle.x, expected, 0.5,
            "the handle is not where visualPosition says it is right after the move -- it is animating there");

        mouseRelease(sliderH, 170, 16);
        tryCompare(sliderH, "_hostDriven", true, 500);
    }

    function test_a_wheel_notch_moves_value_by_wheelUnits_in_the_declared_direction() {
        sliderWheel.value = 0.5;
        mouseMove(sliderWheel, 100, 16);

        mouseWheel(sliderWheel, 100, 16, 0, 120);
        wait(50);
        fuzzyCompare(sliderWheel.value, 0.5 + probe.keyStep, 0.0001,
            "a positive wheel notch did not move value by wheelUnits steps");

        mouseWheel(sliderWheel, 100, 16, 0, -120);
        wait(50);
        fuzzyCompare(sliderWheel.value, 0.5, 0.0001,
            "a negative wheel notch did not undo it");

        // A horizontal wheel on a HORIZONTAL slider, which is the one axis
        // whose sign is not obvious: Qt reports a POSITIVE angleDelta.x when
        // the top of the wheel goes LEFT, and left is the decreasing end.
        mouseWheel(sliderWheel, 100, 16, -120, 0);
        wait(50);
        fuzzyCompare(sliderWheel.value, 0.5 + probe.keyStep, 0.0001,
            "scrolling a horizontal slider to the RIGHT did not increase it -- "
            + "angleDelta.x is positive leftward, so it has to be flipped");
    }

    // A high-resolution touchpad sends many small angleDelta values for one
    // physical flick. Treating each as a notch is what made one gesture slam
    // the value, so a notch is 120 units accumulated, and a reversal drops
    // what was collected rather than cancelling into it.
    function test_a_wheel_accumulates_to_one_notch_before_it_moves() {
        sliderWheel.value = 0.5;
        mouseMove(sliderWheel, 100, 16);

        mouseWheel(sliderWheel, 100, 16, 0, 40);
        wait(50);
        compare(sliderWheel.value, 0.5, "a third of a notch already moved the value");
        mouseWheel(sliderWheel, 100, 16, 0, 40);
        wait(50);
        compare(sliderWheel.value, 0.5, "two thirds of a notch already moved the value");
        mouseWheel(sliderWheel, 100, 16, 0, 40);
        wait(50);
        fuzzyCompare(sliderWheel.value, 0.5 + probe.keyStep, 0.0001,
            "three 40-unit events did not add up to one notch");

        mouseWheel(sliderWheel, 100, 16, 0, -40);
        wait(50);
        mouseWheel(sliderWheel, 100, 16, 0, -40);
        wait(50);
        compare(sliderWheel.value, 0.5 + probe.keyStep,
            "two reversed thirds moved the value before the notch completed");
        mouseWheel(sliderWheel, 100, 16, 0, -40);
        wait(50);
        fuzzyCompare(sliderWheel.value, 0.5, 0.0001,
            "three reversed events did not add up to one notch the other way");
    }

    function test_a_wheel_notch_stays_clamped_at_the_upper_bound() {
        sliderWheel.value = 0.98;
        mouseMove(sliderWheel, 100, 16);

        mouseWheel(sliderWheel, 100, 16, 0, 120);
        wait(50);
        verify(sliderWheel.value === sliderWheel.to,
            "a wheel notch that overshoots the top did not clamp exactly to `to`");
    }

    function test_wheelUnits_zero_means_the_wheel_is_off() {
        sliderH.value = 0.5;
        mouseMove(sliderH, 100, 16);

        mouseWheel(sliderH, 100, 16, 0, 120);
        wait(50);
        compare(sliderH.value, 0.5, "a slider with wheelUnits 0 still answered the wheel");
    }

    // The wheel is taken by a `MouseArea` that fills the control, so a wheel
    // the slider cannot use must be handed BACK rather than swallowed: an
    // area that keeps an event it did nothing with silently disables the
    // scrolling of whatever encloses it. The enclosing area below is the
    // scroller, and it only ever hears what the slider declined.
    property int scrollerNotches: 0
    Item {
        id: scroller
        x: 20; y: 560; width: 60; height: 120

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: probe.scrollerNotches++
        }

        Slider {
            id: sliderInScroller
            anchors.fill: parent
            orientation: Qt.Vertical
            value: 0.5
            wheelUnits: Style.sliderKeyboardUnits
        }
    }

    function test_a_wheel_the_slider_cannot_use_reaches_the_enclosing_scroller() {
        probe.scrollerNotches = 0;
        sliderInScroller.value = 0.5;
        mouseMove(sliderInScroller, 10, 60);

        mouseWheel(sliderInScroller, 10, 60, 0, 120);
        wait(50);
        fuzzyCompare(sliderInScroller.value, 0.5 + probe.keyStep, 0.0001,
            "the vertical slider did not take an on-axis notch");
        compare(probe.scrollerNotches, 0,
            "the slider used a notch AND passed it on, so the scroller scrolled too");

        mouseWheel(sliderInScroller, 10, 60, 120, 0);
        wait(50);
        fuzzyCompare(sliderInScroller.value, 0.5 + probe.keyStep, 0.0001,
            "a horizontal wheel moved a VERTICAL slider");
        compare(probe.scrollerNotches, 1,
            "an off-axis wheel was swallowed -- the slider did nothing with it and the "
            + "enclosing scroller never saw it either");
    }

    // Everything here is read DURING the drag on purpose: a gesture switches
    // the painted position's animation off, so the handle is where the value
    // says it is in the same turn as the move. The bounds are compared
    // against the contentItem's own rectangle rather than against the padding
    // arithmetic, so the assertion says "flush with the end of the track"
    // rather than restating the formula that put it there.
    function test_vertical_orientation_grows_upward_not_downward() {
        sliderVert.value = 0.5;
        const content = sliderVert.contentItem;
        const thumb = sliderVert.second.handle;

        mousePress(sliderVert, 16, 180);
        const nearBottom = sliderVert.value;
        const yNearBottom = thumb.y;
        mouseMove(sliderVert, 16, 20);
        const nearTop = sliderVert.value;
        const yNearTop = thumb.y;

        verify(nearTop > nearBottom,
            "moving the pointer toward the TOP of a vertical slider did not increase value -- the axis is upside down");
        verify(yNearTop < yNearBottom,
            "value rose but the thumb did not travel UP the track -- the handle is following `position` "
            + "instead of `visualPosition`, which Qt already inverts for a vertical slider");

        mouseMove(sliderVert, 16, 250);
        verify(sliderVert.value === sliderVert.from, "dragging past the bottom did not clamp to `from`");
        verify(Math.abs((thumb.y + thumb.height) - (content.y + content.height)) < 0.5,
            "at `from` the thumb is not flush with the BOTTOM of the track -- it is off by "
            + ((thumb.y + thumb.height) - (content.y + content.height)) + "px");

        mouseMove(sliderVert, 16, -50);
        verify(sliderVert.value === sliderVert.to, "dragging past the top did not clamp to `to`");
        verify(Math.abs(thumb.y - content.y) < 0.5,
            "at `to` the thumb is not flush with the TOP of the track -- it is off by "
            + (thumb.y - content.y) + "px");

        mouseRelease(sliderVert, 16, -50);
    }

    // The fill ends at the thumb's CENTRE and is pinned to the low end, which
    // on a vertical slider is the bottom. Read mid-drag for the same reason
    // as above.
    function test_the_vertical_fill_runs_from_the_bottom_to_the_thumb_centre() {
        sliderVert.value = 0.5;
        const content = sliderVert.contentItem;
        const thumb = sliderVert.second.handle;
        const fill = findChild(sliderVert, "sliderFill");
        verify(fill !== null, "the fill lost its objectName");

        mousePress(sliderVert, 16, 60);
        const fillTop = fill.mapToItem(sliderVert, 0, 0).y;
        const thumbCentre = thumb.y + thumb.height / 2;

        verify(Math.abs(fillTop - thumbCentre) < 0.5,
            "the fill does not start at the thumb's centre -- it is off by " + (fillTop - thumbCentre) + "px");
        verify(Math.abs((fillTop + fill.height) - (content.y + content.height)) < 0.5,
            "the fill does not reach the BOTTOM of the track -- a vertical fill that grows downward "
            + "is the axis upside down");

        mouseRelease(sliderVert, 16, 60);
    }

    // A flip has to land where a slider BUILT that way already sits, which is
    // an oracle the geometry formula does not get to write. Qt recomputes
    // `visualPosition` for the new axis but emits no change signal for an
    // orientation flip, so a binding that names only `visualPosition` keeps
    // painting the old axis: measured, a slider flipped to vertical at value
    // .82 put its thumb at 0.82 of the travel from the TOP, which is .18 of
    // the value, at the wrong end of the track.
    function test_a_runtime_orientation_flip_repaints_the_thumb_at_the_value() {
        compare(sliderFlip.vertical, false, "the flip case did not start out horizontal");

        sliderVert.value = 0.82;
        sliderFlip.orientation = Qt.Vertical;
        verify(sliderFlip.vertical, "the flip did not reach the control");

        const content = sliderFlip.contentItem;
        const thumb = sliderFlip.second.handle;
        const fill = findChild(sliderFlip, "sliderFill");
        const builtThumb = sliderVert.second.handle;
        const builtFill = findChild(sliderVert, "sliderFill");
        verify(fill !== null && builtFill !== null, "a fill lost its objectName");

        // Both eased: a flip and a written value are host changes, not
        // gestures, so the settle is waited out rather than asserted away.
        tryVerify(() => Math.abs(thumb.y - builtThumb.y) < 0.5, 1000,
            "a slider flipped to vertical does not put its thumb where one built vertical does");
        verify(Math.abs(fill.height - builtFill.height) < 0.5,
            "the flipped fill is not the height the built-vertical one has -- off by "
            + (fill.height - builtFill.height) + "px");

        sliderFlip.value = sliderFlip.to;
        tryVerify(() => Math.abs(thumb.y - content.y) < 0.5, 1000,
            "at `to` the flipped slider's thumb is not flush with the TOP of its track");

        sliderFlip.value = sliderFlip.from;
        tryVerify(() => Math.abs((thumb.y + thumb.height) - (content.y + content.height)) < 0.5, 1000,
            "at `from` the flipped slider's thumb is not flush with the BOTTOM of its track");
    }

    // Paint order, which no tree walk can report: both the track and the fill
    // are children of the contentItem, and QQuickSlider completes its handle
    // BEFORE QQuickControl completes the contentItem, so the handle is the
    // earlier sibling however the two are declared. At equal z the track
    // painted over the thumb and the accent fill drew a line through it.
    function test_the_thumb_paints_above_the_track_and_the_fill() {
        verify(sliderH.second.handle.z > sliderH.contentItem.z,
            "the handle does not sit above the contentItem -- the track and the fill paint over the thumb");
        verify(sliderVert.second.handle.z > sliderVert.contentItem.z,
            "the vertical handle does not sit above the contentItem either");
    }

    // A fat track is a call-site property, not a second type, so writing it
    // has to grow the control rather than be clipped by it.
    function test_a_thick_track_grows_the_control_and_keeps_the_thumb_centred() {
        const shapes = [
            { thickness: Style.controlHeightSm, thumb: Style.controlHeightSm },
            { thickness: Style.controlHeight, thumb: Style.controlHeight },
            { thickness: Style.controlHeight, thumb: Style.controlHeightSm }
        ];

        for (let i = 0; i < shapes.length; i++) {
            const shape = shapes[i];
            sliderFat.thickness = shape.thickness;
            sliderFat.thumbSize = shape.thumb;

            // The thumb GROWS by `space1` per side on hover, and a growth the
            // control does not reserve is a growth that paints outside it.
            const expected = Math.max(
                Style.controlHeightSm, shape.thickness, shape.thumb + Style.space1 * 2);
            compare(sliderFat.implicitHeight, expected,
                "the cross axis is not the largest of controlHeightSm, thickness and the "
                + "thumb plus the room its hover growth needs");
            compare(sliderFat.height, expected,
                "the control did not take the cross size it asked for");

            const content = sliderFat.contentItem;
            const thumb = sliderFat.second.handle;
            verify(Math.abs((thumb.y + thumb.height / 2) - (content.y + content.height / 2)) < 0.5,
                "the thumb is not centred across a " + shape.thickness + "px track");
            verify(thumb.y >= -0.5 && thumb.y + thumb.height <= sliderFat.height + 0.5,
                "the thumb hangs outside the control's own bounds at thickness " + shape.thickness);
        }
    }

    // A raised thumb casts a shadow that drops further while pressed, and the
    // control has to be big enough to hold it: a caller sizing a row to a
    // slider otherwise gets a smudge over whatever sits under it.
    //
    // The shadow drops along `y` in BOTH orientations -- it is gravity, not
    // the axis -- so on a horizontal slider the slack it needs is cross-axis
    // and on a vertical one it is MAIN-axis. Measured, the vertical case
    // spent its slack on the width and painted 2px (4px pressed) below the
    // control's own bottom edge at the low bound, which is where the thumb is
    // flush with the end of the track and there is nothing left to give.
    function test_a_raised_thumb_keeps_its_shadow_inside_the_control() {
        const cases = [
            { slider: sliderFat, horizontal: true },
            { slider: sliderVertRaised, horizontal: false }
        ];

        sliderFat.raised = true;
        sliderFat.thickness = Style.controlHeight;
        sliderFat.thumbSize = Style.controlHeight;

        for (let i = 0; i < cases.length; i++) {
            const slider = cases[i].slider;
            const label = cases[i].horizontal ? "horizontal" : "vertical";
            const shadow = findChild(slider, "sliderThumbShadow");
            verify(shadow !== null, label + ": the thumb shadow lost its objectName");

            // The low bound, where the thumb has travelled as far as it can
            // and no padding is left between it and the end of the control.
            slider.toMinimum();
            const x = slider.width / 2;
            const y = cases[i].horizontal ? slider.height / 2 : slider.height - 2;

            mouseMove(slider, x, y);
            let rect = shadow.mapToItem(slider, 0, 0);
            verify(rect.y + shadow.height <= slider.height + 0.5,
                label + ": a hovered raised thumb's shadow paints "
                + (rect.y + shadow.height - slider.height) + "px below the control's bottom edge");
            verify(rect.x >= -0.5 && rect.x + shadow.width <= slider.width + 0.5,
                label + ": the shadow paints outside the control across the axis");

            mousePress(slider, x, y);
            wait(Motion.press * 3);
            rect = shadow.mapToItem(slider, 0, 0);
            const overflow = rect.y + shadow.height - slider.height;
            mouseRelease(slider, x, y);

            verify(overflow <= 0.5,
                label + ": a pressed raised thumb's shadow paints " + overflow
                + "px below the control's own bottom edge");
            mouseMove(probe, 5, 5);
        }

        sliderFat.raised = false;
    }

    // The three size presets, one for each shape a call site asks for. They
    // are only the DEFAULT: `thickness` and `thumbSize` stay the primary API,
    // and a host that states one keeps it through a later size change --
    // otherwise a preset would silently take back a decision the call site
    // made on purpose.
    function test_size_presets_resolve_the_track_and_thumb_scale() {
        compare(sliderFresh.size, "md", "the default size is not md");
        compare(sliderFresh.thickness, Style.rhythm(Style.size("Slider", "md") * 2 / 3), "the md preset did not reach thickness");
        compare(sliderFresh.thumbSize, Style.size("Slider", "md"), "the md preset did not reach thumbSize");

        const shapes = [
            { size: "sm", thickness: Style.space1, thumb: Style.size("Slider", "sm") },
            { size: "md", thickness: Style.rhythm(Style.size("Slider", "md") * 2 / 3), thumb: Style.size("Slider", "md") },
            { size: "lg", thickness: Style.rhythm(Style.size("Slider", "lg") * 2 / 3), thumb: Style.size("Slider", "lg") }
        ];

        for (let i = 0; i < shapes.length; i++) {
            sliderSize.size = shapes[i].size;
            compare(sliderSize.thickness, shapes[i].thickness,
                "size " + shapes[i].size + " did not resolve its track thickness");
            compare(sliderSize.thumbSize, shapes[i].thumb,
                "size " + shapes[i].size + " did not resolve its thumb size");
        }

        sliderSize.thumbSize = Style.controlHeight;
        sliderSize.size = "sm";
        compare(sliderSize.thumbSize, Style.controlHeight,
            "a size change took back an explicit thumbSize -- the preset is the default, "
            + "not an override of the call site");
        compare(sliderSize.thickness, Style.space1,
            "the size preset stopped reaching thickness once thumbSize was stated");

        sliderSize.size = "md";
    }

    // One thumb colour, in every state. A raised thumb at rest used to paint
    // DARKER than its own fill (measured 1.06:1), so its fill-side half had
    // no edge at all -- and the property's own rule is that the thumb is the
    // lightest thing on the surface, which is what makes it read as raised
    // out of the track rather than as a hole cut into it.
    function test_the_raised_thumb_at_rest_is_the_same_colour_as_an_active_one() {
        mouseMove(probe, 5, 5);
        const thumb = findChild(sliderVertRaised, "sliderThumb");
        verify(thumb !== null, "the thumb lost its objectName");

        compare(sliderVertRaised.raised, true, "the raised case is not raised");
        compare(sliderVertRaised.hovered, false, "the raised case was still hovered at rest");
        tryCompare(thumb, "color", Style.text, 500,
            "a raised thumb at rest is not the library's thumb colour -- it is darker than "
            + "the fill it sits on and loses its edge");

        mouseMove(sliderVertRaised, sliderVertRaised.width / 2, sliderVertRaised.height / 2);
        compare(sliderVertRaised.hovered, true, "the pointer never reached the raised case");
        tryCompare(thumb, "color", Style.text, 500, "the active thumb changed colour");
        mouseMove(probe, 5, 5);
    }

    // Hover and press, at a size a person can see. `StateLayer`'s 1.08/0.94
    // scale is 0.96px of diameter on a 12px thumb, which is an answer nobody
    // can see, and the 6% press SHRINK contradicted the shadow saying the
    // thumb had just risen. So the thumb grows by a fixed `space1` per side,
    // and the press cue is the lift doubling with the growth kept.
    function test_hover_grows_the_thumb_and_press_lifts_it_without_shrinking() {
        mouseMove(probe, 5, 5);
        const thumb = findChild(sliderHover, "sliderThumb");
        const shadow = findChild(sliderHover, "sliderThumbShadow");
        verify(thumb !== null && shadow !== null, "a painted part lost its objectName");

        const rest = sliderHover.thumbSize;
        const grown = rest + Style.space1 * 2;
        tryCompare(thumb, "width", rest, 500, "the resting thumb is not its own thumbSize");
        tryVerify(() => Math.abs((shadow.y - thumb.y) - Style.sliderThumbLift) < 0.5, 500,
            "the resting shadow does not sit one lift below the thumb");

        const midway = sliderHover.width / 2;
        const across = sliderHover.height / 2;
        mouseMove(sliderHover, midway, across);
        compare(sliderHover.hovered, true, "the pointer never arrived");
        tryCompare(thumb, "width", grown, 500,
            "hover did not grow the thumb by space1 per side");
        tryCompare(thumb, "height", grown, 500, "the grown thumb is not still a circle");
        tryVerify(() => Math.abs((shadow.y - thumb.y) - Style.sliderThumbLift) < 0.5, 500,
            "hover changed the lift, which is the press cue");

        mousePress(sliderHover, midway, across);
        tryVerify(() => Math.abs((shadow.y - thumb.y) - Style.sliderThumbLift * 2) < 0.5, 500,
            "the press did not double the lift");
        compare(thumb.width, grown,
            "the press SHRANK the thumb while its shadow said it had risen -- two press cues "
            + "that contradict each other");

        // A drag that leaves the control keeps the press, so it has to keep
        // the growth: a thumb that shrinks mid-gesture is the control letting
        // go under the finger holding it.
        mouseMove(sliderHover, midway, across - 200);
        compare(thumb.width, grown, "the thumb shrank when the pointer left mid-drag");
        mouseRelease(sliderHover, midway, across - 200);

        mouseMove(probe, 5, 5);
        tryCompare(thumb, "width", rest, 500, "the thumb never came back down");
    }

    // `committedValue` is the last value a GESTURE left behind, which is what
    // a host that only writes on commit needs to compare against. It never
    // moves mid-drag, and a direct write to `value` is not a gesture.
    function test_committedValue_holds_the_last_value_a_gesture_left() {
        compare(sliderFresh.committedValue, sliderFresh.value,
            "committedValue did not start at the value the slider completed with");

        sliderH.value = 0.5;
        const preDrag = sliderH.committedValue;

        mousePress(sliderH, 40, 16);
        mouseMove(sliderH, 190, 16);
        verify(sliderH.value !== preDrag, "the drag did not change the value, so it proves nothing");
        compare(sliderH.committedValue, preDrag,
            "committedValue moved mid-drag -- it is tracking `value` rather than the end of a gesture");

        mouseRelease(sliderH, 190, 16);
        compare(sliderH.committedValue, sliderH.value,
            "a released drag did not leave committedValue on the value it ended at");
    }

    // The pointer route (Qt's own press grab), the wheel area, the key
    // dispatcher and hover all go inert together on a disabled slider --
    // confirmed by running this, not assumed.
    function test_disabled_ignores_pointer_wheel_and_keyboard_and_reports_no_hover() {
        sliderDisabled.value = 0.5;
        movedSpyDisabled.clear();

        mouseMove(sliderDisabled, 100, 16);
        compare(sliderDisabled.hovered, false,
            "hovered still reports true on a disabled slider");

        mousePress(sliderDisabled, 30, 16);
        mouseMove(sliderDisabled, 170, 16);
        mouseRelease(sliderDisabled, 170, 16);
        compare(sliderDisabled.value, 0.5, "dragging a disabled slider changed its value");

        mouseWheel(sliderDisabled, 100, 16, 0, 120);
        wait(50);
        compare(sliderDisabled.value, 0.5, "scrolling a disabled slider changed its value");

        sliderDisabled.forceActiveFocus();
        compare(sliderDisabled.activeFocus, false, "a disabled slider took keyboard focus");
        keyClick(Qt.Key_Right);
        compare(sliderDisabled.value, 0.5, "a keyboard step changed a disabled slider's value");
        compare(sliderDisabled.stepBy(Style.sliderKeyboardUnits), false,
            "stepBy reported a change on a disabled slider");

        compare(movedSpyDisabled.count, 0,
            "a disabled slider emitted moved from a route that should be inert");
    }

    // Disabled dims by COLOUR, never by opacity on a composite: `opacity` on
    // the control applies to each child separately, so a translucent thumb
    // shows the translucent fill straight through it. Every layer blends
    // toward the background instead and stays opaque, which is what keeps the
    // layers layers.
    function test_disabled_dims_by_colour_and_leaves_the_control_opaque() {
        compare(sliderDisabled.opacity, 1,
            "a disabled slider dimmed itself with `opacity`, so its thumb is translucent "
            + "and the fill shows through it");

        const track = findChild(sliderDisabled, "sliderTrack");
        const fill = findChild(sliderDisabled, "sliderFill");
        const thumb = findChild(sliderDisabled, "sliderThumb");
        verify(track !== null && fill !== null && thumb !== null, "a painted part lost its objectName");

        tryCompare(thumb, "color", Style.disabled(Style.text), 500,
            "a disabled thumb is not its rest colour blended toward the background");
        compare(track.color, Style.disabled(Style.outline),
            "a disabled track is not its rest colour blended toward the background");
        compare(fill.color, Style.disabled(Style.accent),
            "a disabled fill is not its rest colour blended toward the background");
        compare(thumb.color.a, 1, "the dimmed thumb is translucent rather than dimmed");

        // A literal, and the one place one is right: comparing against
        // `Style.disabled` alone passes even if the blend is wrong, as long
        // as both sides are wrong the same way. Deep-night's background is
        // #1c0e27 and `opacityDisabled` is 0.35, so retuning either moves
        // this number and the message says which.
        compare(String(Style.disabled(Style.text)), "#685d71",
            "the disabled blend of Style.text is not the measured deep-night value -- either "
            + "the arithmetic changed or the theme's background / opacityDisabled did");
    }

    // Qt's own Slider handles the four arrows with `stepSize` as its step, so
    // every arrow branch in the dispatcher accepts the event. If it did not,
    // both routes would run and one press would move SIX units, not five --
    // which is what the exact comparison below catches.
    function test_arrow_keys_move_by_the_keyboard_units_on_the_slider_axis_only() {
        sliderKeyboard.forceActiveFocus();
        sliderKeyboard.value = 0.5;

        keyClick(Qt.Key_Right);
        fuzzyCompare(sliderKeyboard.value, 0.5 + probe.keyStep, 0.0001,
            "Right did not move a horizontal slider by exactly the keyboard units -- "
            + "one unit too many means Qt's own arrow handler ran as well");
        keyClick(Qt.Key_Left);
        fuzzyCompare(sliderKeyboard.value, 0.5, 0.0001,
            "Left did not undo the Right step on a horizontal slider");

        keyClick(Qt.Key_Up);
        fuzzyCompare(sliderKeyboard.value, 0.5, 0.0001,
            "Up moved a HORIZONTAL slider -- the off-axis arrows belong to the surface");
        keyClick(Qt.Key_Down);
        fuzzyCompare(sliderKeyboard.value, 0.5, 0.0001,
            "Down moved a HORIZONTAL slider -- the off-axis arrows belong to the surface");

        sliderVert.forceActiveFocus();
        sliderVert.value = 0.5;

        keyClick(Qt.Key_Up);
        fuzzyCompare(sliderVert.value, 0.5 + probe.keyStep, 0.0001,
            "Up did not INCREASE a vertical slider -- this is the case that silently gets built upside down");
        keyClick(Qt.Key_Down);
        fuzzyCompare(sliderVert.value, 0.5, 0.0001,
            "Down did not undo the Up step on a vertical slider");

        keyClick(Qt.Key_Right);
        fuzzyCompare(sliderVert.value, 0.5, 0.0001,
            "Right moved a VERTICAL slider -- the off-axis arrows belong to the surface");
        keyClick(Qt.Key_Left);
        fuzzyCompare(sliderVert.value, 0.5, 0.0001,
            "Left moved a VERTICAL slider -- the off-axis arrows belong to the surface");
    }

    // Under mirroring the arrows follow the VISUAL axis, which Qt's
    // `mirrored` reports and `visualPosition` already flips.
    function test_under_mirroring_the_arrow_that_increases_swaps_ends() {
        compare(sliderRtl.mirrored, true, "LayoutMirroring did not reach the control");

        sliderRtl.forceActiveFocus();
        sliderRtl.value = 0.5;

        keyClick(Qt.Key_Left);
        fuzzyCompare(sliderRtl.value, 0.5 + probe.keyStep, 0.0001,
            "under mirroring Left did not increase -- the arrows did not follow the visual axis");
        keyClick(Qt.Key_Right);
        fuzzyCompare(sliderRtl.value, 0.5, 0.0001,
            "under mirroring Right did not decrease");
    }

    // Page, Home and End are ours entirely: Qt's Slider has no handler for
    // any of them, on either type.
    function test_page_keys_move_by_the_larger_step_and_home_end_reach_the_bounds_exactly() {
        sliderKeyboard.forceActiveFocus();
        sliderKeyboard.value = 0.5;

        keyClick(Qt.Key_PageUp);
        fuzzyCompare(sliderKeyboard.value, 0.5 + probe.pageStep, 0.0001,
            "PageUp did not move by the larger page step");
        keyClick(Qt.Key_PageDown);
        fuzzyCompare(sliderKeyboard.value, 0.5, 0.0001,
            "PageDown did not undo the PageUp step");

        keyClick(Qt.Key_Home);
        verify(sliderKeyboard.value === sliderKeyboard.from,
            "Home did not reach the lower bound exactly -- a step count that rounds the drift away leaves it at 1e-16");
        keyClick(Qt.Key_End);
        verify(sliderKeyboard.value === sliderKeyboard.to, "End did not reach the upper bound exactly");
    }

    function test_keyboard_route_is_clamped_at_both_ends_like_the_pointer_and_wheel() {
        sliderKeyboard.forceActiveFocus();

        sliderKeyboard.value = 0.98;
        keyClick(Qt.Key_PageUp);
        verify(sliderKeyboard.value === sliderKeyboard.to,
            "a page step that overshoots the top did not clamp exactly to `to`");

        sliderKeyboard.value = 0.02;
        keyClick(Qt.Key_PageDown);
        verify(sliderKeyboard.value === sliderKeyboard.from,
            "a page step that overshoots the bottom did not clamp exactly to `from`");
    }

    // Qt's `moved()` carries no argument by design: it says a gesture changed
    // the value, and the host reads `value`. One press is one `moved`, however
    // many units it walked.
    function test_keyboard_emits_the_same_signal_a_drag_emits() {
        sliderKeyboard.forceActiveFocus();
        sliderKeyboard.value = 0.5;
        movedSpyKeyboard.clear();

        keyClick(Qt.Key_Right);

        compare(movedSpyKeyboard.count, 1, "a keyboard step did not fire moved exactly once");
        compare(movedSpyKeyboard.signalArguments[0].length, 0,
            "moved carried an argument -- the Qt signature has none and every host reads `value`");
        fuzzyCompare(sliderKeyboard.value, 0.5 + probe.keyStep, 0.0001,
            "moved fired but the value it announces did not change");
    }

    // `committed` is the END of a gesture: a release that changed something, a
    // key release that changed something, and each wheel notch that changed
    // something, because a notch has no release to wait for.
    function test_committed_fires_once_at_the_end_of_a_pointer_gesture() {
        sliderH.value = 0.5;
        committedSpyH.clear();

        mousePress(sliderH, 40, 16);
        mouseMove(sliderH, 90, 16);
        mouseMove(sliderH, 140, 16);
        compare(committedSpyH.count, 0, "committed fired mid-drag");
        mouseRelease(sliderH, 140, 16);
        compare(committedSpyH.count, 1, "a drag that changed the value did not commit on release");

        committedSpyH.clear();
        mousePress(sliderH, 140, 16);
        mouseRelease(sliderH, 140, 16);
        compare(committedSpyH.count, 0, "a press that changed nothing still committed");

        // A click on the track is a whole gesture with no move in it. Qt jumps
        // the value on PRESS, so the pre-jump value has to be captured before
        // that -- a commit that read it afterwards would see no change here.
        committedSpyH.clear();
        sliderH.value = 0.5;
        mousePress(sliderH, 40, 16);
        const jumped = sliderH.value;
        verify(jumped < 0.5,
            "a press on the track left of the thumb did not jump the value down to the pointer");
        mouseRelease(sliderH, 40, 16);
        compare(committedSpyH.count, 1,
            "a click on the track jumped the value but never committed");
        compare(sliderH.value, jumped, "the release moved the value after the jump");
    }

    function test_committed_fires_on_key_release_and_once_per_wheel_notch() {
        sliderKeyboard.forceActiveFocus();
        sliderKeyboard.value = 0.5;
        committedSpyKeyboard.clear();

        keyPress(Qt.Key_Right);
        compare(committedSpyKeyboard.count, 0, "a key committed while it was still held");
        keyRelease(Qt.Key_Right);
        compare(committedSpyKeyboard.count, 1, "a key that moved the value did not commit on release");

        committedSpyKeyboard.clear();
        sliderKeyboard.value = sliderKeyboard.to;
        keyClick(Qt.Key_Right);
        compare(committedSpyKeyboard.count, 0, "a key that moved nothing still committed");

        sliderWheel.value = 0.5;
        committedSpyWheel.clear();
        mouseMove(sliderWheel, 100, 16);
        mouseWheel(sliderWheel, 100, 16, 0, 120);
        wait(50);
        compare(committedSpyWheel.count, 1, "one wheel notch did not commit exactly once");
    }

    // The action list is the API a consumer's action menu renders, and each
    // entry must be the SAME route the keyboard takes.
    function test_actions_are_the_same_route_as_the_keys() {
        const names = [];
        for (let i = 0; i < sliderKeyboard.actions.length; i++)
            names.push(sliderKeyboard.actions[i].text);
        compare(names, ["Increase", "Decrease", "Minimum", "Maximum"], "action list changed shape");

        sliderKeyboard.value = 0.5;
        sliderKeyboard.actions[0].trigger();
        const afterAction = sliderKeyboard.value;
        fuzzyCompare(afterAction, 0.5 + probe.keyStep, 0.0001,
            "the Increase action did not step by the keyboard units");

        sliderKeyboard.value = 0.5;
        sliderKeyboard.forceActiveFocus();
        keyClick(Qt.Key_Right);
        fuzzyCompare(sliderKeyboard.value, afterAction, 0.0001,
            "Right and the Increase action are not one route");

        sliderKeyboard.actions[1].trigger();
        fuzzyCompare(sliderKeyboard.value, 0.5, 0.0001, "the Decrease action did not undo it");

        sliderKeyboard.actions[3].trigger();
        verify(sliderKeyboard.value === sliderKeyboard.to,
            "the Maximum action did not reach the upper bound exactly");
        sliderKeyboard.actions[2].trigger();
        verify(sliderKeyboard.value === sliderKeyboard.from,
            "the Minimum action did not reach the lower bound exactly");
    }

    // Half a step lands on the next unit, and the DIRECTION must not decide
    // whether it lands at all. `Math.round(-0.5)` is `-0`, which `stepBy`
    // reads as no work, so half a step down was a silent no-op while half a
    // step up moved. 0.01 -> 0.005 is the case where the halving is exact in
    // binary, which is what it takes to reach the asymmetry at this stepSize.
    function test_moveTo_takes_a_half_step_in_either_direction() {
        sliderKeyboard.value = 0;
        verify(sliderKeyboard.moveTo(Style.sliderStep / 2),
            "half a step UP reported no change");
        fuzzyCompare(sliderKeyboard.value, Style.sliderStep, 0.0001,
            "half a step up did not land on the next unit");

        verify(sliderKeyboard.moveTo(Style.sliderStep / 2),
            "half a step DOWN reported no change -- Math.round(-0.5) is -0, which reads as no work");
        verify(sliderKeyboard.value === sliderKeyboard.from,
            "half a step down did not land on the previous unit");
    }

    // The reason no route assigns `value` from JavaScript: a JS write severs
    // the host's binding, and then a service that changes the level from
    // elsewhere stops reaching the control. Qt's C++ setter does not.
    function test_a_step_leaves_the_hosts_binding_installed() {
        probe.hostSource = 0.3;
        verify(sliderBound.stepBy(Style.sliderKeyboardUnits), "stepBy reported no change");
        fuzzyCompare(sliderBound.value, 0.3 + probe.keyStep, 0.0001,
            "stepBy did not move a slider whose value is bound");

        probe.hostSource = 0.7;
        fuzzyCompare(sliderBound.value, 0.7, 0.0001,
            "the host's binding no longer reaches the control -- a route wrote `value` from JavaScript");
    }

    // A gesture never animates; a host change does. `_hostDriven` is the one
    // fact the Behavior hangs off, so it is what the test reads.
    function test_a_gesture_does_not_animate_and_the_arm_comes_back() {
        sliderKeyboard.value = 0.5;

        verify(sliderKeyboard.stepBy(1), "stepBy(1) reported no change");
        compare(sliderKeyboard._hostDriven, false,
            "the animation was still armed during a keyboard step");
        tryCompare(sliderKeyboard, "_hostDriven", true, 500);
    }

    function test_tab_reaches_the_slider_and_skips_the_disabled_one() {
        sliderVert.forceActiveFocus();

        keyClick(Qt.Key_Tab);

        compare(sliderKeyboard.activeFocus, true,
            "Tab from sliderVert did not skip the disabled slider and land on the next one");
        // Focus lives on a RangeSlider's handle, so the ring reads the handle.
        compare(findChild(sliderKeyboard, "sliderLayer").focused, true,
            "focus arrived by Tab but the ring's `focused` is false -- the ring would not show");
    }

    function test_programmatic_value_write_does_not_emit_moved() {
        movedSpyProg.clear();

        sliderProg.value = 0.8;

        compare(movedSpyProg.count, 0,
            "writing value directly emitted moved -- `moved` means a GESTURE changed it");
    }

    // One slider, one or two thumbs. With one, the low thumb is parked at
    // `from` with no size, so no press can find it; with two, the fill runs
    // between them and Qt keeps them from crossing.
    function test_range_paints_the_fill_between_two_thumbs_that_never_cross() {
        compare(sliderH.first.handle.width, 0, "a single-thumb slider still has a low thumb a press can hit");

        probe.rangeLow = 0.2;
        sliderRange.value = 0.8;
        const low = sliderRange.first.handle;
        const high = sliderRange.second.handle;
        const fill = findChild(sliderRange, "sliderFill");
        verify(low.visible && low.width > 0, "the range's low thumb is not painted");
        tryVerify(() => Math.abs(fill.mapToItem(sliderRange, 0, 0).x - (low.x + low.width / 2)) < 0.5, 1000,
            "the fill does not start at the low thumb's centre");
        verify(Math.abs(fill.mapToItem(sliderRange, fill.width, 0).x - (high.x + high.width / 2)) < 0.5,
            "the fill does not end at the high thumb's centre");

        // Drag the low thumb past the high one: it stops AT it.
        mousePress(sliderRange, low.x + low.width / 2, 16);
        mouseMove(sliderRange, 199, 16);
        verify(sliderRange.lowValue <= sliderRange.value, "the low thumb crossed the high one");
        compare(sliderRange.lowValue, sliderRange.value, "the low thumb did not reach the high one");
        mouseRelease(sliderRange, 199, 16);

        // The keyboard steps the thumb the pointer grabbed last. Both thumbs
        // sit at the top now, and a low bound that is already 0.2 does not
        // re-evaluate its binding, so both are set at once.
        sliderRange.setValues(0.2, 0.8);
        const before = sliderRange.lowValue;
        verify(sliderRange.stepBy(Style.sliderKeyboardUnits), "the step reported no change");
        fuzzyCompare(sliderRange.lowValue, before + Style.sliderKeyboardUnits * sliderRange.stepSize, 1e-9,
            "a step after grabbing the low thumb did not move the low thumb");
        compare(sliderRange.value, 0.8, "a step meant for the low thumb moved the high one");
    }
}
