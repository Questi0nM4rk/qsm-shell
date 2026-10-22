import QtQuick

import qs.QsmShell.Components

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property real maximum: 100
    property real value: variant === "decimal" ? 42.5 : 7
    property bool failed: false
    property bool editable: true
    property bool wrap: false
    property string size: "md"

    implicitWidth: spin.implicitWidth
    implicitHeight: spin.implicitHeight

    SpinBox {
        id: spin
        anchors.centerIn: parent
        from: 0
        to: root.maximum
        stepSize: 0.5
        decimals: 1
        size: root.size
        wrap: root.wrap
        editable: root.editable
        failed: root.failed
        value: root.value
        accessibleName: "Brightness"
        onValueModified: {
            root.value = spin.value
            root.eventRecorder?.("intent", "value-modified", { value: root.value })
        }
    }

    // The field's own state layer, which owns the focus ring, and its editor.
    readonly property var ringLayer: spin.children.find(child => child.objectName === "spinBoxLayer")
    readonly property var editor: spin.contentItem.children.find(child => child.objectName === "spinBoxInput")

    readonly property var controls: [
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "value", options: [
            { label: "min", set: { maximum: 100, value: 0 } },
            { label: "middle", set: { maximum: 100, value: 50 } },
            { label: "max", set: { maximum: 100, value: 100 } },
            { label: "long", set: { maximum: 1000000, value: 123456.7 } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] },
        { label: "failed", options: [
            { label: "off", set: { failed: false } },
            { label: "on", set: { failed: true } }
        ] },
        // Off, the text is not typed into and Home and End reach the bounds;
        // the steppers, the wheel and the arrow keys still work.
        { label: "typing", options: [
            { label: "on", set: { editable: true } },
            { label: "off", set: { editable: false } }
        ] },
        { label: "wrap", options: [
            { label: "off", set: { wrap: false } },
            { label: "on", set: { wrap: true } }
        ] }
    ]
    readonly property var integration: ({
        events: ["value-modified"],
        actions: ["increase", "decrease", "minimum", "maximum"],
        targets: ({
            spinbox: () => spin,
            increase: () => spin.up.indicator,
            decrease: () => spin.down.indicator
        }),
        observables: {
            value: () => root.value,
            size: () => root.size,
            "acceptable-input": () => spin.acceptableInput,
            // What the person reads in the field, and whether the keyboard ring
            // is showing: a click focuses the field and must not ring it.
            text: () => spin.displayText,
            // What is typed in the field right now, accepted or not.
            "typed-text": () => root.editor.text,
            focused: () => spin.focused,
            "focus-ring": () => root.ringLayer.focused && !root.ringLayer._pointerFocus,
            "can-increase": () => spin.actions[0].enabled,
            "can-decrease": () => spin.actions[1].enabled
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
