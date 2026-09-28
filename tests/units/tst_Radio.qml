import QtQuick
import QtTest

import qs.QsmShell.Components

TestCase {
    id: probe

    name: "Radio"
    width: 400
    height: 220
    visible: true
    when: windowShown

    Radio { id: pointerRadio; x: 40; y: 20; onSelectionRequested: checked = true }
    SignalSpy { id: pointerSpy; target: pointerRadio; signalName: "selectionRequested" }

    Radio { id: keyboardRadio; x: 40; y: 60; onSelectionRequested: checked = true }
    SignalSpy { id: keyboardSpy; target: keyboardRadio; signalName: "selectionRequested" }

    Radio { id: disabledRadio; x: 40; y: 100; enabled: false; onSelectionRequested: probe.disabledSelections++ }
    property int disabledSelections: 0

    Radio { id: unwiredRadio; x: 40; y: 140 }
    SignalSpy { id: unwiredSpy; target: unwiredRadio; signalName: "selectionRequested" }

    function init() {
        pointerRadio.checked = false;
        keyboardRadio.checked = false;
        disabledSelections = 0;
        unwiredRadio.checked = false;
        pointerSpy.clear();
        keyboardSpy.clear();
        unwiredSpy.clear();
    }

    function test_pointer_space_return_and_action_share_select_intent() {
        mouseClick(pointerRadio);
        pointerRadio.checked = false;
        pointerRadio.actions[0].trigger();

        keyboardRadio.forceActiveFocus();
        keyClick(Qt.Key_Space);
        keyboardRadio.checked = false;
        keyClick(Qt.Key_Return);

        compare(pointerSpy.count, 2);
        compare(keyboardSpy.count, 2);
        compare(keyboardRadio.checked, true);
    }

    function test_disabled_and_selected_radios_refuse_selection() {
        mouseClick(disabledRadio);
        disabledRadio.select();
        pointerRadio.checked = true;
        mouseClick(pointerRadio);
        pointerRadio.select();

        compare(disabledSelections, 0);
        compare(pointerSpy.count, 0);
        compare(pointerRadio.checked, true);
    }

    function test_unwired_radio_keeps_host_owned_checked_state() {
        mouseClick(unwiredRadio);

        compare(unwiredSpy.count, 1);
        compare(unwiredRadio.checked, false);
    }
}
