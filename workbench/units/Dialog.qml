import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool open: variant === "open"
    property string tone: "danger"
    property bool longBody: false
    property int dismissals: 0
    property int closes: 0
    property int confirms: 0

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    Dialog {
        id: dialog
        open: root.open
        title: "Remove device?"
        body: root.longBody
            ? "The sink stays; the route goes away. Anything routed through it falls back to the default output until a new route is made. ".repeat(12)
            : "The sink stays; the route goes away."
        tone: root.tone

        onDismissRequested: {
            root.dismissals++
            root.eventRecorder?.("intent", "dismiss-requested", {})
        }
        onClosed: {
            root.closes++
            root.eventRecorder?.("intent", "closed", {})
        }

        // Reading order: the safe action leads and takes first focus.
        Capsule {
            label: "Keep"
            icon: "x"
            onClicked: root.eventRecorder?.("intent", "cancel-clicked", {})
        }
        Capsule {
            id: confirm
            label: "Remove"
            icon: "check"
            variant: "destructive"
            onClicked: {
                root.confirms++
                root.eventRecorder?.("intent", "confirm-clicked", {})
            }
        }
    }

    readonly property var controls: [
        { label: "state", options: [
            { label: "open", set: { open: true } },
            { label: "closed", set: { open: false } }
        ] },
        { label: "tone", options: [
            { label: "danger", set: { tone: "danger" } },
            { label: "warning", set: { tone: "warning" } },
            { label: "neutral", set: { tone: "neutral" } }
        ] },
        { label: "body", options: [
            { label: "short", set: { longBody: false } },
            { label: "long", set: { longBody: true } }
        ] }
    ]

    readonly property var integration: ({
        events: ["dismiss-requested", "closed", "confirm-clicked", "cancel-clicked"],
        actions: ["confirm"],
        observables: {
            open: () => dialog.open,
            tone: () => dialog.tone,
            dismissals: () => root.dismissals,
            closes: () => root.closes,
            confirms: () => root.confirms
        },
        runAction: name => {
            if (name !== "confirm")
                return false
            confirm.activate()
            return true
        }
    })
}
