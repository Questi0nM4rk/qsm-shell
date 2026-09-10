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
