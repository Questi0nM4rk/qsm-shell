import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// One card on the band it lives on, configured the way its two hosts configure
// it: `popup` is the stack's row (hover opens it, no action row), `list` is the
// centre's row (the leading column opens it, the action row shows).
Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property var inputDriver: null

    property string surface: "popup"
    property string urgency: "normal"
    property string lead: "glyph"
    property bool hasDefault: true
    property string bodyKind: "preview"
    property bool archived: false
    property bool actionEnabled: true
    property bool unread: false
    property bool selected: false
    property bool listExpanded: false
    readonly property bool listMode: root.surface === "list"

    property int callbackCount: 0
    property int dismissals: 0
    property int expandRequests: 0
    property int activations: 0
    property string lastAction: ""
    property string outcome: ""
    readonly property double createdAt: Date.now() - 200000
    readonly property double archivedAt: Date.now() - 7500000

    readonly property string messageBody: root.bodyKind === "empty" ? ""
        : root.bodyKind === "long"
            ? "Could you review the new keyboard interaction before it ships? The focus order now follows the conversation and keeps the current message visible. Please check the edge cases when you have a moment; no change is needed if everything reads clearly."
            : "Could you review the new keyboard interaction before it ships?"

    color: Style.band
    implicitWidth: Style.notificationWidth + Style.space6 * 2
    implicitHeight: 280

    readonly property var entry: ({
        notificationId: "discord-review-1",
        appName: "Discord",
        summary: "Alice · #frontend",
        body: root.messageBody,
        urgency: root.urgency,
        createdAt: root.createdAt,
        archivedAt: root.archived ? root.archivedAt : undefined,
        imagePath: root.lead === "image"
            ? Qt.resolvedUrl("../../qml/QsmShell/assets/icons/application.svg") : undefined,
        // A named action sits before the default: only the exact default is primary.
        actions: root.hasDefault
            ? [{ id: "mark-read", label: "Mark read" },
                { id: "default", label: "Open conversation" }]
            : [{ id: "mark-read", label: "Mark read" }, { id: "snooze", label: "Snooze" }]
    })

    NotificationCard {
        id: card
        x: Style.space6
        y: Style.space6
        width: Style.notificationWidth
        entry: root.entry
        swatch: root.lead === "swatch" ? "#c78fe0" : undefined
        inputEnabled: root.actionEnabled
        primaryActionEnabled: root.hasDefault && root.actionEnabled && !root.archived
        showActions: root.listMode
        bodied: true
        bodyRadius: root.listMode ? Style.radiusBody : Style.radiusMd
        expandOnHover: !root.listMode
        hostExpanded: root.listMode && root.listExpanded
        selected: root.selected
        unread: root.unread
        activatable: root.unread
        draggable: true
        verticalDragEnabled: !root.listMode
        animateEntrance: false
        height: implicitHeight

        onDismissed: {
            root.dismissals++
            root.eventRecorder?.("component", "dismissed", {})
        }
        onExpandRequested: {
            root.expandRequests++
            root.listExpanded = !root.listExpanded
            root.eventRecorder?.("component", "expand-requested", {})
        }
        onActivated: {
            root.activations++
            root.eventRecorder?.("component", "activated", {})
        }
        onActionTriggered: actionId => {
            root.lastAction = actionId
            root.eventRecorder?.("component", "action-invoked", { action: actionId })
        }
        onPrimaryTriggered: requestedEntry => {
            // Fixture evidence only: no application is launched.
            root.callbackCount++
            root.outcome = `Fixture callback invoked · ${requestedEntry.notificationId}`
            root.eventRecorder?.("component", "primary-triggered", { id: requestedEntry.notificationId })
        }
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: Style.space6
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.space4
        width: Style.notificationWidth
        visible: root.outcome.length > 0
        text: root.outcome
        color: Style.textMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.textSm
        elide: Text.ElideRight
    }

    readonly property var controls: [
        { label: "surface", options: [
            { label: "popup", set: { surface: "popup", selected: false, unread: false, listExpanded: false } },
            { label: "list", set: { surface: "list", selected: true, unread: true, listExpanded: false } }
        ] },
        { label: "urgency", options: [
            { label: "low", set: { urgency: "low" } },
            { label: "normal", set: { urgency: "normal" } },
            { label: "critical", set: { urgency: "critical" } }
        ] },
        { label: "lead", options: [
            { label: "glyph", set: { lead: "glyph" } },
            { label: "swatch", set: { lead: "swatch" } },
            { label: "image", set: { lead: "image" } }
        ] },
        { label: "default-action", options: [
            { label: "provided", set: { hasDefault: true } },
            { label: "no-default", set: { hasDefault: false } }
        ] },
        { label: "body", options: [
            { label: "preview", set: { bodyKind: "preview" } },
            { label: "long", set: { bodyKind: "long" } },
            { label: "empty", set: { bodyKind: "empty" } }
        ] },
        { label: "record", options: [
            { label: "live", set: { archived: false } },
            { label: "archived", set: { archived: true } }
        ] },
        { label: "marks", options: [
            { label: "none", set: { unread: false, selected: false } },
            { label: "unread", set: { unread: true, selected: false } },
            { label: "selected", set: { unread: false, selected: true } }
        ] },
        { label: "input", options: [
            { label: "eligible", set: { actionEnabled: true } },
            { label: "retiring", set: { actionEnabled: false } }
        ] }
    ]

    readonly property var integration: ({
        events: ["dismissed", "primary-triggered", "action-invoked", "expand-requested", "activated"],
        actions: ["activate-primary", "dismiss", "first-action", "second-action"],
        targets: ({
            card: () => card,
            scene: () => root
        }),
        observables: {
            "primary-available": () => card.primaryActionAvailable,
            "primary-callback-count": () => root.callbackCount,
            "dismiss-count": () => root.dismissals,
            "expand-requests": () => root.expandRequests,
            "activation-count": () => root.activations,
            "last-action": () => root.lastAction,
            "fixture-outcome": () => root.outcome,
            expanded: () => card.expanded,
            hovered: () => card.hovered,
            pressed: () => card.primaryPressed,
            focused: () => card.activeFocus,
            archived: () => card.archived,
            "input-enabled": () => card.inputEnabled,
            "icon-name": () => card.iconName,
            "has-swatch": () => card.hasSwatch,
            timestamp: () => card.timestampText(),
            height: () => card.height
        },
        runAction: name => {
            if (name === "activate-primary")
                return card.activatePrimary()
            if (name === "dismiss") {
                card.dismiss()
                return true
            }
            if (name === "first-action" || name === "second-action") {
                const list = card.actionList()
                const action = list[name === "first-action" ? 0 : 1]
                if (!action)
                    return false
                card.activateAction(String(action.id))
                return true
            }
            return false
        }
    })
}
