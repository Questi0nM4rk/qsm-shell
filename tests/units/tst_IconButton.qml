import QtQuick
import QtTest

import qs.QsmShell.Components

TestCase {
    id: probe

    name: "IconButton"
    width: 320
    height: 180
    visible: true
    when: windowShown

    IconButton {
        id: button
        x: 40
        y: 40
        icon: "check"
    }
    SignalSpy { id: clicked; target: button; signalName: "clicked" }

    function init() {
        button.enabled = true
        clicked.clear()
    }

    function test_pointer_keyboard_and_programmatic_activation_share_clicked() {
        mouseClick(button)
        button.forceActiveFocus()
        keyClick(Qt.Key_Space)
        keyClick(Qt.Key_Return)
        button.activate()

        compare(clicked.count, 4, "IconButton routes did not share clicked")
    }

    function test_disabled_button_ignores_every_route() {
        button.enabled = false
        mouseClick(button)
        button.forceActiveFocus()
        keyClick(Qt.Key_Space)
        keyClick(Qt.Key_Return)
        button.activate()

        compare(clicked.count, 0, "disabled IconButton fired clicked")
    }
}
