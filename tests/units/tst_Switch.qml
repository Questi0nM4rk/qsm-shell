import QtQuick
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style

TestCase {
    id: probe

    name: "Switch"
    width: 400
    height: 280
    visible: true
    when: windowShown

    Switch {
        id: pointerSwitch
        x: 40; y: 20
        onToggleRequested: next => pointerSwitch.checked = next
    }
    SignalSpy { id: pointerSpy; target: pointerSwitch; signalName: "toggleRequested" }

    Switch {
        id: keyboardSwitch
        x: 40; y: 80
        onToggleRequested: next => keyboardSwitch.checked = next
    }
    SignalSpy { id: keyboardSpy; target: keyboardSwitch; signalName: "toggleRequested" }

    Switch {
        id: disabledSwitch
        x: 40; y: 140
        enabled: false
        onToggled: probe.disabledToggles++
    }
    property int disabledToggles: 0

    Switch {
        id: unwiredSwitch
        x: 40; y: 200
    }
    SignalSpy { id: unwiredSpy; target: unwiredSwitch; signalName: "toggleRequested" }

    Switch {
        id: unknownSizeSwitch
        x: 40; y: 260
        size: "not-a-preset"
    }

    function init() {
        pointerSwitch.checked = false;
        keyboardSwitch.checked = false;
        disabledToggles = 0;
        pointerSpy.clear();
        keyboardSpy.clear();
        unwiredSwitch.checked = false;
        unwiredSpy.clear();
    }

    function test_pointer_space_and_return_share_toggled_intent() {
        mouseClick(pointerSwitch);
        compare(pointerSpy.count, 1, "pointer did not emit toggleRequested");
        compare(pointerSwitch.checked, true, "host did not apply pointer intent");

        keyboardSwitch.forceActiveFocus();
        keyClick(Qt.Key_Space);
        keyClick(Qt.Key_Return);

        compare(keyboardSpy.count, 2, "Space and Return did not emit toggleRequested");
        compare(keyboardSwitch.checked, false, "host did not apply both keyboard intents");
    }

    function test_disabled_switch_ignores_pointer_and_keyboard() {
        mouseClick(disabledSwitch);
        disabledSwitch.forceActiveFocus();
        keyClick(Qt.Key_Space);
        keyClick(Qt.Key_Return);

        compare(disabledToggles, 0, "a disabled switch fired a route");
    }

    function test_unwired_switch_keeps_host_owned_checked_value() {
        unwiredSwitch.checked = false;
        mouseClick(unwiredSwitch);

        compare(unwiredSpy.count, 1, "unwired switch did not report intent");
        compare(unwiredSwitch.checked, false, "switch wrote its own host-owned checked state");
    }

    function test_tab_reaches_switch_and_skips_disabled_switch() {
        keyboardSwitch.forceActiveFocus();
        keyClick(Qt.Key_Tab);

        compare(unwiredSwitch.activeFocus, true,
            "Tab did not reach the next enabled switch after the disabled switch");
        compare(disabledSwitch.activeFocus, false, "Tab entered a disabled switch");
    }

    // A typo'd preset name has to render something rather than throw --
    // Style.size falls back to the md preset.
    function test_unknown_size_name_falls_back_to_md_without_throwing() {
        compare(unknownSizeSwitch.knobSize, Style.size("Switch", "md"),
            "an unknown size name did not fall back to the md preset");
    }
}
