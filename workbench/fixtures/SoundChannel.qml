import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property real level: 50
    property bool muted: false
    property string channelIcon: "volume"
    property bool nodeEnabled: true
    property string size: "lg"
    property var scene: null
    property string nodeId: ""

    readonly property Item nativeTarget: slider
    readonly property var events: ["changed", "mute-changed"]
    readonly property var actionHandlers: ({
        "increase": () => slider.stepBy(Style.sliderKeyboardUnits),
        "decrease": () => slider.stepBy(-Style.sliderKeyboardUnits),
        "minimum": () => slider.toMinimum(),
        "maximum": () => slider.toMaximum(),
        "toggle-mute": () => root.toggleMute()
    })
    readonly property var actions: Object.keys(root.actionHandlers).map(name => ({
        text: name,
        trigger: root.actionHandlers[name]
    }))
    readonly property var controls: [
        { "label": "level", "options": [
            { "label": "minimum", "set": { "level": 0 } },
            { "label": "middle", "set": { "level": 50 } },
            { "label": "maximum", "set": { "level": 100 } }
        ] },
        { "label": "muted", "options": [
            { "label": "unmuted", "set": { "muted": false } },
            { "label": "muted", "set": { "muted": true } }
        ] },
        { "label": "availability", "options": [
            { "label": "enabled", "set": { "nodeEnabled": true } },
            { "label": "disabled", "set": { "nodeEnabled": false } }
        ] }
    ]
    readonly property var integration: ({
        events: root.events,
        actions: Object.keys(root.actionHandlers),
        targets: ({
            "slider": () => root.nativeTargetFor("slider"),
            "mute-label": () => root.nativeTargetFor("mute-label"),
            "scene": () => root.nativeTargetFor("scene")
        }),
        observables: {
            "level": () => root.level,
            "muted": () => root.muted,
            "enabled": () => slider.enabled,
            "orientation": () => slider.orientation === Qt.Vertical ? "vertical" : "horizontal",
            "wheel-units": () => slider.wheelUnits,
            "can-toggle-mute": () => slider.actions[4].enabled
        },
        runAction: name => {
            return Object.prototype.hasOwnProperty.call(root.actionHandlers, name)
                && root.actionHandlers[name]() === true
        },
        idle: () => true
    })

    function nativeTargetFor(name: string): var {
        if (name === "slider")
            return slider
        if (name === "mute-label")
            return slider.labelItem
        if (name === "scene")
            return root.scene
        return null
    }

    implicitWidth: slider.implicitWidth
    implicitHeight: slider.implicitHeight

    function toggleMute(): bool {
        return slider.activateLabel()
    }

    function onLabelClicked(): void {
        root.muted = !root.muted
        root.report("mute-changed", { "muted": root.muted })
    }

    function report(name: string, payload: var): void {
        if (root.scene)
            root.scene.recordNodeEvent(root.nodeId, name, payload, "component")
    }

    Slider {
        id: slider
        objectName: "soundChannelSlider"
        width: implicitWidth
        height: implicitHeight
        anchors.centerIn: parent
        enabled: root.nodeEnabled
        orientation: Qt.Vertical
        size: root.size
        raised: true
        wheelUnits: Style.sliderKeyboardUnits
        from: 0
        to: 100
        stepSize: 1
        value: root.level
        fill: root.muted ? Style.textMuted : Style.accent
        thumbColor: root.muted ? Style.textMuted : Style.text
        thumbContentColor: Style.textOnPrimary
        thumbText: root.muted ? "—" : String(Math.round(root.level))
        labelIcon: root.channelIcon
        labelAccessibleName: root.muted ? "Unmute output" : "Mute output"
        labelPosition: "below"
        labelClickable: true
        onLabelClicked: root.onLabelClicked()
        onMoved: {
            const wasMuted = root.muted
            root.level = slider.value
            root.muted = false
            root.report("changed", { "level": root.level })
            if (wasMuted)
                root.report("mute-changed", { "muted": false })
        }
        onCommitted: {}
    }
}
