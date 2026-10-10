import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool ods: variant === "vertical-high"
    property real value: ods ? 72 : 87
    property real lowValue: 0
    property bool range: false
    property string size: "lg"
    property string thumbStyle: "circle"
    property int wheelUnits: 0
    property bool labelClickable: false
    property bool muted: false
    readonly property var actionHandlers: ({
        increase: () => slider.stepBy(Style.sliderKeyboardUnits),
        decrease: () => slider.stepBy(-Style.sliderKeyboardUnits),
        minimum: () => slider.toMinimum(),
        maximum: () => slider.toMaximum(),
        "activate-label": () => slider.activateLabel()
    })

    implicitWidth: Style.sliderLength + Style.space6 * 2
    implicitHeight: ods
        ? Style.sliderLengthVertical + Style.space6 * 2
        : Style.controlHeightLg + Style.space6 * 2

    Slider {
        id: slider
        anchors.centerIn: parent
        orientation: root.ods ? Qt.Vertical : Qt.Horizontal
        from: 0
        to: 100
        stepSize: 1
        value: root.value
        lowValue: root.lowValue
        range: root.range
        size: root.size
        thumbStyle: root.thumbStyle
        raised: true
        wheelUnits: root.wheelUnits
        labelPosition: root.ods ? "above" : "left"
        labelText: "Output"
        labelClickable: root.labelClickable
        labelIcon: "volume"
        labelAccessibleName: root.muted ? "Unmute output" : "Mute output"
        thumbIcon: "volume"
        thumbText: ""
        fill: root.muted ? Style.textMuted : Style.accent
        thumbColor: root.muted ? Style.textMuted : Style.text

        onLabelClicked: {
            root.muted = !root.muted
            root.eventRecorder?.("intent", "mute-changed", { muted: root.muted })
        }

        onMoved: {
            root.value = slider.value
            root.lowValue = slider.lowValue
            root.eventRecorder?.("intent", "moved", { value: slider.value })
        }
        onCommitted: root.eventRecorder?.("intent", "committed",
            { value: slider.committedValue, "low-value": slider.committedLowValue })
    }

    readonly property var controls: [
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] },
        { label: "range", options: [
            { label: "single", set: { range: false } },
            { label: "range", set: { range: true } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "thumb", options: [
            { label: "circle", set: { thumbStyle: "circle" } },
            { label: "pill", set: { thumbStyle: "pill" } }
        ] },
        { label: "wheel", options: [
            { label: "off", set: { wheelUnits: 0 } },
            { label: "nudge", set: { wheelUnits: 1 } }
        ] },
        { label: "label", options: [
            { label: "caption", set: { labelClickable: false } },
            { label: "action", set: { labelClickable: true } }
        ] },
        { label: "mute", options: [
            { label: "unmuted", set: { muted: false } },
            { label: "muted", set: { muted: true } }
        ] }
    ]

    readonly property var integration: ({
        events: ["moved", "committed", "mute-changed"],
        actions: ["increase", "decrease", "minimum", "maximum", "activate-label"],
        targets: ({ slider: () => slider, label: () => slider.labelItem }),
        observables: {
            value: () => slider.value,
            "low-value": () => slider.lowValue,
            range: () => slider.range,
            size: () => slider.size,
            orientation: () => slider.orientation === Qt.Vertical ? "vertical" : "horizontal",
            "thumb-icon": () => slider.thumbIcon,
            "label-position": () => slider.labelPosition,
            "thumb-style": () => slider.thumbStyle,
            "wheel-units": () => slider.wheelUnits,
            "label-clickable": () => slider.labelClickable,
            muted: () => root.muted,
            "can-increase": () => slider.actions[0].enabled,
            "can-decrease": () => slider.actions[1].enabled,
            "can-activate-label": () => slider.actions[4].enabled
        },
        runAction: name => {
            return Object.prototype.hasOwnProperty.call(root.actionHandlers, name)
                ? root.actionHandlers[name]() : false;
        }
    })
}
