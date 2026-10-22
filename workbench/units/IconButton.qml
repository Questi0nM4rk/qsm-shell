import QtQuick

import qs.QsmShell.Components

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property string size: "md"
    property string glyph: "check"
    property int clicks: 0

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    IconButton {
        id: button
        anchors.centerIn: parent
        icon: root.glyph
        accessibleName: root.glyph === "play" ? "Play" : "Apply"
        size: root.size
        onClicked: {
            root.clicks++
            root.eventRecorder?.("intent", "clicked", {})
        }
    }

    readonly property var controls: [
        { label: "size", options: [
            { label: "xs", set: { size: "xs" } },
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "glyph", options: [
            { label: "check", set: { glyph: "check" } },
            { label: "play", set: { glyph: "play" } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["clicked"],
        actions: ["activate"],
        targets: ({ button: () => button }),
        observables: {
            enabled: () => root.enabled,
            clicks: () => root.clicks,
            size: () => root.size,
            "box-size": () => button.width,
            "glyph-size": () => button.contentItem.implicitWidth,
            glyph: () => root.glyph,
            "accessible-name": () => button.Accessible.name,
            "accessible-button": () => button.Accessible.role === Accessible.Button
        },
        runAction: name => {
            if (name !== "activate")
                return false
            button.activate()
            return true
        }
    })
}
