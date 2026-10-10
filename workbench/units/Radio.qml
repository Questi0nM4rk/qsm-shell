import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool checked: variant !== "off"

    implicitWidth: option.implicitWidth
    implicitHeight: option.implicitHeight

    Radio {
        id: option
        anchors.centerIn: parent
        checked: root.checked
        accessibleName: optionLabel.text
        onSelectionRequested: {
            root.checked = true
            root.eventRecorder?.("intent", "selection-requested", {})
        }

        Prose {
            id: optionLabel
            role: "label"
            text: "Match window size"
            color: option.enabled ? Style.text : Style.disabled(Style.text)
        }
    }

    readonly property var controls: [
        { label: "checked", options: [
            { label: "on", set: { checked: true } },
            { label: "off", set: { checked: false } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["selection-requested"],
        actions: ["select"],
        keys: {
            "Space": () => { option.select(); return true },
            "Enter": () => { option.select(); return true }
        },
        observables: { checked: () => root.checked },
        runAction: name => {
            if (name !== "select")
                return false
            option.select()
            return true
        }
    })
}
