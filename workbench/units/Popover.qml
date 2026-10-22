pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import qs.QsmShell.Components
import qs.QsmShell.Style

// The host: an output button whose detail opens beside it, with an action in
// the panel so the keyboard and a pointer have something to reach there. The
// host answers every request; `manual` is the one trigger where it also wires
// the button itself.
Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool open: variant === "open"
    property string placement: "bottom"
    property string alignment: "center"
    property string trigger: "manual"
    // The anchor sits against the preferred side's edge, so the popover has to
    // flip to the side with room.
    property bool tight: false
    property int openRequests: 0
    property int dismissRequests: 0
    property int settingsClicks: 0

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    Capsule {
        id: anchor
        readonly property bool _horizontal: root.placement === "left" || root.placement === "right"
        // Against the preferred side's edge when tight, against the far one when roomy.
        readonly property bool _lowEdge: root.placement === "top" || root.placement === "left"
        readonly property bool _atLow: root.tight ? _lowEdge : !_lowEdge
        x: Style.snap(_horizontal ? (_atLow ? Style.space4 : parent.width - width - Style.space4) : (parent.width - width) / 2, root)
        y: Style.snap(_horizontal ? (parent.height - height) / 2 : (_atLow ? Style.space4 : parent.height - height - Style.space4), root)
        label: "HDMI output"
        icon: "monitor"
        // The popover wires a press or hover trigger itself; only a manual one is the host's.
        onClicked: if (root.trigger === "manual") pop.toggle()
    }

    Popover {
        id: pop
        anchorItem: anchor
        placement: root.placement
        alignment: root.alignment
        trigger: root.trigger
        open: root.open

        onOpenRequested: {
            root.openRequests++
            root.eventRecorder?.("intent", "open-requested", {})
            root.open = true
        }
        onDismissRequested: {
            root.dismissRequests++
            root.eventRecorder?.("intent", "dismiss-requested", {})
            root.open = false
        }

        Card {
            id: card
            surfaceColor: Style.overlay
            glow: true
            width: Style.controlWidth / 2
            height: content.implicitHeight + Style.space4 * 2

            ColumnLayout {
                id: content
                x: Style.space4
                y: Style.space4
                width: parent.width - Style.space4 * 2
                spacing: Style.space1

                Prose {
                    role: "title"
                    text: "HDMI output"
                }
                Prose {
                    role: "supporting"
                    text: "48 kHz · 2 channels"
                }
                Capsule {
                    id: settings
                    Layout.fillWidth: true
                    Layout.topMargin: Style.space2
                    size: "sm"
                    label: "Sound settings"
                    onClicked: {
                        root.settingsClicks++
                        root.eventRecorder?.("intent", "settings-clicked", {})
                    }
                }
            }
        }
    }

    readonly property var controls: [
        { label: "state", options: [
            { label: "open", set: { open: true } },
            { label: "closed", set: { open: false } }
        ] },
        { label: "placement", options: [
            { label: "bottom", set: { placement: "bottom" } },
            { label: "top", set: { placement: "top" } },
            { label: "left", set: { placement: "left" } },
            { label: "right", set: { placement: "right" } }
        ] },
        { label: "alignment", options: [
            { label: "center", set: { alignment: "center" } },
            { label: "start", set: { alignment: "start" } },
            { label: "end", set: { alignment: "end" } }
        ] },
        { label: "trigger", options: [
            { label: "manual", set: { trigger: "manual" } },
            { label: "hover", set: { trigger: "hover" } },
            { label: "press", set: { trigger: "press" } }
        ] },
        { label: "room", options: [
            { label: "roomy", set: { tight: false } },
            { label: "tight", set: { tight: true } }
        ] }
    ]

    // Where the keyboard is, by the name a person would give it.
    function _focusName(): string {
        for (let item = root.Window.window?.activeFocusItem ?? null; item; item = item.parent) {
            if (item === settings)
                return "settings"
            if (item === anchor)
                return "anchor"
        }
        return ""
    }

    readonly property var integration: ({
        events: ["open-requested", "dismiss-requested", "settings-clicked"],
        actions: ["toggle", "focus-anchor"],
        targets: ({
            anchor: () => anchor,
            settings: () => settings,
            panel: () => card,
            scene: () => root
        }),
        observables: {
            open: () => pop.open,
            // The panel has stopped travelling: fully opaque and painted where it is laid out.
            settled: () => pop.opacity === 1 && Math.hypot(card.mapToItem(root, 0, 0).x - pop.x, card.mapToItem(root, 0, 0).y - pop.y) < 0.01,
            hovered: () => pop.hovered,
            side: () => pop.side,
            focus: () => root._focusName(),
            "open-requests": () => root.openRequests,
            "dismiss-requests": () => root.dismissRequests,
            "settings-clicks": () => root.settingsClicks
        },
        runAction: name => {
            if (name === "toggle")
                pop.toggle()
            else if (name === "focus-anchor")
                anchor.forceActiveFocus(Qt.TabFocusReason)
            else
                return false
            return true
        }
    })
}
