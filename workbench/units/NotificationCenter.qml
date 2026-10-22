import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// The history on the band it lives on, hosted the way the desktop hosts it:
// the host owns the entries, the view and the do-not-disturb flag, and answers
// every intent the centre reports.
Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property var inputDriver: null
    property bool dnd: false
    property string view: "unread"
    property string query: ""
    property string lastAction: ""
    property string lastDismissed: ""
    property string population: "mixed"
    property int dismissed: 0
    property int activations: 0
    property int escaped: 0
    property int claims: 0
    property int clears: 0
    property int dndToggles: 0

    readonly property double now: Date.now()
    readonly property var mixed: [
        { notificationId: "n1", appName: "Shell", summary: "Build finished", body: "qsm-shell is ready.",
            urgency: "low", read: false, createdAt: root.now - 120000, actions: [] },
        { notificationId: "n2", appName: "Composer", summary: "Output switched", body: "The OSD now names the sink.",
            urgency: "normal", read: true, createdAt: root.now - 900000, actions: [{ id: "open", label: "Open" }] },
        { notificationId: "n3", appName: "Power", summary: "Battery critically low",
            body: "Plug in within five minutes or the session will hibernate.",
            urgency: "critical", read: false, createdAt: root.now - 1500000, actions: [] },
        { notificationId: "n4", appName: "Mail", summary: "Weekly report",
            body: "The quarterly numbers are in and the summary is attached. Revenue is up on the previous period and the three open risks from the last review are closed; the remaining items need a decision from you before the end of the week. Please read section four first.",
            urgency: "normal", read: false, createdAt: root.now - 3600000,
            actions: [{ id: "reply", label: "Reply" }, { id: "archive", label: "Archive" }] },
        { appName: "Shell", summary: "Update installed", body: "Restart to finish.", urgency: "normal", read: true,
            createdAt: root.now - 90000000, archivedAt: root.now - 7200000, actions: [] },
        { appName: "Colour picker", summary: "#c78fe0", body: "Copied to the clipboard.", urgency: "normal", read: true,
            createdAt: root.now - 90000000, archivedAt: root.now - 10800000, actions: [] },
        { appName: "Mail", summary: "Invoice paid", body: "Thank you, the invoice for October is settled.", urgency: "normal",
            read: true, createdAt: root.now - 90000000, archivedAt: root.now - 90000000, actions: [] }
    ]
    readonly property var allRead: root.mixed.map(entry => Object.assign({}, entry, { read: true }))
    property var entries: root.mixed

    color: Style.band
    // The cards are one notification wide; the list reaches past them by the
    // shadow's extent on each side, and the unit leaves a space4 margin.
    implicitWidth: Style.notificationWidth + Style.cardShadowExtent * 2 + Style.space4 * 2
    implicitHeight: 480

    NotificationCenter {
        id: center
        anchors.fill: parent
        anchors.margins: Style.space4
        entries: root.entries
        dnd: root.dnd
        query: root.query
        fadeColor: Style.band
        // A colour-picker announcement's summary IS the picked colour.
        swatchFor: entry => entry.appName === "Colour picker" && /^#[0-9a-fA-F]{6}$/.test(entry.summary)
            ? entry.summary : undefined

        // The host owns `view`: the control strip sets it on the unit and the
        // centre's own view switch writes it back.
        Binding { target: center; property: "view"; value: root.view }
        onViewChanged: root.view = center.view

        onActivated: entry => {
            root.activations++
            root.entries = root.entries.map(candidate =>
                center.entryKey(candidate) === center.entryKey(entry)
                    ? Object.assign({}, candidate, { read: true }) : candidate)
            root.eventRecorder?.("intent", "activated", {})
        }

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
            root.dndToggles++
            root.eventRecorder?.("intent", "dnd-toggled", { dnd: root.dnd })
        }
        onClearRequested: {
            root.clears++
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
        // Delete is a list command here, as the desktop makes it: the rows are
        // the thing being acted on.
        onKeyPressed: event => {
            root.eventRecorder?.("intent", "key-pressed", {})
            if (event.key === Qt.Key_Delete) {
                center.removeSelected()
                event.accepted = true
            }
        }
    }

    readonly property var controls: [
        { label: "disturbance", options: [
            { label: "off", set: { dnd: false } },
            { label: "on", set: { dnd: true } }
        ] },
        { label: "view", options: [
            { label: "unread", set: { view: "unread" } },
            { label: "all", set: { view: "all" } }
        ] },
        { label: "filter", options: [
            { label: "all", set: { query: "" } },
            { label: "none", set: { query: "zzz-no-match" } }
        ] },
        { label: "history", options: [
            { label: "mixed", set: { population: "mixed", entries: root.mixed } },
            { label: "all-read", set: { population: "all-read", entries: root.allRead } },
            { label: "empty", set: { population: "empty", entries: [] } }
        ] }
    ]

    readonly property var integration: ({
        events: ["activated", "dismiss-requested", "action-triggered", "hover-changed", "dnd-toggled", "clear-requested", "escaped", "selection-claimed", "key-pressed"],
        actions: ["select-next", "select-previous", "toggle", "activate", "remove", "move-action-next", "move-action-previous", "focus-field"],
        targets: ({
            scene: () => root,
            field: () => center.searchTarget
        }),
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
            view: () => center.view,
            "unread-count": () => center.unreadCount,
            "current-index": () => center.currentIndex,
            expanded: () => center.expandedKey !== "",
            "last-action": () => root.lastAction,
            "last-dismissed": () => root.lastDismissed,
            dismissed: () => root.dismissed,
            activations: () => root.activations,
            escapes: () => root.escaped,
            claims: () => root.claims,
            clears: () => root.clears,
            "dnd-toggles": () => root.dndToggles,
            "field-focused": () => (center.searchTarget as TextField)?.focused === true
        },
        runAction: name => {
            if (name === "select-next") { center.moveSelection(1); return true }
            if (name === "select-previous") { center.moveSelection(-1); return true }
            if (name === "toggle") { center.toggleSelected(); return true }
            if (name === "activate") { center.activateSelected(); return true }
            if (name === "remove") { center.removeSelected(); return true }
            if (name === "move-action-next") { center.moveAction(1); return true }
            if (name === "move-action-previous") { center.moveAction(-1); return true }
            if (name === "focus-field") { center.focusField(); return true }
            return false
        }
    })
}
