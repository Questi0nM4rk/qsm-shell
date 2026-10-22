import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool clickable: variant === "clickable"
    property bool required: true
    property bool iconShown: true
    property string caption: "Volume"
    property string size: "md"
    property int clicks: 0

    // The label wears the scale of the control it names: the same ratios the
    // text field and the slider hand it at their sm, md and lg.
    readonly property real labelScale: ({ sm: 0.8, md: 1, lg: 1.3 })[root.size] ?? 1

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: label.implicitHeight + Style.space4 * 2

    ControlLabel {
        id: label
        anchors.centerIn: parent
        text: root.caption
        accessibleName: root.caption !== "" ? root.caption : "Volume"
        icon: root.iconShown ? "volume" : ""
        required: root.required
        clickable: root.clickable
        sizeScale: root.labelScale
        onClicked: {
            root.clicks++
            root.eventRecorder?.("intent", "clicked", {})
        }
    }

    readonly property var controls: [
        { label: "interaction", options: [
            { label: "caption", set: { clickable: false } },
            { label: "clickable", set: { clickable: true } }
        ] },
        { label: "required", options: [
            { label: "yes", set: { required: true } },
            { label: "no", set: { required: false } }
        ] },
        { label: "icon", options: [
            { label: "shown", set: { iconShown: true } },
            { label: "none", set: { iconShown: false } }
        ] },
        { label: "text", options: [
            { label: "full", set: { caption: "Volume" } },
            { label: "empty", set: { caption: "" } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] }
    ]

    readonly property var integration: ({
        events: ["clicked"],
        actions: ["activate"],
        targets: ({ label: () => label }),
        observables: {
            clickable: () => label.clickable,
            required: () => label.required,
            "has-content": () => label.hasContent,
            "can-activate": () => label.actions[0].enabled,
            clicks: () => root.clicks,
            focused: () => label.activeFocus,
            "keyboard-focused": () => label.visualFocus,
            size: () => root.size
        },
        runAction: name => {
            if (name !== "activate")
                return false
            return label.activate()
        }
    })
}
