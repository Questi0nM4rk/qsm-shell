import QtQuick
import QtTest
import qs.QsmShell.Components

TestCase {
    name: "Disclosure"
    width: 360
    height: 240
    visible: true
    when: windowShown

    Disclosure {
        id: disclosure
        x: 20
        y: 20
        width: 300
        title: "Details"
    }
    SignalSpy { id: toggled; target: disclosure; signalName: "toggled" }

    function init() {
        disclosure.expanded = false
        disclosure.enabled = true
        toggled.clear()
    }

    function test_routes_emit_intent_without_mutating_host_state() {
        disclosure.toggle()
        compare(toggled.count, 1)
        compare(toggled.signalArguments[0][0], true)
        compare(disclosure.expanded, false)
        mouseClick(disclosure, 30, 20)
        compare(toggled.count, 2)
        findChild(disclosure, "disclosureHeading").forceActiveFocus()
        keyClick(Qt.Key_Space)
        compare(toggled.count, 3)
        keyClick(Qt.Key_Return)
        compare(toggled.count, 4)
        keyClick(Qt.Key_Enter)
        compare(toggled.count, 5)
    }

    function test_disabled_routes_are_refused() {
        disclosure.enabled = false
        disclosure.toggle()
        compare(toggled.count, 0)
    }
}
