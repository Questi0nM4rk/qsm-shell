import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Switch {
    id: root

    property string variant: "off"

    checked: root.variant === "on"
    // Switch is host-owned: the proof harness plays the host and writes the
    // signal back so a real pointer or keyboard action is visible here.
    onToggled: next => root.checked = next

    implicitWidth: Style.iconSm * 2 + Style.spaceTight * 2
    implicitHeight: Style.iconSm + Style.spaceTight * 2

    readonly property var controls: [
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ]}
    ]
}
