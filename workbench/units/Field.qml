import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property string hint: "Follow the light around the room."
    property string error: ""
    property bool required: true
    property string size: "md"
    property bool toggled: true
    property int toggles: 0

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlHeightLg + Style.space6 * 2

    Field {
        id: field

        width: root.width
        label: "Night light"
        hint: root.hint
        error: root.error
        required: root.required
        sizeScale: switcher.sizeScale

        Switch {
            id: switcher
            size: root.size
            checked: root.toggled
            Accessible.name: field.accessibleName
            Accessible.description: field.accessibleDescription

            onToggleRequested: checked => {
                root.toggled = checked
                root.toggles++
                root.eventRecorder?.("intent", "toggle-requested", { checked })
            }
        }
    }

    readonly property var controls: [
        { label: "validation", options: [
            { label: "ok", set: { error: "" } },
            { label: "failed", set: { error: "Pick a profile the shell can read." } }
        ] },
        { label: "hint", options: [
            { label: "shown", set: { hint: "Follow the light around the room." } },
            { label: "none", set: { hint: "" } }
        ] },
        { label: "required", options: [
            { label: "yes", set: { required: true } },
            { label: "no", set: { required: false } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] }
    ]

    readonly property var integration: ({
        events: ["toggle-requested"],
        actions: ["toggle"],
        observables: {
            failed: () => field.failed,
            toggled: () => switcher.checked,
            toggles: () => root.toggles,
            label: () => field.label,
            "accessibility-name": () => switcher.Accessible.name,
            "accessibility-description": () => switcher.Accessible.description,
            required: () => field.required,
            error: () => field.error,
            hint: () => field.hint
        },
        runAction: name => {
            if (name === "toggle") { switcher.flip(); return true }
            return false
        },
        keys: {
            "Enter": () => { switcher.flip(); return true }
        }
    })
}
