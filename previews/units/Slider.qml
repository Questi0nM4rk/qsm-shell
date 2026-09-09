pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// THE slider, wearing its two former surface names as VARIANTS instead of two
// types. `level` and `osd-slider` differed in orientation, thickness and
// decoration and nothing else.
//
// The unit is a HOST rather than the bare control, because the one thing a
// slider cannot show about itself is the difference between the value it is
// painting and the value a finished gesture left behind. The readout below is
// that, live: `value` moves under the finger, `committed` only on release.
// Everything a control group writes is aliased onto this root, so the strip
// still writes flat properties and lands on the slider.
//
// The unit does not play host to `value`: Qt's own C++ setter writes it,
// through the binding rather than over it, so the drag, the wheel and every
// arrow key work with no wiring here.
Column {
    id: root
    property string variant: ""

    // "vertical-*" is the raised, decorated look the OSD volume popup used;
    // anything else is the plain horizontal reading rail. `decorated` is its
    // own axis: the `orientation` control can flip a plain rail vertical
    // without dragging the raised look along with it.
    readonly property bool decorated: variant.indexOf("vertical") === 0

    // Every property a control group names, on the root the strip writes to.
    // The bindings below are the defaults; a strip write replaces one, which
    // is what a control strip is for.
    property alias orientation: slider.orientation
    property alias raised: slider.raised
    property alias wheelUnits: slider.wheelUnits
    property alias size: slider.size
    // The component's own enumeration of what it can do. `tests/units`
    // triggers a unit's actions, and a wrapper that does not hand them up
    // takes the slider's four out of that walk without saying so.
    readonly property alias actions: slider.actions

    // One glyph, in either end slot. Which end is the consumer's business, so
    // it is a property here rather than a second unit.
    property bool showGlyph: true
    property string glyphPosition: "end"
    // The reading inside the thumb, which only has room for it once the thumb
    // is a control-height one.
    property bool showThumbContent: root.decorated

    spacing: Style.space2

    Slider {
        id: slider
        anchors.horizontalCenter: parent.horizontalCenter

        orientation: root.decorated ? Qt.Vertical : Qt.Horizontal
        value: root.variant.indexOf("high") >= 0 ? .82 : .42
        wheelUnits: Style.sliderKeyboardUnits
        raised: root.decorated

        // Both slots are real and both are Loaders, so the slot the glyph is
        // not in reserves nothing -- a bare slider looks exactly like a bare
        // slider.
        before: Loader {
            active: root.showGlyph && root.glyphPosition === "start"
            sourceComponent: root.decorated ? glyphAction : glyphIcon
        }

        after: Loader {
            active: root.showGlyph && root.glyphPosition === "end"
            sourceComponent: root.decorated ? glyphAction : glyphIcon
        }

        // The readout is sized to the THUMB minus one step of breathing room
        // per side and fits itself into that box, because the thumb is a
        // property of the call site: at `sm` the same two digits overflowed a
        // 12px thumb by 4.7px and `anchors.centerIn` spilled them
        // symmetrically over the track.
        thumbContent: Loader {
            anchors.centerIn: parent
            width: parent.width - Style.space1 * 2
            height: parent.height - Style.space1 * 2
            active: root.showThumbContent
            sourceComponent: Text {
                text: Math.round(slider.value * 100)
                color: Style.background
                font.family: Style.fontFamily
                font.pixelSize: Style.textSm
                font.weight: Style.weightBold
                fontSizeMode: Text.Fit
                minimumPixelSize: Style.textXs
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // The OSD's fat track and big thumb, STATED rather than derived. It is an
    // override a call site makes, and a `Binding` states one without the
    // plain rail having to name a preset value it would then have to keep in
    // sync with the component. Clicking `size` on this variant changes
    // nothing, which is the point: an override wins over a preset.
    Binding {
        target: slider
        property: "thickness"
        value: Style.controlHeight
        when: root.decorated
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: slider
        property: "thumbSize"
        value: Style.controlHeight
        when: root.decorated
        restoreMode: Binding.RestoreBindingOrValue
    }

    // What the host sees. `value` follows the drag frame by frame because it
    // binds to it; `committed` only moves when a gesture ends, which is the
    // whole point of having both.
    Prose {
        anchors.horizontalCenter: parent.horizontalCenter
        role: "metadata"
        text: `value: ${slider.value.toFixed(2)}  committed: ${slider.committedValue.toFixed(2)}`
    }

    Component {
        id: glyphIcon
        SvgIcon {
            name: "volume"
            size: Style.iconMd
            // Slot content is the HOST's, including what it does while the
            // control is unavailable: the component dims its own layers by
            // colour and never by opacity, so nothing dims a glyph for us.
            color: slider.enabled ? Style.textMuted : Style.disabled(Style.textMuted)
        }
    }

    Component {
        id: glyphAction
        // The OSD's volume button, and it does something: a mute that takes
        // the level to the bottom, and back to the top from there. It calls
        // the component's own routes -- the same ones the keys take -- rather
        // than synthesizing a pointer, and an IconButton with no action is a
        // dead control in the live window.
        IconButton {
            icon: "volume"
            size: Style.iconMd
            padding: Style.space2
            onClicked: slider.value > slider.from ? slider.toMinimum() : slider.toMaximum()
        }
    }

    // States a pointer or keyboard can already reach (hover, press, focus)
    // must never be faked as options. Only property-only states belong here.
    readonly property var controls: [
        { label: "orientation", options: [
            { label: "horizontal", set: { orientation: Qt.Horizontal } },
            { label: "vertical",   set: { orientation: Qt.Vertical } }
        ]},
        // One property, three shapes: the component owns which numbers each
        // size means, so the strip names the size and nothing else.
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ]},
        { label: "glyph", options: [
            { label: "on",  set: { showGlyph: true } },
            { label: "off", set: { showGlyph: false } }
        ]},
        // `before` is the high end, which reads as the top once the slider is
        // vertical, so the options say where the glyph actually sits.
        { label: "glyph position", options: [
            { label: slider.vertical ? "top" : "start", set: { glyphPosition: "start" } },
            { label: slider.vertical ? "bottom" : "end", set: { glyphPosition: "end" } }
        ]},
        { label: "thumb content", options: [
            { label: "on",  set: { showThumbContent: true } },
            { label: "off", set: { showThumbContent: false } }
        ]},
        { label: "shape", options: [
            { label: "flat",   set: { raised: false } },
            { label: "raised", set: { raised: true } }
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
