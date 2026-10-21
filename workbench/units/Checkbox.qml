import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool checked: variant === "on"
    property bool indeterminate: variant === "some"
    property string size: "md"
    property string labelLength: "short"

    implicitWidth: box.implicitWidth
    implicitHeight: box.implicitHeight

    Checkbox {
        id: box
        anchors.centerIn: parent
        size: root.size
        checked: root.checked
        indeterminate: root.indeterminate
        accessibleName: boxLabel.text
        onToggleRequested: next => {
            root.checked = next
            root.eventRecorder?.("intent", "toggle-requested", { checked: next })
        }

        Prose {
            id: boxLabel
            role: "label"
            width: parent.width
            text: root.labelLength === "long"
                ? "Include hidden files, files whose names start with a dot, and everything inside folders that are themselves hidden from the listing"
                : "Include hidden files"
            color: box.enabled ? Style.text : Style.disabled(Style.text)
        }
    }

    readonly property var controls: [
        { label: "checked", options: [
            { label: "off", set: { checked: false, indeterminate: false } },
            { label: "on", set: { checked: true, indeterminate: false } },
            { label: "some", set: { checked: false, indeterminate: true } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "label", options: [
            { label: "short", set: { labelLength: "short" } },
            { label: "long", set: { labelLength: "long" } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["toggle-requested"],
        actions: ["toggle"],
        targets: ({ checkbox: () => box }),
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
