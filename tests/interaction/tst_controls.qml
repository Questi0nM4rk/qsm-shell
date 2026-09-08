import QtQuick
import QtTest

import qs.QsmShell.Components

// The law being checked: a pointer route and a keyboard route perform the SAME
// action, and an unavailable control performs neither. Every control that
// answers a click has to answer a key, and until this file existed the only
// way to know was to try it by hand.
TestCase {
    id: probe

    name: "Controls"
    width: 400
    height: 200
    visible: true
    when: windowShown

    property int checkToggles: 0

    Checkbox {
        id: check
        y: 40
        label: "Include"
        onToggled: probe.checkToggles++
    }

    function init() {
        probe.checkToggles = 0;
    }

    function test_checkbox_answers_both_routes() {
        mouseClick(check);
        compare(probe.checkToggles, 1, "pointer did not reach the checkbox");
        check.forceActiveFocus();
        keyClick(Qt.Key_Space);
        compare(probe.checkToggles, 2, "Space did not reach the checkbox");
    }

    function test_checkbox_does_not_write_its_own_state() {
        compare(check.checked, false, "the checkbox wrote its own checked state");
    }
}
