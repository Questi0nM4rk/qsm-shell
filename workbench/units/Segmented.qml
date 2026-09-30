import QtQuick

import qs.QsmShell.Components

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property int currentIndex: variant === "second" ? 1 : 0
    property bool mediaLocked: false

    implicitWidth: bar.implicitWidth
    implicitHeight: bar.implicitHeight

    Segmented {
        id: bar
        anchors.centerIn: parent
        options: ["Overview", { label: "Media", disabled: root.mediaLocked }, "Alerts"]
        currentIndex: root.currentIndex
        onSelected: index => {
            root.currentIndex = index
            root.eventRecorder?.("component", "selected", { index })
        }
    }

    readonly property var controls: [
        { label: "middle-option", options: [
            { label: "enabled", set: { mediaLocked: false } },
            { label: "disabled", set: { mediaLocked: true } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["selected"],
        actions: ["previous", "next", "first", "last"],
        observables: { "current-index": () => root.currentIndex },
        runAction: name => {
            if (name === "previous")
                return bar.step(-1)
            if (name === "next")
                return bar.step(1)
            if (name === "first")
                return bar.first()
            if (name === "last")
                return bar.last()
            return false
        }
    })
}
