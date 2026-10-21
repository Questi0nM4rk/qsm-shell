import QtQuick

import qs.QsmShell.Components

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool active: variant === "active"
    property string size: "sm"
    property string emphasis: "secondary"
    // label | reading | long | glyph: the same wireless toggle, composed whole.
    property string content: variant === "active" ? "reading" : "label"

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Capsule {
        id: pill
        anchors.centerIn: parent
        icon: "power"
        label: root.content === "glyph" ? "" : root.content === "long" ? "Wireless off · click to enable" : "Wireless"
        detail: root.content === "reading" ? "2 paired" : ""
        accessibleName: "Wireless"
        checkable: true
        size: root.size
        variant: root.emphasis
        active: root.active
        onClicked: {
            root.active = !root.active
            root.eventRecorder?.("intent", "clicked", { active: root.active })
        }
    }

    readonly property var controls: [
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] },
        { label: "active", options: [
            { label: "on", set: { active: true } },
            { label: "off", set: { active: false } }
        ] },
        { label: "size", options: [
            { label: "xs", set: { size: "xs" } },
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "variant", options: [
            { label: "ghost", set: { emphasis: "ghost" } },
            { label: "secondary", set: { emphasis: "secondary" } },
            { label: "primary", set: { emphasis: "primary" } },
            { label: "destructive", set: { emphasis: "destructive" } }
        ] },
        { label: "content", options: [
            { label: "label", set: { content: "label" } },
            { label: "reading", set: { content: "reading" } },
            { label: "long", set: { content: "long" } },
            { label: "glyph-only", set: { content: "glyph" } }
        ] }
    ]
    readonly property var integration: ({
        events: ["clicked"],
        actions: ["activate"],
        keys: {
            "Space": () => { pill.activate(); return true },
            "Enter": () => { pill.activate(); return true }
        },
        observables: { active: () => root.active },
        runAction: name => {
            if (name !== "activate")
                return false
            pill.activate()
            return true
        }
    })
}
