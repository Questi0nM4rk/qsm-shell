pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// THE slider, wearing its two former surface names as VARIANTS: `level` is
// the everyday horizontal rail, `osd-slider` is the vertical hardware level.
//
// The unit is a HOST rather than the bare control, because the one thing a
// slider cannot show about itself is the difference between the value it is
// painting and the value a finished gesture left behind. The readout below
// is that, live. Everything a control group writes is aliased onto this
// root, so the strip writes flat properties and lands on the slider.
//
// The unit does not play host to `value`: Qt's own C++ setter writes it
// through the binding rather than over it, so the drag, the wheel and every
// arrow key work with no wiring here.
Column {
    id: root
    property string variant: ""

    readonly property bool osd: variant.indexOf("vertical") === 0

    property alias orientation: slider.orientation
    property alias size: slider.size
    property alias thumbStyle: slider.thumbStyle
    property alias raised: slider.raised
    property alias wheelUnits: slider.wheelUnits
    property alias thumbIcon: slider.thumbIcon
    property alias thumbText: slider.thumbText
    property alias labelText: slider.labelText
    property alias labelIcon: slider.labelIcon
    property alias labelPosition: slider.labelPosition
    property alias fill: slider.fill
    property alias thumbColor: slider.thumbColor
    readonly property alias actions: slider.actions

    property alias labelClickable: slider.labelClickable
    property alias range: slider.range
    property alias lowValue: slider.lowValue

    spacing: Style.space2

    Slider {
        id: slider
        anchors.horizontalCenter: parent.horizontalCenter

        orientation: root.osd ? Qt.Vertical : Qt.Horizontal
        size: root.osd ? "lg" : "md"
        // Flat by default, OSD included: the 2px shadow drop read as a thumb
        // floating above its bar (owner, live window); `shape: raised` is a
        // control for hosts that want the lift.
        raised: false
        value: root.variant.indexOf("high") >= 0 ? .82 : .42
        wheelUnits: Style.sliderKeyboardUnits
        thumbIcon: root.osd ? "volume" : ""
        thumbText: root.osd ? "" : ""
        labelText: "Volume"
        // A glyph in the default scene too, not only OSD, so the label's
        // own scaling (icon + text together) is visible at rest.
        labelIcon: "volume"

        // The host maps the label's click: here a mute that takes the level
        // to the bottom and back to the top from there, through the
        // component's own routes.
        onLabelClicked: slider.value > slider.from ? slider.toMinimum() : slider.toMaximum()
    }

    Prose {
        anchors.horizontalCenter: parent.horizontalCenter
        role: "metadata"
        text: (slider.range ? `low: ${slider.lowValue.toFixed(2)}  ` : "")
            + `value: ${slider.value.toFixed(2)}  committed: ${slider.committedValue.toFixed(2)}`
    }

    // States a pointer or keyboard can already reach (hover, press, focus)
    // are never options. Only property-only states belong here.
    readonly property var controls: [
        { label: "orientation", options: [
            { label: "horizontal", set: { orientation: Qt.Horizontal } },
            { label: "vertical",   set: { orientation: Qt.Vertical } }
        ]},
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } },
            // Not in the default table -- previews/theme.json's consumer
            // backend adds it, proving a consumer preset name resolves.
            { label: "xl", set: { size: "xl" } }
        ]},
        { label: "range", options: [
            { label: "off", set: { range: false, lowValue: 0 } },
            { label: "on",  set: { range: true, lowValue: .2 } }
        ]},
        { label: "thumb", options: [
            { label: "circle", set: { thumbStyle: "circle" } },
            { label: "pill",   set: { thumbStyle: "pill" } }
        ]},
        { label: "thumb content", options: [
            { label: "none",  set: { thumbIcon: "", thumbText: "" } },
            { label: "glyph", set: { thumbIcon: "volume", thumbText: "" } },
            { label: "text",  set: { thumbIcon: "", thumbText: "82" } }
        ]},
        { label: "label", options: [
            { label: "none",  set: { labelText: "", labelIcon: "" } },
            { label: "text",  set: { labelText: "Volume", labelIcon: "" } },
            { label: "glyph", set: { labelText: "", labelIcon: "volume" } },
            { label: "both",  set: { labelText: "Volume", labelIcon: "volume" } }
        ]},
        { label: "label position", options: [
            { label: "above", set: { labelPosition: "above" } },
            { label: "below", set: { labelPosition: "below" } },
            { label: "left",  set: { labelPosition: "left" } },
            { label: "right", set: { labelPosition: "right" } }
        ]},
        { label: "colour", options: [
            { label: "accent",  set: { fill: Style.accent, thumbColor: Style.text } },
            { label: "danger",  set: { fill: Style.danger, thumbColor: Style.danger } },
            { label: "success", set: { fill: Style.success, thumbColor: Style.text } }
        ]},
        { label: "shape", options: [
            { label: "flat",   set: { raised: false } },
            { label: "raised", set: { raised: true } }
        ]},
        { label: "label action", options: [
            { label: "off", set: { labelClickable: false } },
            { label: "on",  set: { labelClickable: true } }
        ]},
        { label: "wheel", options: [
            { label: "off",     set: { wheelUnits: 0 } },
            { label: "5 units", set: { wheelUnits: Style.sliderKeyboardUnits } }
        ]},
        { label: "state", options: [
            { label: "enabled",  set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ]}
    ]
}
