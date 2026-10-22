import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool expanded: true
    property string badge: "3"
    property bool iconShown: true
    property bool longContent: false
    property int toggles: 0

    implicitWidth: Style.controlWidth
    implicitHeight: Style.size("Control", "lg") + Style.space6 * 2

    Disclosure {
        id: disclosure

        width: root.width
        title: root.longContent
            ? "Advanced display and compositor options for every connected output" : "Advanced"
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
            Layout.fillWidth: true
            role: "body"
            text: root.longContent
                ? "Bar, launcher and rail share one rhythm; every colour comes from the style, and every size from its table, so a long paragraph of detail wraps inside the room the heading leaves it instead of running past it."
                : "Bar, launcher and rail share one rhythm; every colour comes from the style."
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
        { label: "content", options: [
            { label: "short", set: { longContent: false } },
            { label: "long", set: { longContent: true } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]

    readonly property var integration: ({
        events: ["toggled"],
        actions: ["toggle"],
        targets: ({ disclosure: () => disclosure }),
        observables: {
            expanded: () => disclosure.expanded,
            focused: () => disclosure.focused,
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
