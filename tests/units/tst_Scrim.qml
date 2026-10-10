import QtQuick
import QtTest
import qs.QsmShell.Components

TestCase {
    name: "Scrim"
    width: 240
    height: 180
    visible: true
    when: windowShown

    Scrim { id: scrim; shown: true }
    SignalSpy { id: dismissalSpy; target: scrim; signalName: "dismissed" }

    function init() { dismissalSpy.clear(); scrim.shown = true; scrim.enabled = true }

    function test_pointer_and_programmatic_dismissal_share_intent_once() {
        scrim.shown = true
        compare(scrim.shown, true)
        scrim.dismiss()
        compare(dismissalSpy.count, 1)
        mouseClick(scrim, 120, 90, Qt.RightButton)
        compare(dismissalSpy.count, 2)
        compare(scrim.shown, true)
    }

    function test_hidden_and_disabled_are_refused() {
        scrim.shown = false
        scrim.dismiss()
        scrim.shown = true
        scrim.enabled = false
        scrim.dismiss()
        compare(dismissalSpy.count, 0)
    }
}
