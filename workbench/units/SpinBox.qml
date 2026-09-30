import QtQuick

import qs.QsmShell.Components

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property real value: variant === "decimal" ? 42.5 : 7
    property bool failed: false
    property bool editable: true
    property bool wrap: false

    implicitWidth: spin.implicitWidth
    implicitHeight: spin.implicitHeight

    SpinBox {
        id: spin
        anchors.centerIn: parent
        from: 0
        to: 100
        stepSize: 0.5
        decimals: 1
        wrap: root.wrap
        editable: root.editable
        failed: root.failed
        value: root.value
        accessibleName: "Brightness"
        onValueModified: {
            root.value = spin.value
            root.eventRecorder?.("component", "value-modified", { value: root.value })
        }
    }

    readonly property var controls: [
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] },
        { label: "failed", options: [
            { label: "off", set: { failed: false } },
            { label: "on", set: { failed: true } }
        ] },
        { label: "editable", options: [
            { label: "editable", set: { editable: true } },
            { label: "read-only", set: { editable: false } }
        ] },
        { label: "wrap", options: [
            { label: "off", set: { wrap: false } },
            { label: "on", set: { wrap: true } }
        ] }
    ]
    readonly property var integration: ({
        events: ["value-modified"],
        actions: ["increase", "decrease", "minimum", "maximum"],
        observables: {
            value: () => root.value,
            "acceptable-input": () => spin.acceptableInput
        },
        runAction: name => {
            if (name === "increase")
                return spin.stepUp()
            if (name === "decrease")
                return spin.stepDown()
            if (name === "minimum")
                return spin.toMinimum()
            if (name === "maximum")
                return spin.toMaximum()
            return false
        }
    })
}
