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

    property int switchToggles: 0
    property int checkToggles: 0
    property int deadToggles: 0

    Switch {
        id: toggle
        onToggled: probe.switchToggles++
    }

    Checkbox {
        id: check
        y: 40
        label: "Include"
        onToggled: probe.checkToggles++
    }

    Switch {
        id: dead
        y: 80
        enabled: false
        onToggled: probe.deadToggles++
    }

    function init() {
        probe.switchToggles = 0;
        probe.checkToggles = 0;
        probe.deadToggles = 0;
    }

    function test_switch_answers_both_routes() {
        mouseClick(toggle);
        compare(probe.switchToggles, 1, "pointer did not reach the switch");
        toggle.forceActiveFocus();
        keyClick(Qt.Key_Space);
        compare(probe.switchToggles, 2, "Space did not reach the switch");
        keyClick(Qt.Key_Return);
        compare(probe.switchToggles, 3, "Return did not reach the switch");
    }

    function test_checkbox_answers_both_routes() {
        mouseClick(check);
        compare(probe.checkToggles, 1, "pointer did not reach the checkbox");
        check.forceActiveFocus();
        keyClick(Qt.Key_Space);
        compare(probe.checkToggles, 2, "Space did not reach the checkbox");
    }

    // Unavailable means unavailable on BOTH routes. A control that ignores the
    // pointer and still answers the keyboard is the more dangerous half,
    // because nothing on screen says it is still live.
    function test_disabled_answers_neither() {
        mouseClick(dead);
        dead.forceActiveFocus();
        keyClick(Qt.Key_Space);
        compare(probe.deadToggles, 0, "a disabled switch still fired");
    }

    // The host owns the value: the control reports the intent and never writes
    // its own state, so a setting the system can also change from elsewhere
    // cannot end up disagreeing with the control that shows it.
    function test_controls_do_not_write_their_own_state() {
        compare(toggle.checked, false, "the switch wrote its own checked state");
        compare(check.checked, false, "the checkbox wrote its own checked state");
    }
}
