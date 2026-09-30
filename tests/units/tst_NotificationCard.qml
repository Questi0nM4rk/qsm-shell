import QtQuick
import QtTest
import qs.QsmShell.Components

TestCase {
    name: "NotificationCard"
    width: 500
    height: 180
    visible: true
    when: windowShown

    NotificationCard {
        id: card
        x: 10
        y: 10
        width: 460
        alwaysExpanded: true
        animateEntrance: false
        entry: ({ notificationId: "n1", appName: "App", summary: "Alert", actions: [
            { id: "open", label: "Open" }, { id: "disabled", label: "Disabled", disabled: true }
        ] })
    }
    SignalSpy { id: dismissalSpy; target: card; signalName: "dismissed" }
    SignalSpy { id: triggered; target: card; signalName: "actionTriggered" }

    function init() {
        card.entry = ({ notificationId: "n1", appName: "App", summary: "Alert", actions: [
            { id: "open", label: "Open" }, { id: "disabled", label: "Disabled", disabled: true }
        ] })
        card.actionFocusIndex = -1
        card.enabled = true
        card.showActions = true
        dismissalSpy.clear()
        triggered.clear()
    }

    function test_programmatic_and_pointer_dismissal_report_without_removal() {
        compare(card.enabled, true)
        compare(card.archived, false)
        card.dismiss()
        compare(dismissalSpy.count, 1)
        mouseClick(card, 450, 10, Qt.MiddleButton)
        compare(dismissalSpy.count, 2)
        verify(card.entry !== undefined)
    }

    function test_action_routes_reject_unavailable_entries() {
        card.activateAction("open")
        compare(triggered.count, 1)
        card.activateAction("missing")
        card.activateAction("disabled")
        card.showActions = false
        card.activateAction("open")
        compare(triggered.count, 1)
        card.showActions = true
        card.actionFocusIndex = 0
        card.entry = ({ notificationId: "n2", appName: "App", summary: "Archived", archivedAt: 10,
            actions: [{ id: "open", label: "Open" }] })
        card.activateAction("open")
        card.dismiss()
        compare(triggered.count, 1)
        compare(dismissalSpy.count, 1)
    }
}
