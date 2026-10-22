import QtQuick
import QtTest

import qs.QsmShell.Components

TestCase {
    id: probe

    name: "SpinBox"
    width: 400
    height: 240
    visible: true
    when: windowShown

    SpinBox {
        id: spin
        x: 40
        y: 40
        from: 0
        to: 12
        stepSize: 0.5
        decimals: 1
        value: 4.5
    }
    SignalSpy { id: modifiedSpy; target: spin; signalName: "valueModified" }

    Item {
        id: feedbackHost
        property real value: 42.5
        SpinBox {
            id: feedbackSpin
            from: 0
            to: 100
            stepSize: 0.5
            decimals: 1
            value: feedbackHost.value
            onValueModified: feedbackHost.value = value
        }
    }

    SignalSpy { id: feedbackSpy; target: feedbackSpin; signalName: "valueModified" }

    function init() {
        spin.from = 0;
        spin.to = 12;
        spin.stepSize = 0.5;
        spin.decimals = 1;
        spin.wrap = false;
        spin.enabled = true;
        spin.editable = true;
        spin.value = 4.5;
        modifiedSpy.clear();
        feedbackHost.value = 42.5;
        feedbackSpin.from = 0;
        feedbackSpin.to = 100;
        feedbackSpin.stepSize = 0.5;
        feedbackSpin.decimals = 1;
        feedbackSpin.wrap = false;
        feedbackSpy.clear();
    }

    // One regression check: native pointer stepping, the component's bound
    // key extension and its enumerated action all report through the same
    // valueModified contract.
    function test_native_and_component_routes_share_one_report() {
        mouseClick(spin.up.indicator);
        fuzzyCompare(spin.value, 5, 0.0001, "pointer increase did not move by one step");

        spin.forceActiveFocus();
        // An editable field keeps Home for the caret; with typing off it
        // reaches the bound.
        keyClick(Qt.Key_Home);
        fuzzyCompare(spin.value, 5, 0.0001, "Home moved the value of an editable field");
        spin.editable = false;
        keyClick(Qt.Key_Home);
        fuzzyCompare(spin.value, spin.from, 0.0001, "Home did not reach the minimum");

        spin.actions[0].trigger();
        fuzzyCompare(spin.value, 0.5, 0.0001, "Increase action did not use the native step");
        compare(modifiedSpy.count, 3, "one value-changing route was not reported exactly once");
    }

    function test_host_feedback_uses_component_actions_and_preserves_external_writes() {
        compare(feedbackSpin.value, 42.5);
        verify(feedbackSpin.stepUp());
        compare(feedbackHost.value, 43);
        compare(feedbackSpin.value, feedbackHost.value);
        compare(feedbackSpy.count, 1);

        feedbackHost.value = 17.5;
        compare(feedbackSpin.value, 17.5);
        verify(feedbackSpin.stepDown());
        compare(feedbackHost.value, 17);
        compare(feedbackSpy.count, 2);

        feedbackHost.value = 100;
        feedbackSpy.clear();
        verify(!feedbackSpin.stepUp());
        compare(feedbackSpy.count, 0);
        feedbackSpin.wrap = true;
        verify(feedbackSpin.stepUp());
        compare(feedbackHost.value, 0);
        compare(feedbackSpin.value, feedbackHost.value);
        compare(feedbackSpy.count, 1);
    }

    // A jump to a bound is one native step with wrapping off; stepSize, wrap
    // and the host's binding on value must all come back.
    function test_a_jump_to_a_bound_is_one_step_and_gives_everything_back() {
        feedbackSpin.to = 1000000;
        feedbackSpin.wrap = true;
        verify(feedbackSpin.toMaximum());
        compare(feedbackHost.value, 1000000);
        compare(feedbackSpin.stepSize, 0.5);
        compare(feedbackSpin.wrap, true);
        feedbackHost.value = 3;
        compare(feedbackSpin.value, 3);
        verify(feedbackSpin.toMinimum());
        compare(feedbackHost.value, 0);
        compare(feedbackSpy.count, 2);
    }

    function test_native_input_feedback_reports_once() {
        feedbackHost.value = 42.5;
        feedbackSpy.clear();
        feedbackSpin.forceActiveFocus();
        compare(feedbackSpin.value, 42.5);
        keyClick(Qt.Key_Up);
        compare(feedbackHost.value, 43);
        compare(feedbackSpin.value, feedbackHost.value);
        compare(feedbackSpy.count, 1);
    }
}
