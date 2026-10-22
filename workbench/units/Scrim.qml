pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// The ground a modal would sit over: an output list that answers hover, click
// and wheel. A scrim that catches the pointer is one the list underneath never
// hears, so every observable here counts what REACHED the list.
Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool shown: variant === "shown"
    property bool dismissible: true
    property int dismissals: 0
    property int groundActivations: 0

    readonly property var devices: ["Speakers", "Headphones", "HDMI output", "USB headset",
        "Bluetooth speaker", "Line out", "Monitor speakers", "Loopback"]

    // The dim is the band, so the ground steps up to surface to show it.
    color: Style.surface
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    ScrollArea {
        id: ground
        x: Style.snap((root.width - width) / 2, root)
        y: Style.snap((root.height - height) / 2, root)
        width: Style.controlWidth - Style.space5 * 2
        fadeColor: Style.surface

        Column {
            width: ground.width

            Repeater {
                id: rows
                model: root.devices

                ListRow {
                    required property string modelData
                    width: ground.width
                    icon: "monitor"
                    primary: modelData
                    recede: false
                    onActivated: {
                        root.groundActivations++
                        root.eventRecorder?.("intent", "ground-activated", { device: modelData })
                    }
                }
            }
        }
    }

    Scrim {
        id: scrim
        shown: root.shown
        dismissible: root.dismissible
        onDismissed: {
            root.shown = false
            root.dismissals++
            root.eventRecorder?.("intent", "dismissed", {})
        }
    }

    readonly property var controls: [
        { label: "visibility", options: [
            { label: "shown", set: { shown: true } },
            { label: "hidden", set: { shown: false } }
        ] },
        { label: "dismissal", options: [
            { label: "allowed", set: { dismissible: true } },
            { label: "refused", set: { dismissible: false } }
        ] }
    ]

    function _anyHovered(): bool {
        for (let i = 0; i < rows.count; i++) {
            if ((rows.itemAt(i) as ListRow).hovered)
                return true
        }
        return false
    }

    readonly property var integration: ({
        events: ["dismissed", "ground-activated"],
        idle: () => !ground.viewport.moving && (scrim.shown || !scrim.visible),
        actions: ["dismiss"],
        targets: ({
            "ground-row": () => rows.itemAt(0),
            "ground-list": () => ground,
            scene: () => root
        }),
        observables: {
            shown: () => scrim.shown,
            dismissals: () => root.dismissals,
            "ground-activations": () => root.groundActivations,
            "ground-hovered": () => root._anyHovered(),
            "ground-scrolled": () => ground.viewport.contentY > 0,
            "scrim-visible": () => scrim.visible
        },
        runAction: name => {
            if (name !== "dismiss")
                return false
            scrim.dismiss()
            return true
        }
    })
}
