import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// The host of one Switch: it owns `checked` and answers the intent, so a
// real pointer, Space or Return is visible in the window.
Switch {
    id: root

    property string variant: "off"

    checked: root.variant === "on"
    onToggleRequested: next => root.checked = next

    readonly property var controls: [
        { label: "checked", options: [
            { label: "off", set: { checked: false } },
            { label: "on",  set: { checked: true } }
        ]},
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } },
            // Not in the default table -- previews/theme.json's consumer
            // backend adds it, proving a consumer preset name resolves.
            { label: "xl", set: { size: "xl" } }
        ]},
        { label: "colour", options: [
            { label: "accent",  set: { accentColor: Style.accent } },
            { label: "danger",  set: { accentColor: Style.danger } },
            { label: "success", set: { accentColor: Style.success } }
        ]},
        { label: "state", options: [
            { label: "enabled",  set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ]}
    ]
}
