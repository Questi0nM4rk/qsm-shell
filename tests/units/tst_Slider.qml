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

    // `hovered` keeps reporting true while disabled -- confirmed by running
    // this, not assumed. `HoverHandler` has no tie to `root.enabled` (unlike
    // the drag `MouseArea`, which inherits Item's own enabled-propagation,
    // and the `WheelHandler`, which the run below shows is also inert here).
    // This is pinned down as current fact, not endorsed; see the report.
    function test_disabled_ignores_both_pointer_and_wheel_though_hover_still_reports() {
        sliderDisabled.value = 0.5;
        movedSpyDisabled.clear();

        mouseMove(sliderDisabled, 100, 16);
        compare(sliderDisabled.hovered, true,
            "hovered stopped reporting on a disabled slider -- if this now fails, HoverHandler "
            + "gained an enabled tie to root.enabled; update this test and drop the finding");

        mousePress(sliderDisabled, 30, 16);
        mouseMove(sliderDisabled, 170, 16);
        mouseRelease(sliderDisabled, 170, 16);
        compare(sliderDisabled.value, 0.5, "dragging a disabled slider changed its value");

        mouseWheel(sliderDisabled, 100, 16, 0, 120);
        compare(sliderDisabled.value, 0.5, "scrolling a disabled slider changed its value");

        compare(movedSpyDisabled.count, 0, "a disabled slider emitted moved from a route that should be inert");
    }

    // Slider has no Keys handling and never takes focus today -- confirmed by
    // reading the whole component. This test pins down that current fact so
    // a silent regression (or a silent fix) does not slip past unnoticed; it
    // is not a substitute for the missing route. See the report for the
    // finding this stands in for.
    function test_keyboard_route_does_nothing_today() {
        sliderKeyboard.value = 0.5;
        movedSpyKeyboard.clear();

        sliderKeyboard.forceActiveFocus();
        keyClick(Qt.Key_Right);
        keyClick(Qt.Key_Left);
        keyClick(Qt.Key_Up);
        keyClick(Qt.Key_Down);
        keyClick(Qt.Key_PageUp);
        keyClick(Qt.Key_PageDown);

        compare(sliderKeyboard.value, 0.5,
            "a keyboard route changed value -- Slider gained key handling; update this test and drop the finding");
        compare(movedSpyKeyboard.count, 0,
            "a keyboard route fired moved -- Slider gained key handling; update this test and drop the finding");
    }

    function test_programmatic_value_write_does_not_emit_moved() {
        movedSpyProg.clear();

        sliderProg.value = 0.8;

        compare(movedSpyProg.count, 0,
            "writing value directly emitted moved -- value is meant to be host-owned and silent on a direct write");
    }
}
