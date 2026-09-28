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
    }

    // One regression check: native pointer stepping, the component's bound
    // key extension and its enumerated action all report through the same
    // valueModified contract.
    function test_native_and_component_routes_share_one_report() {
        mouseClick(spin.up.indicator);
        fuzzyCompare(spin.value, 5, 0.0001, "pointer increase did not move by one step");

        spin.forceActiveFocus();
        keyClick(Qt.Key_Home);
        fuzzyCompare(spin.value, spin.from, 0.0001, "Home did not reach the minimum");

        spin.actions[0].trigger();
        fuzzyCompare(spin.value, 0.5, 0.0001, "Increase action did not use the native step");
        compare(modifiedSpy.count, 3, "one value-changing route was not reported exactly once");
    }
}
