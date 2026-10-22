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
    property bool grab: ods
    property bool reading: false
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
        : Style.size("Control", "lg") + Style.space6 * 2

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
        grabThumb: root.grab
        wheelUnits: root.wheelUnits
        labelPosition: root.ods ? "above" : "left"
        labelText: "Output"
        labelClickable: root.labelClickable
        labelIcon: "volume"
        labelAccessibleName: root.muted ? "Unmute output" : "Mute output"
        thumbIcon: root.reading ? "" : "volume"
        thumbText: root.reading ? String(Math.round(root.value)) : ""
        fill: root.muted ? Style.textMuted : Style.primary
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
        { label: "value", options: [
            { label: "first", set: { value: 0 } },
            { label: "middle", set: { value: 50 } },
            { label: "last", set: { value: 100 } }
        ] },
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
        // A press on the thumb either jumps the value to the pointer or grabs
        // the thumb and moves nothing until the pointer does.
        { label: "press", options: [
            { label: "jump", set: { grab: false } },
            { label: "grab", set: { grab: true } }
        ] },
        // What the thumb carries: the channel's glyph at rest, or the reading
        // while it is being changed.
        { label: "content", options: [
            { label: "glyph", set: { reading: false } },
            { label: "reading", set: { reading: true } }
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
        // Idle once the painted thumbs have reached the values: a host write
        // glides in, and a press aimed at a thumb still on its way lands
        // wherever it has got to.
        idle: () => slider._paintedHigh === slider.second.visualPosition
            && slider._paintedLow === slider.first.visualPosition,
        events: ["moved", "committed", "mute-changed"],
        actions: ["increase", "decrease", "minimum", "maximum", "activate-label"],
        targets: ({
            slider: () => slider,
            track: () => slider.contentItem,
            thumb: () => slider.second.handle,
            "low-thumb": () => slider.first.handle,
            label: () => slider.labelItem
        }),
        observables: {
            value: () => slider.value,
            "low-value": () => slider.lowValue,
            range: () => slider.range,
            size: () => slider.size,
            orientation: () => slider.orientation === Qt.Vertical ? "vertical" : "horizontal",
            "thumb-icon": () => slider.thumbIcon,
            "thumb-text": () => slider.thumbText,
            "thumb-hovered": () => slider.second.hovered,
            "label-position": () => slider.labelPosition,
            "thumb-style": () => slider.thumbStyle,
            "wheel-units": () => slider.wheelUnits,
            "grab-thumb": () => slider.grabThumb,
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
