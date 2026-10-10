import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool hasDefault: true
    property bool longBody: false
    property bool emptyBody: false
    property bool archived: false
    property bool actionEnabled: true
    property int callbackCount: 0
    property int dismissals: 0
    property string outcome: ""

    readonly property string messageBody: root.emptyBody ? ""
        : root.longBody
            ? "Could you review the new keyboard interaction before it ships? The focus order now follows the conversation and keeps the current message visible. Please check the edge cases when you have a moment; no change is needed if everything reads clearly."
            : "Could you review the new keyboard interaction before it ships?"

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    readonly property var entry: ({
        notificationId: "discord-review-1",
        appName: "Discord",
        summary: "Alice · #frontend",
        body: root.messageBody,
        urgency: "normal",
        createdAt: Date.now(),
        archivedAt: root.archived ? Date.now() : undefined,
        // Keep a named action before default: only the exact default is primary.
        actions: root.hasDefault
            ? [{ id: "mark-read", label: "Mark read" },
                { id: "default", label: "Open conversation" }]
            : [{ id: "mark-read", label: "Mark read" }]
    })

    NotificationCard {
        id: card
        anchors.centerIn: parent
        entry: root.entry
        visible: true
        inputEnabled: root.actionEnabled
        primaryActionEnabled: root.hasDefault && root.actionEnabled && !root.archived
        showActions: false
        draggable: true
        animateEntrance: false

        onDismissed: {
            root.dismissals++
            root.eventRecorder?.("intent", "dismissed", {})
        }
        onPrimaryTriggered: requestedEntry => {
            // This is fixture callback evidence only; no application is launched.
            root.callbackCount++
            root.outcome = `Fixture callback invoked · ${requestedEntry.notificationId}`
            root.eventRecorder?.("component", "primary-triggered", {
                id: requestedEntry.notificationId
            })
            root.eventRecorder?.("client", "action-invoked", {
                id: requestedEntry.notificationId, action: "default",
                outcome: "fixture-callback-only"
            })
        }
    }

    Text {
        anchors.top: card.bottom
        anchors.topMargin: Style.space2
        anchors.horizontalCenter: card.horizontalCenter
        width: card.width
        visible: root.outcome.length > 0
        text: root.outcome
        color: Style.textMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.textSm
        wrapMode: Text.WordWrap
    }

    readonly property var controls: [
        { label: "default-action", options: [
            { label: "provided", set: { hasDefault: true } },
            { label: "no-default", set: { hasDefault: false } }
        ] },
        { label: "body", options: [
            { label: "preview", set: { longBody: false, emptyBody: false } },
            { label: "long", set: { longBody: true, emptyBody: false } },
            { label: "empty", set: { emptyBody: true, longBody: false } }
        ] },
        { label: "record", options: [
            { label: "live", set: { archived: false } },
            { label: "archived", set: { archived: true } }
        ] },
        { label: "input", options: [
            { label: "eligible", set: { actionEnabled: true } },
            { label: "retiring", set: { actionEnabled: false } }
        ] }
    ]

    readonly property var integration: ({
        events: ["dismissed", "primary-triggered", "action-invoked"],
        actions: ["activate-primary", "dismiss"],
        observables: {
            "primary-available": () => card.primaryActionAvailable,
            "primary-callback-count": () => root.callbackCount,
            "fixture-outcome": () => root.outcome,
            "dismiss-count": () => root.dismissals,
            "body-expanded": () => card.expanded,
            "body-preview": () => root.messageBody,
            archived: () => card.archived,
            "input-enabled": () => card.inputEnabled
        },
        runAction: name => {
            if (name === "activate-primary")
                return card.activatePrimary();
            if (name === "dismiss") {
                card.dismiss();
                return true;
            }
            return false;
        }
    })
}
