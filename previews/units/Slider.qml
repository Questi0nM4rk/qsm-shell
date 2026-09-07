import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// THE slider, wearing its two former surface names as VARIANTS instead of
// two types. "level" and "osd-slider" differed in orientation, thickness,
// decoration and nothing else -- one type, `variant` picks the look.
Slider {
    id: root
    property string variant: ""

    // "vertical-*" is the raised, decorated look the OSD volume popup used;
    // anything else is the plain horizontal reading rail. `root.vertical` is
    // the base component's own derived property (from `orientation`), not a
    // second one -- redeclaring it here would shadow it. `decorated` is its
    // own axis: the `orientation` control can flip a plain rail vertical
    // without dragging the raised/thumbContent/after look along with it.
    readonly property bool decorated: variant.indexOf("vertical") === 0

    orientation: root.decorated ? Qt.Vertical : Qt.Horizontal
    value: variant.indexOf("high") >= 0 ? .82 : .42
    // `Slider` emits `moved` and never writes its own value -- the HOST owns
    // it. A preview unit therefore has to BE the host, or the live window
    // shows a control that answers no drag, no wheel and no arrow key. Every
    // type that hands its state upward needs this line.
    onMoved: v => root.value = v
    wheelStep: root.decorated ? 0 : .05
    raised: root.decorated
    thickness: root.decorated ? 40 : Style.sliderTrackThickness
    thumbSize: root.decorated ? 32 : Style.sliderThumbSize
    trackColor: root.decorated ? Qt.darker(Style.surface, 1.35) : Style.surfaceHover

    implicitWidth: root.vertical ? Math.max(thickness, thumbSize) : 260
    implicitHeight: root.vertical ? 180 : Math.max(thickness, thumbSize)

    // Both slots are real, loaded only for the decorated look -- an inactive
    // Loader has no size, so the plain rail reserves no space for either.
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
        { label: "thumb", options: [
            { label: "shown",  set: { showThumb: true } },
            { label: "hidden", set: { showThumb: false } }
        ]}
    ]
}
