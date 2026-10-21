import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool expanded: true
    property string badge: "3"
    property bool iconShown: true
    property int toggles: 0

    implicitWidth: Style.controlWidth
    implicitHeight: Style.size("Control", "lg") + Style.space6 * 2

    Disclosure {
        id: disclosure

        width: root.width
        title: "Advanced"
        icon: root.iconShown ? "gauge" : ""
        badge: root.badge
        expanded: root.expanded

        onToggled: value => {
            root.toggles++
            root.expanded = value
            root.eventRecorder?.("intent", "toggled", { expanded: value })
        }

        Prose {
            id: contentText
            role: "body"
            text: "Bar, launcher and rail share one rhythm; every colour comes from the style."
        }
    }

    readonly property var controls: [
        { label: "expansion", options: [
            { label: "open", set: { expanded: true } },
            { label: "closed", set: { expanded: false } }
        ] },
        { label: "badge", options: [
            { label: "count", set: { badge: "3" } },
            { label: "none", set: { badge: "" } }
        ] },
        { label: "icon", options: [
            { label: "shown", set: { iconShown: true } },
            { label: "none", set: { iconShown: false } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]

    readonly property var integration: ({
        events: ["toggled"],
        actions: ["toggle"],
        observables: {
            expanded: () => disclosure.expanded,
            toggles: () => root.toggles,
            badge: () => disclosure.badge,
            icon: () => disclosure.icon
        },
        runAction: name => {
            if (name !== "toggle")
                return false
            disclosure.toggle()
            return true
        }
    })
}
