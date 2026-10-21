import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

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

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    Rectangle {
        id: anchor
        readonly property bool _horizontal: root.placement === "left" || root.placement === "right"
        // Against the preferred side when tight, against the far one when roomy.
        readonly property bool _lowEdge: root.placement === "top" || root.placement === "left"
        readonly property bool _atLow: root.tight ? _lowEdge : !_lowEdge
        x: _horizontal ? (_atLow ? Style.space4 : parent.width - width - Style.space4) : (parent.width - width) / 2
        y: _horizontal ? (parent.height - height) / 2 : (_atLow ? Style.space4 : parent.height - height - Style.space4)
        width: Style.space6 * 2
        height: Style.controlHeightSm
        color: Style.overlay
        radius: Style.radiusSm

        activeFocusOnTab: true
        Keys.onReturnPressed: pop.toggle()
        Keys.onSpacePressed: pop.toggle()
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
            root.open = true
            root.eventRecorder?.("intent", "open-requested", {})
        }
        onDismissRequested: {
            root.dismissRequests++
            root.open = false
            root.eventRecorder?.("intent", "dismiss-requested", {})
        }

        Card {
            surfaceColor: Style.overlay
            width: Style.controlWidth / 2
            height: note.implicitHeight + Style.space4 * 2

            Prose {
                id: note
                anchors.fill: parent
                anchors.margins: Style.space4
                role: "body"
                text: "Pinned beside its anchor"
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

    readonly property var integration: ({
        events: ["open-requested", "dismiss-requested"],
        actions: ["toggle"],
        runAction: name => {
            if (name !== "toggle")
                return false
            pop.toggle()
            return true
        },
        observables: {
            open: () => pop.open,
            hovered: () => pop.hovered,
            side: () => pop.side,
            "open-requests": () => root.openRequests,
            "dismiss-requests": () => root.dismissRequests
        }
    })
}
