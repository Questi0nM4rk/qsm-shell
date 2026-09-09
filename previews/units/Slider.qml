pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// THE slider, wearing its two former surface names as VARIANTS instead of two
// types. `level` and `osd-slider` differed in orientation, thickness and
// decoration and nothing else.
//
// This unit no longer plays host. Every type that hands its state upward needs
// a unit that answers, or the live window shows a control that ignores the
// pointer -- but `Slider` no longer hands `value` up: Qt's own C++ setter
// writes it, through the binding below rather than over it, so the drag, the
// wheel and every arrow key work with no wiring here.
Slider {
    id: root
    property string variant: ""

    // "vertical-*" is the raised, decorated look the OSD volume popup used;
    // anything else is the plain horizontal reading rail. `root.vertical` is
    // the template's own derived property -- redeclaring it here would shadow
    // it. `decorated` is its own axis: the `orientation` control can flip a
    // plain rail vertical without dragging the raised look along with it.
    readonly property bool decorated: variant.indexOf("vertical") === 0

    orientation: root.decorated ? Qt.Vertical : Qt.Horizontal
    value: variant.indexOf("high") >= 0 ? .82 : .42
    wheelUnits: root.decorated ? 0 : Style.sliderKeyboardUnits
    raised: root.decorated
    // The OSD's fat track and big thumb, from the control scale rather than
    // the literals 40 and 32 this file used to type.
    thickness: root.decorated ? Style.controlHeight : Style.sliderTrackThickness
    thumbSize: root.decorated ? Style.controlHeightSm : Style.sliderThumbSize
    trackColor: root.decorated ? Qt.darker(Style.surface, 1.35) : Style.surfaceHover

    // Both slots are real, loaded only for the decorated look -- an inactive
    // Loader has no content, so the plain rail reserves no padding for either.
    thumbContent: Loader {
        anchors.centerIn: parent
        active: root.decorated
        sourceComponent: Text {
            text: Math.round(root.value * 100)
            color: Style.background
            font.family: Style.fontFamily
            font.pixelSize: Style.textSm
            font.weight: Style.weightBold
        }
    }

    after: Loader {
        active: root.decorated
        sourceComponent: IconButton {
            icon: "volume"
            size: Style.iconMd
            padding: Style.space2
        }
    }

    readonly property var controls: [
        { label: "orientation", options: [
            { label: "horizontal", set: { orientation: Qt.Horizontal } },
            { label: "vertical",   set: { orientation: Qt.Vertical } }
        ]},
        { label: "state", options: [
            { label: "enabled",  set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ]},
        { label: "shape", options: [
            { label: "flat",   set: { raised: false } },
            { label: "raised", set: { raised: true } }
        ]},
        { label: "wheel", options: [
            { label: "off",   set: { wheelUnits: 0 } },
            { label: "5 units", set: { wheelUnits: Style.sliderKeyboardUnits } }
        ]}
    ]
}
