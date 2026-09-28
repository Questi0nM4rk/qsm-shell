import QtQuick
import QtTest

import qs.QsmShell.Components

TestCase {
    id: probe

    name: "ActionTile"
    width: 400
    height: 300
    visible: true
    when: windowShown

    ActionTile {
        id: hosted
        x: 40
        y: 30
        icon: "power"
        label: "Power off"
    }
    SignalSpy { id: hostedFired; target: hosted; signalName: "activated" }

    ActionTile {
        id: frozen
        x: 40
        y: 160
        icon: "power"
        label: "Power off"
        enabled: false
    }
    SignalSpy { id: frozenFired; target: frozen; signalName: "activated" }

    function init() {
        hostedFired.clear()
        frozenFired.clear()
    }

    function test_pointer_keyboard_and_programmatic_activation_with_disabled_guard() {
        mouseClick(hosted)
        hosted.forceActiveFocus()
        keyClick(Qt.Key_Space)
        keyClick(Qt.Key_Return)
        keyClick(Qt.Key_Enter)
        hosted.activate()

        compare(hostedFired.count, 5, "ActionTile routes did not share activated")
        compare(hosted.selected, false, "the tile mutated selected without the host asking")
        compare(hosted.armed, false, "the tile mutated armed without the host asking")

        mouseClick(frozen)
        frozen.forceActiveFocus()
        keyClick(Qt.Key_Space)
        keyClick(Qt.Key_Return)
        keyClick(Qt.Key_Enter)
        frozen.activate()

        compare(frozenFired.count, 0, "disabled ActionTile fired activated")
    }
}
