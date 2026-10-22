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
        view: "all"
        fadeColor: "#271e30"
    }
    SignalSpy { id: triggered; target: center; signalName: "actionTriggered" }
    SignalSpy { id: dismissed; target: center; signalName: "dismissRequested" }
    SignalSpy { id: hovered; target: center; signalName: "hoverChanged" }

    function init() {
        center.query = ""
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
        mouseMove(center, -20, -20)
        hovered.clear()
    }

    function test_sort_does_not_change_host_feed_and_searches_application() {
        const entries = [
            { archiveId: "old", archivedAt: 10, appName: "Mail", summary: "First", body: "" },
            { archiveId: "new", archivedAt: 20, appName: "Build", summary: "Done", body: "" }
        ]
        center.entries = entries
        tryVerify(() => center.selectedEntry()?.archiveId === "new")
        compare(entries[0].archiveId, "old")
        compare(entries[1].archiveId, "new")
        center.query = "Mail"
        tryVerify(() => center.selectedEntry()?.archiveId === "old")
        compare(center.items.length, 1)
    }

    function test_same_count_replacement_retains_identity() {
        center.entries = [
            { archiveId: "a", archivedAt: 20, appName: "Mail", summary: "A", body: "" },
            { archiveId: "b", archivedAt: 10, appName: "Mail", summary: "B", body: "" }
        ]
        tryVerify(() => center.selectedEntry()?.archiveId === "a")
        center.moveSelection(1)
        compare(center.selectedEntry().archiveId, "b")
        center.entries = [
            { archiveId: "a", archivedAt: 5, appName: "Mail", summary: "A", body: "" },
            { archiveId: "b", archivedAt: 30, appName: "Mail", summary: "B updated", body: "" }
        ]
        tryVerify(() => center.selectedEntry()?.summary === "B updated")
        center.removeSelected()
        compare(dismissed.count, 1)
        compare(dismissed.signalArguments[0][0].archiveId, "b")
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

    function test_hover_pause_snapshot_keeps_the_hovered_delegate() {
        const button = findChild(center, "notificationAction0")
        verify(button !== null)
        mouseMove(button, button.width / 2, button.height / 2)
        tryVerify(() => hovered.count > 0)
        compare(hovered.signalArguments[hovered.count - 1][1], true)
        hovered.clear()
        center.entries = [Object.assign({}, center.entries[0], { paused: true })]
        tryVerify(() => center.selectedEntry()?.paused === true && !center.restoringCursor)
        compare(findChild(center, "notificationAction0"), button)
        compare(hovered.count, 0)
        mouseClick(button, button.width / 2, button.height / 2)
        compare(triggered.count, 1)
        compare(triggered.signalArguments[0][1], "open")
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
