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
    property int clicks: 0

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
            clicks: () => root.clicks
        },
        runAction: name => {
            if (name !== "activate")
                return false
            return label.activate()
        }
    })
}
