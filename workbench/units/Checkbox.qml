import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool checked: variant === "on"
    property bool indeterminate: variant === "some"

    implicitWidth: box.implicitWidth
    implicitHeight: box.implicitHeight

    Checkbox {
        id: box
        anchors.centerIn: parent
        checked: root.checked
        indeterminate: root.indeterminate
        accessibleName: boxLabel.text
        onToggleRequested: next => {
            root.checked = next
            root.eventRecorder?.("component", "toggle-requested", { checked: next })
        }

        Prose {
            id: boxLabel
            role: "label"
            text: "Include hidden files"
            color: box.enabled ? Style.text : Style.disabled(Style.text)
        }
    }

    readonly property var controls: [
        { label: "checked", options: [
            { label: "off", set: { checked: false, indeterminate: false } },
            { label: "on", set: { checked: true, indeterminate: false } },
            { label: "some", set: { checked: false, indeterminate: true } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["toggle-requested"],
        actions: ["toggle"],
        keys: {
            "Space": () => { box.flip(); return true },
            "Enter": () => { box.flip(); return true }
        },
        observables: {
            checked: () => root.checked,
            indeterminate: () => root.indeterminate
        },
        runAction: name => {
            if (name !== "toggle")
                return false
            box.flip()
            return true
        }
    })
}
