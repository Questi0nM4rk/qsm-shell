import QtQuick
import QtTest

import qs.QsmShell.Components

TestCase {
    id: probe

    name: "Checkbox"
    width: 400
    height: 200
    visible: true
    when: windowShown

    Checkbox {
        id: pointerCheck
        x: 40; y: 20
        onToggleRequested: next => pointerCheck.checked = next
    }
    SignalSpy { id: pointerSpy; target: pointerCheck; signalName: "toggleRequested" }

    Checkbox {
        id: keyboardCheck
        x: 40; y: 60
        onToggleRequested: next => keyboardCheck.checked = next
    }
    SignalSpy { id: keyboardSpy; target: keyboardCheck; signalName: "toggleRequested" }

    Checkbox {
        id: disabledCheck
        x: 40; y: 100
        enabled: false
        onToggleRequested: probe.disabledToggles++
    }
    property int disabledToggles: 0

    Checkbox {
        id: unwiredCheck
        x: 40; y: 140
    }
    SignalSpy { id: unwiredSpy; target: unwiredCheck; signalName: "toggleRequested" }

    function init() {
        pointerCheck.checked = false;
        pointerCheck.indeterminate = false;
        keyboardCheck.checked = false;
        keyboardCheck.indeterminate = false;
        disabledToggles = 0;
        pointerSpy.clear();
        keyboardSpy.clear();
        unwiredCheck.checked = false;
        unwiredCheck.indeterminate = false;
        unwiredSpy.clear();
    }

    function test_pointer_space_and_return_share_toggle_intent() {
        mouseClick(pointerCheck);
        compare(pointerSpy.count, 1, "pointer did not emit toggleRequested");
        compare(pointerCheck.checked, true, "host did not apply pointer intent");

        keyboardCheck.forceActiveFocus();
        keyClick(Qt.Key_Space);
        keyClick(Qt.Key_Return);

        compare(keyboardSpy.count, 2, "Space and Return did not emit toggleRequested");
        compare(keyboardCheck.checked, false, "host did not apply both keyboard intents");
    }

    function test_disabled_checkbox_ignores_pointer_and_keyboard() {
        mouseClick(disabledCheck);
        disabledCheck.forceActiveFocus();
        keyClick(Qt.Key_Space);
        keyClick(Qt.Key_Return);

        compare(disabledToggles, 0, "a disabled checkbox fired a route");
    }

    function test_unwired_checkbox_keeps_host_owned_states() {
        unwiredCheck.checked = true;
        unwiredCheck.indeterminate = true;
        mouseClick(unwiredCheck);

        compare(unwiredSpy.count, 1, "unwired checkbox did not report intent");
        compare(unwiredCheck.checked, true, "checkbox wrote its own host-owned checked state");
        compare(unwiredCheck.indeterminate, true, "checkbox wrote its own host-owned indeterminate state");
    }
}
