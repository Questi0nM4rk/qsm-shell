import QtQuick

import qs.QsmShell.Components

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property int currentIndex: variant === "second" ? 1 : 0
    property bool mediaLocked: false
    property bool tabNavigation: false
    property bool wrapNavigation: true
    property string unavailable: "none"
    property string size: "md"
    property bool hostRefuses: false
    property string badge: "none"

    implicitWidth: bar.implicitWidth
    implicitHeight: bar.implicitHeight

    Segmented {
        id: bar
        anchors.centerIn: parent
        options: [
            { label: "Overview", disabled: ["first", "all"].includes(root.unavailable) },
            { label: "Media", disabled: root.mediaLocked || ["middle", "all"].includes(root.unavailable) },
            { label: "Alerts", badge: root.badge === "count" ? "3" : "", disabled: ["last", "all"].includes(root.unavailable) }
        ]
        size: root.size
        tabNavigation: root.tabNavigation
        wrapNavigation: root.wrapNavigation
        currentIndex: root.currentIndex
        onSelected: index => {
            if (!root.hostRefuses)
                root.currentIndex = index
            root.eventRecorder?.("intent", "selected", { index })
        }
    }

    readonly property var controls: [
        { label: "navigation", options: [
            { label: "standard", set: { tabNavigation: false, wrapNavigation: true } },
            { label: "panel-tabs", set: { tabNavigation: true, wrapNavigation: false } }
        ] },
        { label: "unavailable", options: [
            { label: "none", set: { unavailable: "none" } },
            { label: "first", set: { unavailable: "first" } },
            { label: "middle", set: { unavailable: "middle" } },
            { label: "last", set: { unavailable: "last" } },
            { label: "all", set: { unavailable: "all" } }
        ] },
        { label: "size", options: [
            { label: "small", set: { size: "sm" } },
            { label: "medium", set: { size: "md" } },
            { label: "large", set: { size: "lg" } }
        ] },
        { label: "middle-option", options: [
            { label: "enabled", set: { mediaLocked: false } },
            { label: "disabled", set: { mediaLocked: true } }
        ] },
        { label: "badge", options: [
            { label: "none", set: { badge: "none" } },
            { label: "count", set: { badge: "count" } }
        ] },
        { label: "host", options: [
            { label: "accepts", set: { hostRefuses: false } },
            { label: "refuses", set: { hostRefuses: true } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    function _which(test: var): int {
        for (let i = 0; i < bar.count; i++) {
            if (test(bar.itemAt(i)))
                return i
        }
        return -1
    }

    readonly property var integration: ({
        events: ["selected"],
        actions: ["previous", "next", "first", "last"],
        targets: ({
            bar: () => bar,
            overview: () => bar.itemAt(0),
            media: () => bar.itemAt(1),
            alerts: () => bar.itemAt(2),
            scene: () => root
        }),
        observables: {
            "current-index": () => root.currentIndex,
            hovered: () => root._which(tab => tab.hovered),
            pressed: () => root._which(tab => tab.pressed),
            "segment-height": () => bar.itemAt(0).height
        },
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
