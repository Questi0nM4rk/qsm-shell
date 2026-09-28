import QtQuick
import QtTest

import qs.QsmShell.Components

TestCase {
    id: probe

    name: "Capsule"
    width: 400
    height: 220
    visible: true
    when: windowShown

    Capsule {
        id: hosted
        x: 40
        y: 30
        icon: "check"
        label: "Hosted"
        onClicked: hosted.active = !hosted.active
    }
    SignalSpy { id: hostedClicked; target: hosted; signalName: "clicked" }

    Capsule {
        id: disabled
        x: 40
        y: 110
        icon: "check"
        label: "Disabled"
        enabled: false
    }
    SignalSpy { id: disabledClicked; target: disabled; signalName: "clicked" }

    function init() {
        hosted.active = false
        hostedClicked.clear()
        disabledClicked.clear()
    }

    function test_pointer_keyboard_and_action_keep_active_host_owned() {
        mouseClick(hosted)
        compare(hosted.active, true, "host did not answer pointer intent")

        hosted.forceActiveFocus()
        keyClick(Qt.Key_Space)
        keyClick(Qt.Key_Return)
        hosted.activate()

        compare(hostedClicked.count, 4, "Capsule routes did not share clicked")
        compare(hosted.active, false, "host did not answer every intent")
    }

    function test_disabled_capsule_ignores_every_route() {
        mouseClick(disabled)
        disabled.forceActiveFocus()
        keyClick(Qt.Key_Space)
        keyClick(Qt.Key_Return)
        disabled.activate()

        compare(disabledClicked.count, 0, "disabled Capsule fired clicked")
    }
}
