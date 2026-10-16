import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool dnd: false
    property string query: ""
    property string lastAction: ""
    property string lastDismissed: ""
    property int dismissed: 0
    property int escaped: 0
    property int claims: 0
    property var entries: [
        {
            notificationId: "n1",
            appName: "Shell",
            summary: "Build finished",
            body: "qsm-shell is ready.",
            urgency: "low",
            createdAt: 0,
            actions: []
        },
        {
            notificationId: "n2",
            appName: "Composer",
            summary: "Output switched",
            body: "The OSD now names the sink.",
            urgency: "normal",
            createdAt: 0,
            actions: [{ id: "open", label: "Open" }]
        },
        {
            appName: "Shell",
            summary: "Update installed",
            body: "Restart to finish.",
            urgency: "normal",
            createdAt: 0,
            archivedAt: 1,
            actions: []
        }
    ]

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth * 2

    NotificationCenter {
        id: center
        anchors.fill: parent
        anchors.margins: Style.space4
        entries: root.entries
        dnd: root.dnd
        query: root.query

        onDismissRequested: entry => {
            root.dismissed++
            root.lastDismissed = entry.summary ?? ""
            root.entries = root.entries.filter(candidate => center.entryKey(candidate) !== center.entryKey(entry))
            root.eventRecorder?.("intent", "dismiss-requested", {})
        }
        onActionTriggered: (entry, actionId) => {
            root.lastAction = actionId
            root.eventRecorder?.("intent", "action-triggered", { action: actionId })
        }
        onHoverChanged: (entry, hovered) => root.eventRecorder?.("intent", "hover-changed", { hovered })
        onDndToggled: {
            root.dnd = !root.dnd
            root.eventRecorder?.("intent", "dnd-toggled", { dnd: root.dnd })
        }
        onClearRequested: {
            root.entries = []
            root.eventRecorder?.("intent", "clear-requested", {})
        }
        onEscaped: {
            root.escaped++
            root.eventRecorder?.("intent", "escaped", {})
        }
        onSelectionClaimed: {
            root.claims++
            root.eventRecorder?.("intent", "selection-claimed", {})
        }
        onKeyPressed: root.eventRecorder?.("intent", "key-pressed", {})
    }

    readonly property var controls: [
        { label: "disturbance", options: [
            { label: "off", set: { dnd: false } },
            { label: "on", set: { dnd: true } }
        ] },
        { label: "filter", options: [
            { label: "all", set: { query: "" } },
            { label: "none", set: { query: "zzz-no-match" } }
        ] }
    ]

    readonly property var integration: ({
        events: ["dismiss-requested", "action-triggered", "hover-changed", "dnd-toggled", "clear-requested", "escaped", "selection-claimed", "key-pressed"],
        actions: ["select-next", "select-previous", "toggle", "activate", "remove"],
        keys: {
            "Enter": () => { center.activateSelected(); return true }
        },
        textDriver: text => {
            root.query = String(text)
            return true
        },
        observables: {
            count: () => center.items.length,
            query: () => center.query,
            dnd: () => center.dnd,
            "current-index": () => center.currentIndex,
            expanded: () => center.expandedKey !== "",
            "last-action": () => root.lastAction,
            "last-dismissed": () => root.lastDismissed,
            dismissed: () => root.dismissed
        },
        runAction: name => {
            if (name === "select-next") { center.moveSelection(1); return true }
            if (name === "select-previous") { center.moveSelection(-1); return true }
            if (name === "toggle") { center.toggleSelected(); return true }
            if (name === "activate") { center.activateSelected(); return true }
            if (name === "remove") { center.removeSelected(); return true }
            return false
        }
    })
}
