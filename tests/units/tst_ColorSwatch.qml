import QtQuick
import QtTest

import qs.QsmShell.Components

TestCase {
    id: probe

    name: "ColorSwatch"
    width: 400
    height: 260
    visible: true
    when: windowShown

    ColorSwatch {
        id: hosted
        x: 60
        y: 60
        size: 24
        sample: "#f6f1f9"
        reading: "#F6F1F9"
    }
    SignalSpy { id: hostedClicked; target: hosted; signalName: "clicked" }

    ColorSwatch {
        id: disabled
        x: 220
        y: 60
        size: 24
        sample: "#f6f1f9"
        reading: "#F6F1F9"
        enabled: false
    }
    SignalSpy { id: disabledClicked; target: disabled; signalName: "clicked" }

    function init() {
        hostedClicked.clear()
        disabledClicked.clear()
    }

    function test_pointer_keyboard_and_action_share_one_guarded_route() {
        mouseClick(hosted, hosted.width - 1, hosted.height / 2)
        hosted.forceActiveFocus()
        keyClick(Qt.Key_Space)
        keyClick(Qt.Key_Return)
        hosted.activate()

        compare(hostedClicked.count, 4, "swatch routes did not share clicked")
    }

    function test_disabled_swatch_stays_silent() {
        mouseClick(disabled)
        disabled.forceActiveFocus()
        keyClick(Qt.Key_Space)
        keyClick(Qt.Key_Return)
        disabled.activate()

        compare(disabledClicked.count, 0, "disabled swatch fired clicked")
    }
}
