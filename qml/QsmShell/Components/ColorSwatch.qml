pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Style

// A colour slot: the colour shown as itself with its value readable, or the
// empty state when there is no colour in it yet.
//
// Three surfaces in the consuming shell drew this by hand — the picker's
// history, the theme cards, the palette sheet — and each answered "is this
// swatch light or dark?" differently, so the hex on a pale swatch was
// unreadable in one of them. Contrast against the sample is not a style
// choice; it is the difference between a swatch and a coloured square.
//
// The checkerboard under a translucent colour is not decoration either: a
// 20%-alpha swatch over the shell's own surface looks like a different opaque
// colour, which is exactly the confusion a colour tool must not create.
Rectangle {
    id: root

    required property color sample
    // No colour in this slot YET, which is not the same as a transparent
    // colour: transparent is a real sample and gets the alpha check, while an
    // empty slot has nothing to show and says so with an outline. A picker's
    // "click here to sample something" square is the case. `sample` stays
    // required so a typo in a binding is still caught — an empty slot passes
    // "transparent" and this flag, which says what it means out loud.
    property bool empty: false
    // Shown on the swatch. Empty draws the sample alone.
    property string reading: ""
    property real size: Style.controlHeight
    property bool selected: false
    property bool focused: root.activeFocus

    signal clicked

    // The swatch decides its own ink so no call site has to, and it decides it
    // by MEASURING rather than by assuming the theme is dark. The first
    // version returned `Style.background` for a pale sample and `Style.text`
    // for a dark one, which is only right while background is the dark one —
    // under a light backend it hands a pale swatch pale ink.
    //
    // The sample is composited over the surface first: a 20%-alpha colour is
    // not the colour you would measure, and reading the raw value picks ink
    // for a swatch nobody can see.
    readonly property color _seen: Qt.rgba(
        sample.r * sample.a + Style.surface.r * (1 - sample.a),
        sample.g * sample.a + Style.surface.g * (1 - sample.a),
        sample.b * sample.a + Style.surface.b * (1 - sample.a),
        1)

    // WCAG relative luminance: sRGB has to be linearised first, and skipping
    // that is why mid-tones get the wrong answer.
    function _luminance(channel: real): real {
        return channel <= 0.03928 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4);
    }
    function _relative(sampled: color): real {
        return 0.2126 * _luminance(sampled.r)
            + 0.7152 * _luminance(sampled.g)
            + 0.0722 * _luminance(sampled.b);
    }
    function _contrast(a: color, b: color): real {
        const la = root._relative(a);
        const lb = root._relative(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

    // Whichever of the theme's two inks actually reads on this sample.
    readonly property color ink: _contrast(_seen, Style.text) >= _contrast(_seen, Style.background)
        ? Style.text
        : Style.background

    implicitWidth: size
    implicitHeight: size
    opacity: enabled ? 1 : Style.opacityDisabled
    radius: Style.radiusSm
    // Transparent, because the sample is painted INSIDE, over the alpha check.
    // A Rectangle fills behind all of its children, so a check drawn as a
    // child of the sample would cover the very thing it is there to reveal.
    color: "transparent"
    clip: true


    // The alpha check, first, so a translucent sample composites over it.
    // Without it a 20%-alpha colour reads as a different opaque colour, which
    // is the one confusion a colour tool must not create.
    Item {
        anchors.fill: parent
        visible: !root.empty && root.sample.a < 1

        Repeater {
            model: 16

            delegate: Rectangle {
                required property int index
                width: root.width / 4
                height: root.height / 4
                x: (index % 4) * width
                y: Math.floor(index / 4) * height
                color: (index + Math.floor(index / 4)) % 2 === 0 ? "#ffffff" : "#c0c0c0"
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.empty
        color: root.sample
    }

    // The empty slot: an outline and nothing else. Not a dashed border and not
    // a plus glyph — both announce an action, and the slot is a place, with
    // the action stated by whatever put it there.
    Rectangle {
        anchors.fill: parent
        visible: root.empty
        color: "transparent"
        radius: root.radius
        border.width: 1
        border.color: Style.outline
    }

    // The selection ring is drawn LAST, over the sample.
    //
    // It used to be the root's own `border`, which a Rectangle paints behind
    // its children — so the opaque sample filling the root covered it, and
    // `clip: true` finished the job. The advertised ring was never once
    // visible. It is still a ring rather than a mark ON the swatch, because a
    // mark drawn on top changes the thing being sampled.
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: root.radius
        border.width: root.selected ? Style.markThickness - 1 : 0
        border.color: Style.accent

        Behavior on border.width {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }

    Prose {
        anchors.centerIn: parent
        visible: !root.empty && root.reading.length > 0
        role: "reading"
        font.pixelSize: Style.textXs
        color: root.ink
        text: root.reading
    }

    StateLayer {
        anchors.fill: parent
        interactive: root.enabled
        focused: root.focused
        focusRadius: root.radius
        hoverScale: 1.08
        pressScale: 0.94
        onClicked: root.clicked()
    }

    Keys.onSpacePressed: if (root.enabled) root.clicked()
    Keys.onReturnPressed: if (root.enabled) root.clicked()
}
