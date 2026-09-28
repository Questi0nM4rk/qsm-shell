import QtQuick
import QtTest

import qs.QsmShell.Components

TestCase {
    id: probe
    name: "Segmented"
    width: 500
    height: 120
    visible: true
    when: windowShown

    property int hostIndex: 0

    Segmented {
        id: segmented
        x: 20
        y: 20
        width: 460
        options: ["Overview", { label: "Media", disabled: true }, "Alerts"]
        currentIndex: probe.hostIndex
        onSelected: index => probe.hostIndex = index
    }
    SignalSpy { id: selectedSpy; target: segmented; signalName: "selected" }

    function test_pointer_keyboard_action_share_host_route_and_skip_disabled() {
        selectedSpy.clear();
        probe.hostIndex = 0;
        probe.hostIndex = 2;
        compare(segmented.currentIndex, 2, "host synchronization did not update the selected tab");
        compare(selectedSpy.count, 0, "host synchronization reported user intent");
        probe.hostIndex = 0;

        mouseClick(segmented, 380, 20);
        compare(probe.hostIndex, 2, "pointer did not report the enabled third tab");
        compare(selectedSpy.count, 1, "pointer reported selection more than once");

        segmented.forceActiveFocus();
        keyClick(Qt.Key_Right);
        compare(probe.hostIndex, 0, "Right did not wrap past the disabled tab");
        compare(selectedSpy.count, 2, "keyboard did not use the selected route once");

        segmented.actions[0].trigger();
        compare(probe.hostIndex, 2, "Previous action did not use the same route as arrows");
        compare(selectedSpy.count, 3, "action reported selection more than once");

        segmented.options = [
            { label: "Disabled first", disabled: true },
            "Middle",
            "Enabled last",
            { label: "Disabled last", disabled: true }
        ];
        probe.hostIndex = 2;
        segmented.forceActiveFocus();
        keyClick(Qt.Key_Home);
        compare(probe.hostIndex, 1, "Home stopped at a disabled endpoint");
        keyClick(Qt.Key_End);
        compare(probe.hostIndex, 2, "End stopped at a disabled endpoint");
    }
}
