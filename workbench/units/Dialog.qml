pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import qs.QsmShell.Components
import qs.QsmShell.Style

// The host: an output list whose last row can be removed. The invoker opens
// the dialog, the dialog asks, and the host answers every signal it hands up,
// closing on Keep, Remove and (unless it is guarding something) Escape and a
// click on the dim.
Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool open: variant === "open"
    property string tone: "danger"
    property bool longBody: false
    property bool dismissible: true
    property int dismissals: 0
    property int closes: 0
    property int confirms: 0
    property int cancels: 0

    readonly property var devices: [
        { name: "Speakers", icon: "speaker" },
        { name: "Headphones", icon: "headphones" },
        { name: "HDMI output", icon: "monitor" }
    ]

    // The dim is the band, so the ground steps up to surface to show it.
    color: Style.surface
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    // Beside the centred card, so the dim reads over something.
    ColumnLayout {
        x: Style.space5
        y: Style.space5
        width: Style.controlWidth / 2
        spacing: Style.space1

        Repeater {
            model: root.devices

            ListRow {
                required property var modelData
                Layout.fillWidth: true
                recede: false
                icon: modelData.icon
                primary: modelData.name
            }
        }

        Capsule {
            id: invoker
            Layout.topMargin: Style.space3
            Layout.alignment: Qt.AlignLeft
            label: "Remove HDMI output"
            icon: "trash-2"
            variant: "destructive"
            onClicked: root.open = true
        }
    }

    Dialog {
        id: dialog
        open: root.open
        title: "Remove HDMI output?"
        body: root.longBody
            ? "It stops appearing in the output list. Anything routed through it falls back to the default output until a new route is made. ".repeat(10)
            : "It stops appearing in the output list. Anything routed through it falls back to the default output."
        tone: root.tone

        onDismissRequested: {
            root.dismissals++
            root.eventRecorder?.("intent", "dismiss-requested", {})
            if (root.dismissible)
                root.open = false
        }
        onClosed: {
            root.closes++
            root.eventRecorder?.("intent", "closed", {})
        }

        // Reading order: the safe action leads and takes first focus.
        Capsule {
            id: keep
            label: "Keep"
            onClicked: {
                root.cancels++
                root.eventRecorder?.("intent", "cancel-clicked", {})
                root.open = false
            }
        }
        Capsule {
            id: remove
            label: "Remove"
            icon: "trash-2"
            variant: "destructive"
            onClicked: {
                root.confirms++
                root.eventRecorder?.("intent", "confirm-clicked", {})
                root.open = false
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
        ] },
        { label: "dismissal", options: [
            { label: "allowed", set: { dismissible: true } },
            { label: "refused", set: { dismissible: false } }
        ] }
    ]

    // Which part of the scene holds the keyboard, by the name a person would
    // give it: the invoker, a dialog action, the dialog itself, anything else.
    function _focusName(): string {
        const active = root.Window.window?.activeFocusItem ?? null
        if (!active)
            return ""
        for (let item = active; item; item = item.parent) {
            if (item === keep)
                return "keep"
            if (item === remove)
                return "remove"
            if (item === invoker)
                return "invoker"
            if (item === dialog)
                return "dialog"
        }
        return "outside"
    }

    readonly property var integration: ({
        events: ["dismiss-requested", "closed", "confirm-clicked", "cancel-clicked"],
        actions: ["confirm", "cancel", "invoke"],
        targets: ({
            invoker: () => invoker,
            keep: () => keep,
            remove: () => remove,
            dialog: () => dialog,
            scene: () => root
        }),
        observables: {
            open: () => dialog.open,
            visible: () => dialog.visible,
            tone: () => dialog.tone,
            dismissals: () => root.dismissals,
            closes: () => root.closes,
            confirms: () => root.confirms,
            cancels: () => root.cancels,
            focus: () => root._focusName(),
            "dialog-role": () => dialog.Accessible.role === Accessible.Dialog,
            "dialog-name": () => dialog.Accessible.name,
            "dialog-description": () => dialog.Accessible.description
        },
        idle: () => dialog.open || !dialog.visible,
        runAction: name => {
            if (name === "confirm")
                remove.activate()
            else if (name === "cancel")
                keep.activate()
            else if (name === "invoke")
                invoker.activate()
            else
                return false
            return true
        }
    })
}
