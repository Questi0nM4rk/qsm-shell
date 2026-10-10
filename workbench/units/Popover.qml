import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool open: variant === "open"
    property string placement: "bottom"
    property int openRequests: 0
    property int dismissRequests: 0

    color: Style.background
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    Rectangle {
        id: anchor
        x: (parent.width - width) / 2
        y: Style.space4
        width: Style.space6 * 2
        height: Style.controlHeightSm
        color: Style.surfaceRaised
        radius: Style.radiusSm
    }

    Popover {
        id: pop
        anchorItem: anchor
        placement: root.placement
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
            { label: "top", set: { placement: "top" } }
        ] }
    ]

    readonly property var integration: ({
        events: ["open-requested", "dismiss-requested"],
        actions: [],
        observables: {
            open: () => pop.open,
            side: () => pop.side,
            "open-requests": () => root.openRequests,
            "dismiss-requests": () => root.dismissRequests
        }
    })
}
