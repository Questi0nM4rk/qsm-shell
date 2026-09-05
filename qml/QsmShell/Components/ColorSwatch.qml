pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Style

// A colour, shown as itself, with its value readable.
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
    // Shown on the swatch. Empty draws the sample alone.
    property string reading: ""
    property real size: Style.controlHeight
    property bool selected: false
    property bool focused: root.activeFocus

    signal clicked

    // Relative luminance, the same weighting contrast ratios use. A swatch
    // decides its own ink so no call site has to.
    readonly property color ink: (0.2126 * sample.r + 0.7152 * sample.g + 0.0722 * sample.b) > 0.5
        ? Style.background
        : Style.text

    implicitWidth: size
    implicitHeight: size
    radius: Style.radiusSm
    // Transparent, because the sample is painted INSIDE, over the alpha check.
    // A Rectangle fills behind all of its children, so a check drawn as a
    // child of the sample would cover the very thing it is there to reveal.
    color: "transparent"
    clip: true

    // Selection is a ring OUTSIDE the fill, because a mark drawn on top of the
    // sample changes the thing being sampled.
    border.width: root.selected ? Style.markThickness - 1 : 0
    border.color: Style.accent

    Behavior on border.width {
        NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    // The alpha check, first, so a translucent sample composites over it.
    // Without it a 20%-alpha colour reads as a different opaque colour, which
    // is the one confusion a colour tool must not create.
    Item {
        anchors.fill: parent
        visible: root.sample.a < 1

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
        color: root.sample
    }

    Prose {
        anchors.centerIn: parent
        visible: root.reading.length > 0
        role: "reading"
        font.pixelSize: Style.textXs
        color: root.ink
        text: root.reading
    }

    StateLayer {
        anchors.fill: parent
        focused: root.focused
        focusRadius: root.radius
        hoverScale: 1.08
        pressScale: 0.94
        onClicked: root.clicked()
    }
}
