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
        segmented.tabNavigation = false;
        segmented.wrapNavigation = true;
        segmented.options = ["Overview", { label: "Media", disabled: true }, "Alerts"];
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

    function test_panel_tab_group_moves_selection_with_tab_and_shift_tab() {
        segmented.options = ["Overview", "Media", "Alerts"];
        segmented.tabNavigation = true;
        segmented.wrapNavigation = false;
        probe.hostIndex = 0;
        segmented.forceActiveFocus();
        selectedSpy.clear();

        keyClick(Qt.Key_Tab);
        compare(probe.hostIndex, 1, "Tab did not select the next tab");
        keyClick(Qt.Key_Tab, Qt.ShiftModifier);
        compare(probe.hostIndex, 0, "Shift+Tab did not select the previous tab");
        keyClick(Qt.Key_Tab, Qt.ShiftModifier);
        compare(probe.hostIndex, 0, "the visible first tab did not stop reverse navigation");
        keyClick(Qt.Key_Tab);
        keyClick(Qt.Key_Tab);
        compare(probe.hostIndex, 2, "the visible last tab did not stop forward navigation");
        compare(segmented.activeFocus, true, "selection left the tab group");
        compare(selectedSpy.count, 4, "Tab reported a different number of selections than the keys sent");

        segmented.options = [{ label: "Unavailable middle", disabled: true }, "Second", "Third"];
        probe.hostIndex = 0;
        selectedSpy.clear();
        keyClick(Qt.Key_Tab);
        compare(probe.hostIndex, 1, "Tab stopped on an unavailable tab");
        compare(selectedSpy.count, 1, "skipping an unavailable tab reported more than one selection");
    }

    function test_tab_navigation_is_opt_in() {
        segmented.options = ["Overview", "Media", "Alerts"];
        segmented.tabNavigation = false;
        segmented.wrapNavigation = true;
        probe.hostIndex = 0;
        segmented.forceActiveFocus();
        selectedSpy.clear();

        keyClick(Qt.Key_Tab);
        compare(probe.hostIndex, 0, "the conventional single tab stop moved the selection");
        compare(selectedSpy.count, 0, "the conventional single tab stop reported intent");
        keyClick(Qt.Key_Right);
        compare(probe.hostIndex, 1, "arrows stopped working with the opt-in route present");
    }
}
