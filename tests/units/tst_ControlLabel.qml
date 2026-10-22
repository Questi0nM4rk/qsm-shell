import QtQuick
import QtTest
import QtQuick.Controls
import qs.QsmShell.Components

TestCase {
    name: "ControlLabel"
    width: 240
    height: 100
    visible: true
    when: windowShown

    Button { id: before; x: 20; y: 60; text: "Before" }
    ControlLabel { id: label; x: 20; y: 20; text: "Name"; clickable: true }
    Button { id: after; x: 120; y: 60; text: "After" }
    SignalSpy { id: clicked; target: label; signalName: "clicked" }

    function init() {
        clicked.clear()
        label.enabled = true
        label.clickable = true
        label.text = "Name"
        label.icon = ""
    }

    function test_pointer_and_programmatic_activation_share_intent() {
        verify(label.activate())
        mouseClick(label)
        compare(clicked.count, 2)
        verify(label.activeFocus)
    }

    function test_tab_backtab_and_keyboard_activation() {
        before.forceActiveFocus()
        keyClick(Qt.Key_Tab)
        verify(label.activeFocus)
        keyClick(Qt.Key_Return)
        keyClick(Qt.Key_Enter)
        keyClick(Qt.Key_Space)
        compare(clicked.count, 3)
        keyClick(Qt.Key_Tab)
        verify(after.activeFocus)
        keyClick(Qt.Key_Backtab)
        verify(label.activeFocus)
        keyClick(Qt.Key_Backtab)
        verify(before.activeFocus)
        label.clickable = false
        keyClick(Qt.Key_Tab)
        verify(after.activeFocus)
    }

    function test_unavailable_or_focus_lost_held_activation_is_cancelled() {
        label.forceActiveFocus()
        keyPress(Qt.Key_Space)
        label.enabled = false
        keyRelease(Qt.Key_Space)
        compare(clicked.count, 0)
        label.enabled = true

        label.forceActiveFocus()
        keyPress(Qt.Key_Return)
        label.clickable = false
        keyRelease(Qt.Key_Return)
        compare(clicked.count, 0)
        label.clickable = true

        label.forceActiveFocus()
        keyPress(Qt.Key_Enter)
        label.text = ""
        keyRelease(Qt.Key_Enter)
        compare(clicked.count, 0)
        label.text = "Name"

        label.forceActiveFocus()
        keyPress(Qt.Key_Space)
        before.forceActiveFocus()
        keyRelease(Qt.Key_Space)
        compare(clicked.count, 0)
    }

    function test_action_calls_guarded_public_operation() {
        verify(label.actions[0].enabled)
        label.actions[0].trigger()
        compare(clicked.count, 1)
        label.clickable = false
        verify(!label.activate())
        compare(clicked.count, 1)
    }

    function test_tab_skips_disabled_and_empty_labels() {
        label.enabled = false
        before.forceActiveFocus()
        keyClick(Qt.Key_Tab)
        verify(after.activeFocus)
        label.enabled = true
        label.text = ""
        before.forceActiveFocus()
        keyClick(Qt.Key_Tab)
        verify(after.activeFocus)
    }

    function test_caption_empty_and_disabled_are_refused() {
        label.clickable = false
        label.activate()
        label.clickable = true
        label.text = ""
        label.activate()
        label.text = "Name"
        label.enabled = false
        label.activate()
        compare(clicked.count, 0)
    }
}
