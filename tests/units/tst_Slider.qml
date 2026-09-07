import QtQuick
import QtTest

import qs.QsmShell.Components

// `value` is host-owned: Slider never writes its own value, it only emits
// `moved(value)` and expects whoever holds the control to write it back --
// the same reason a controlled form field works. Every slider below wires
// its own onMoved back into its own value, exactly the way a real host
// would, except `sliderProg` which is deliberately left unwired to prove the
// opposite half of the contract: a write that never went through `moved`.
// Every case drives a REAL pointer, wheel or key event; qmllint cannot see
// any of this.
TestCase {
    id: probe

    name: "Slider"
    width: 400
    height: 400
    visible: true
    when: windowShown

    Slider {
        id: sliderH
        x: 100; y: 20; width: 200; height: 32
        value: 0.5
        onMoved: value => sliderH.value = value
    }
    SignalSpy { id: movedSpyH; target: sliderH; signalName: "moved" }

    Slider {
        id: sliderWheel
        x: 100; y: 90; width: 200; height: 32
        value: 0.5
        wheelStep: 0.1
        onMoved: value => sliderWheel.value = value
    }

    Slider {
        id: sliderVert
        x: 340; y: 60; width: 32; height: 200
        orientation: Qt.Vertical
        value: 0.5
        onMoved: value => sliderVert.value = value
    }

    Slider {
        id: sliderDisabled
        x: 100; y: 160; width: 200; height: 32
        value: 0.5
        wheelStep: 0.1
        enabled: false
        onMoved: value => sliderDisabled.value = value
    }
    SignalSpy { id: movedSpyDisabled; target: sliderDisabled; signalName: "moved" }

    Slider {
        id: sliderKeyboard
        x: 100; y: 210; width: 200; height: 32
        value: 0.5
        onMoved: value => sliderKeyboard.value = value
    }
    SignalSpy { id: movedSpyKeyboard; target: sliderKeyboard; signalName: "moved" }

    // Left unwired on purpose -- see the file header.
    Slider {
        id: sliderProg
        x: 100; y: 260; width: 200; height: 32
        value: 0.5
    }
    SignalSpy { id: movedSpyProg; target: sliderProg; signalName: "moved" }

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
        compare(sliderH.value, 0, "dragging past the left end did not clamp exactly to 0");

        mouseMove(sliderH, 250, 16);
        compare(sliderH.value, 1, "dragging past the right end did not clamp exactly to 1");

        mouseRelease(sliderH, 250, 16);
    }

    function test_wheelStep_moves_value_by_the_step_per_notch_in_the_declared_direction() {
        sliderWheel.value = 0.5;
        mouseMove(sliderWheel, 100, 16);

        mouseWheel(sliderWheel, 100, 16, 0, 120);
        wait(50);
        fuzzyCompare(sliderWheel.value, 0.6, 0.0001,
            "a positive wheel notch did not move value by +wheelStep");

        mouseWheel(sliderWheel, 100, 16, 0, -120);
        wait(50);
        fuzzyCompare(sliderWheel.value, 0.5, 0.0001,
            "a negative wheel notch did not move value by -wheelStep");
    }

    function test_wheelStep_stays_clamped_at_the_upper_bound() {
        sliderWheel.value = 0.95;
        mouseMove(sliderWheel, 100, 16);

        mouseWheel(sliderWheel, 100, 16, 0, 120);
        wait(50);
        compare(sliderWheel.value, 1, "a wheel notch that overshoots the top did not clamp exactly to 1");
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

    // The drag `MouseArea`, the `WheelHandler` and now the keyboard route,
    // and `HoverHandler` (tied to `root.enabled` alongside them), and Tab
    // traversal (`activeFocusOnTab: enabled`) all go inert together on a
    // disabled slider -- confirmed by running this, not assumed.
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
        compare(sliderDisabled.value, 0.5, "scrolling a disabled slider changed its value");

        sliderDisabled.forceActiveFocus();
        compare(sliderDisabled.activeFocus, false, "a disabled slider took keyboard focus");
        keyClick(Qt.Key_Right);
        compare(sliderDisabled.value, 0.5, "a keyboard step changed a disabled slider's value");

        compare(movedSpyDisabled.count, 0, "a disabled slider emitted moved from a route that should be inert");
    }

    // Right and Up both increase, Left and Down both decrease, on EITHER
    // orientation -- there is no orientation branch in the handler. The
    // vertical Up case is the one that silently gets built upside down.
    function test_arrow_keys_move_value_by_one_step_in_the_right_direction_on_both_orientations() {
        sliderH.forceActiveFocus();
        sliderH.value = 0.5;

        keyClick(Qt.Key_Right);
        fuzzyCompare(sliderH.value, 0.5 + sliderH.keyboardStep, 0.0001,
            "Right did not move a horizontal slider up by one step");
        keyClick(Qt.Key_Left);
        fuzzyCompare(sliderH.value, 0.5, 0.0001,
            "Left did not undo the Right step on a horizontal slider");
        keyClick(Qt.Key_Up);
        fuzzyCompare(sliderH.value, 0.5 + sliderH.keyboardStep, 0.0001,
            "Up did not move a horizontal slider up by one step");
        keyClick(Qt.Key_Down);
        fuzzyCompare(sliderH.value, 0.5, 0.0001,
            "Down did not undo the Up step on a horizontal slider");

        sliderVert.forceActiveFocus();
        sliderVert.value = 0.5;

        keyClick(Qt.Key_Up);
        fuzzyCompare(sliderVert.value, 0.5 + sliderVert.keyboardStep, 0.0001,
            "Up did not INCREASE a vertical slider -- this is the case that silently gets built upside down");
        keyClick(Qt.Key_Down);
        fuzzyCompare(sliderVert.value, 0.5, 0.0001,
            "Down did not undo the Up step on a vertical slider");
        keyClick(Qt.Key_Right);
        fuzzyCompare(sliderVert.value, 0.5 + sliderVert.keyboardStep, 0.0001,
            "Right did not move a vertical slider up by one step");
        keyClick(Qt.Key_Left);
        fuzzyCompare(sliderVert.value, 0.5, 0.0001,
            "Left did not undo the Right step on a vertical slider");
    }

    function test_page_keys_move_by_the_larger_step_and_home_end_reach_the_bounds_exactly() {
        sliderKeyboard.forceActiveFocus();
        sliderKeyboard.value = 0.5;

        keyClick(Qt.Key_PageUp);
        fuzzyCompare(sliderKeyboard.value, 0.5 + sliderKeyboard.keyboardPageStep, 0.0001,
            "PageUp did not move by the larger page step");
        keyClick(Qt.Key_PageDown);
        fuzzyCompare(sliderKeyboard.value, 0.5, 0.0001,
            "PageDown did not undo the PageUp step");

        keyClick(Qt.Key_Home);
        compare(sliderKeyboard.value, 0, "Home did not reach the lower bound exactly");
        keyClick(Qt.Key_End);
        compare(sliderKeyboard.value, 1, "End did not reach the upper bound exactly");
    }

    function test_keyboard_route_is_clamped_at_both_ends_like_the_pointer_and_wheel() {
        sliderKeyboard.forceActiveFocus();

        sliderKeyboard.value = 0.98;
        keyClick(Qt.Key_PageUp);
        compare(sliderKeyboard.value, 1, "a page step that overshoots the top did not clamp exactly to 1");

        sliderKeyboard.value = 0.02;
        keyClick(Qt.Key_PageDown);
        compare(sliderKeyboard.value, 0, "a page step that overshoots the bottom did not clamp exactly to 0");
    }

    function test_keyboard_emits_the_same_signal_a_drag_emits() {
        sliderKeyboard.forceActiveFocus();
        sliderKeyboard.value = 0.5;
        movedSpyKeyboard.clear();

        keyClick(Qt.Key_Right);

        compare(movedSpyKeyboard.count, 1, "a keyboard step did not fire moved exactly once");
        fuzzyCompare(movedSpyKeyboard.signalArguments[0][0], 0.5 + sliderKeyboard.keyboardStep, 0.0001,
            "moved's argument did not carry the new value");
    }

    // Tab order follows declaration order: sliderH, sliderWheel, sliderVert,
    // sliderDisabled, sliderKeyboard, sliderProg. `sliderDisabled` sets
    // `activeFocusOnTab: enabled` to false through `enabled: false`, so this
    // proves both "Tab reaches a slider" and "a disabled one is skipped" in
    // one pass.
    function test_tab_reaches_the_slider_and_skips_the_disabled_one() {
        sliderVert.forceActiveFocus();

        keyClick(Qt.Key_Tab);

        compare(sliderKeyboard.activeFocus, true,
            "Tab from sliderVert did not skip the disabled slider and land on the next one");
        compare(sliderKeyboard.focused, true,
            "activeFocus is true but the public `focused` state disagrees");
    }

    function test_programmatic_value_write_does_not_emit_moved() {
        movedSpyProg.clear();

        sliderProg.value = 0.8;

        compare(movedSpyProg.count, 0,
            "writing value directly emitted moved -- value is meant to be host-owned and silent on a direct write");
    }
}
