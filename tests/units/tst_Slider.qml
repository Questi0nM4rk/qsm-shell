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
// of this. `moved()` carries no argument (Qt's signature) and means "a gesture
// changed it"; `committed()` means "the gesture ended".
TestCase {
    id: probe

    name: "Slider"
    width: 400
    height: 400
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
            + sliderH.visualPosition * (sliderH.availableWidth - sliderH.handle.width);
        fuzzyCompare(sliderH.handle.x, expected, 0.5,
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

    function test_vertical_orientation_grows_upward_not_downward() {
        sliderVert.value = 0.5;

        mousePress(sliderVert, 16, 180);
        const nearBottom = sliderVert.value;
        mouseMove(sliderVert, 16, 20);
        const nearTop = sliderVert.value;
        mouseRelease(sliderVert, 16, 20);

        verify(nearTop > nearBottom,
            "moving the pointer toward the TOP of a vertical slider did not increase value -- the axis is upside down");
    }

    // The pointer route (Qt's own press grab), the WheelHandler, the key
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
        compare(sliderKeyboard.visualFocus, true,
            "focus arrived by Tab but visualFocus is false -- the ring StateLayer draws would not show");
    }

    function test_programmatic_value_write_does_not_emit_moved() {
        movedSpyProg.clear();

        sliderProg.value = 0.8;

        compare(movedSpyProg.count, 0,
            "writing value directly emitted moved -- `moved` means a GESTURE changed it");
    }
}
