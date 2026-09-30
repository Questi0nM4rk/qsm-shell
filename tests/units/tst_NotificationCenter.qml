import QtQuick
import QtTest
import qs.QsmShell.Components

TestCase {
    name: "NotificationCenter"
    width: 500
    height: 500
    visible: true
    when: windowShown

    NotificationCenter {
        id: center
        width: 460
        entries: []
    }
    SignalSpy { id: triggered; target: center; signalName: "actionTriggered" }
    SignalSpy { id: dismissed; target: center; signalName: "dismissRequested" }

    function init() {
        center.enabled = true
        center.visible = true
        center.entries = [{ notificationId: "n1", appName: "App", summary: "Alert", actions: [
            { id: "open", label: "Open" },
            { id: "blocked", label: "Blocked", disabled: true },
            { id: "reply", label: "Reply" },
            { id: "hidden", label: "Fourth" }
        ] }]
        center.currentIndex = 0
        tryVerify(() => center.selectedEntry() !== null)
        center.expandedKey = center.entryKey(center.selectedEntry())
        center.actionFocusIndex = -1
        center.focusField()
        triggered.clear()
        dismissed.clear()
    }

    function test_navigation_and_enter_share_card_availability() {
        center.moveAction(-1)
        compare(center.actionFocusIndex, 2)
        center.moveAction(1)
        compare(center.actionFocusIndex, 0)
        center.moveAction(1)
        compare(center.actionFocusIndex, 2)
        keyClick(Qt.Key_Return)
        compare(triggered.count, 1)
        compare(triggered.signalArguments[0][1], "reply")
        compare(center.actionFocusIndex, -1)
        compare(center.entries.length, 1)
    }

    function test_stale_or_unavailable_action_data() {
        return [
            { tag: "disabled-action", index: 1 },
            { tag: "fourth-action", index: 3 },
            { tag: "stale-index", index: 20 },
            { tag: "archived", index: 0, archived: true },
            { tag: "collapsed", index: 0, collapsed: true },
            { tag: "disabled-center", index: 0, disabled: true },
            { tag: "hidden-center", index: 0, hidden: true }
        ]
    }

    function test_stale_or_unavailable_action(data) {
        if (data.archived) {
            center.entries = [Object.assign({}, center.entries[0], { archivedAt: 10 })]
            tryVerify(() => center.selectedEntry()?.archivedAt === 10)
            center.expandedKey = center.entryKey(center.selectedEntry())
            center.moveAction(1)
            compare(center.actionFocusIndex, -1)
        }
        if (data.collapsed)
            center.expandedKey = ""
        center.actionFocusIndex = data.index
        if (data.disabled)
            center.enabled = false
        if (data.hidden)
            center.visible = false
        if (data.disabled || data.hidden)
            center.activateSelected()
        else
            keyClick(Qt.Key_Return)
        compare(triggered.count, 0)
        compare(center.actionFocusIndex, -1)
        center.removeSelected()
        compare(dismissed.count, data.disabled || data.hidden ? 0 : 1)
        compare(center.entries.length, 1)
    }
}
