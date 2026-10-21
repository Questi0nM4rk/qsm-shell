pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Templates as T

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
//
// The painted FACE stays compact (`size`, what the callers chose) and is
// centred in a TARGET that never drops below the Blueprint's floor, so a
// 24px sample in a palette row still answers on a full target without its
// hit zone overlapping a sibling's. Selection and focus belong to the face;
// the target itself paints nothing.
// NOT clipped. `clip` here shaved the StateLayer's hover growth back to
// the swatch's own bounds, so the swatch answered a pointer by not moving
// — measured by the consumer's ui-guard at 1.3px off a 32px swatch. The
// sample carries the corner itself instead, which is what the clip was
// doing for it, and item clipping never rounded the check's corners
// anyway (it is rectangular).
Item {
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
    // The painted face's square side. The layout footprint is the face
    // widened to the target floor, never the other way round.
    property real size: Style.size("ColorSwatch", "md")
    property bool selected: false
    property bool focused: root.activeFocus

    // The keyboard handlers below need focus, and nothing was giving it: no
    // tab stop, and a pointer press that never moved focus here. The five
    // states law counts a state the component cannot express as a state it
    // does not have, and this one was written down and unreachable.
    activeFocusOnTab: enabled

    // A swatch always has a name: the host's reading, else the colour's own
    // value, else what an empty slot is.
    Accessible.role: Accessible.Button
    Accessible.name: root.reading.length > 0 ? root.reading
        : root.empty ? qsTr("Empty colour slot") : root.sample.toString()
    // `selected` is a fact a screen reader has to hear, not only a ring.
    Accessible.checkable: true
    Accessible.checked: root.selected

    signal clicked

    // The swatch decides its own ink so no call site has to, and it decides it
    // by MEASURING rather than by assuming the theme is dark. The first
    // version returned `Style.band` for a pale sample and `Style.text`
    // for a dark one, which is only right while band is the dark one —
    // under a light backend it hands a pale swatch pale ink.
    //
    // The sample is composited over what is actually BEHIND it first: a
    // 20%-alpha colour is not the colour you would measure, and reading the
    // raw value picks ink for a swatch nobody can see.
    //
    // Behind a translucent sample is the alpha check, not the surface — two
    // colours, not one. Measuring against the surface picked pale ink that
    // then sat on the check's white cells and vanished. So a translucent
    // sample is measured against BOTH cells and the ink has to survive the
    // worse of them.
    function _over(ground: color): color {
        return Qt.rgba(sample.r * sample.a + ground.r * (1 - sample.a),
            sample.g * sample.a + ground.g * (1 - sample.a),
            sample.b * sample.a + ground.b * (1 - sample.a), 1);
    }

    readonly property color _seen: _over(Style.surface)
    readonly property color _seenLight: _over(Style.checkerLight)
    readonly property color _seenDark: _over(Style.checkerDark)

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

    // The worst contrast this ink would face on this swatch. Opaque: one
    // ground. Translucent: the two check cells, and the ink must read on both.
    function _worst(candidate: color): real {
        return root.sample.a < 1
            ? Math.min(root._contrast(root._seenLight, candidate),
                root._contrast(root._seenDark, candidate))
            : root._contrast(root._seen, candidate);
    }

    // Whichever of the theme's two inks actually reads on this sample.
    readonly property color ink: _worst(Style.text) >= _worst(Style.band)
        ? Style.text
        : Style.band

    // WCAG 1.4.3 for text. On a mid-tone neither ink reaches it (the better of
    // the two bottoms out at 3.7:1), and a reading nobody can read is the one
    // failure this swatch exists to prevent. Then the reading sits on a band
    // plate and takes the theme's text ink, which reads on band by the ladder.
    readonly property real _readable: 4.5
    readonly property bool _plated: !root.empty && root.reading.length > 0
        && (root._worst(root.ink) < root._readable
            || readingMetrics.advanceWidth > root.size - Style.spaceTight * 2)

    // One route in: pointer, Space, Return and callers share it, guarded here
    // so no route fires while unavailable. The host still owns `selected`
    // and what the click means.
    function activate(): void {
        if (root.enabled)
            root.clicked();
    }

    readonly property list<T.Action> actions: [
        T.Action { text: root.reading; enabled: root.enabled; onTriggered: root.activate() }
    ]

    // Disabled dims each painted role by COLOUR, never by composite opacity:
    // opacity on the stack applies to every child separately, so a dimmed
    // translucent sample would show its own fill through itself and stop
    // being two layers. The sample keeps its alpha, so a translucent sample
    // still reveals the check beneath it instead of turning into an opaque
    // fake.
    // Selected is identity: an accent ring OUTSIDE the face with a gap, so a
    // pale or accent sample keeps its own edge and the ring keeps 3:1 against
    // the host (WCAG 1.4.11), which an ink ring chosen against the sample alone
    // did not. The keyboard ring steps out beyond it while selected.
    readonly property real _selStroke: Style.stroke(Style.spaceTight, Screen.devicePixelRatio)
    readonly property real _selReach: root._selStroke * 2

    // Hover growth is capped to about one pixel a side: a fixed ratio let a
    // 52px face overhang its footprint by 2px, and it is movement, so reduced
    // motion drops it.
    readonly property real _hoverScale: Style.reducedMotion ? 1
        : 1 + Math.min(Motion.hoverScale - 1, Style.spaceTight / root.size)

    function _paint(c: color): color {
        if (root.enabled)
            return c;
        const d = Style.disabled(c);
        return Qt.rgba(d.r, d.g, d.b, c.a);
    }

    // The TARGET: the layout footprint, never below the floor, so palette
    // siblings never receive overlapping hit zones. The face stays `size`
    // and sits centred inside it.
    implicitWidth: Math.max(size, Style.swatchTarget)
    implicitHeight: Math.max(size, Style.swatchTarget)

    // The FACE: the alpha check with the sample composited over it, masked to
    // the swatch's own corner, plus the ring and the reading. Hover and press
    // animate this item's scale, which never moves the layout footprint.
    //
    // The check comes first, because without it a 20%-alpha colour reads as a
    // different opaque colour, which is the one confusion a colour tool must
    // not create. A Rectangle radius does not round it: item clipping is
    // rectangular, so the check's corner cells sat square outside the sample's
    // curve. `MultiEffect.maskSource` is the mechanism that actually cuts
    // them, and it is applied to the pair so they cannot disagree.
    //
    // The mask stops at the pair. Everything that RESPONDS to a pointer — the
    // rings, the reading, the state layer — is outside it, because a mask the
    // size of the face would clip the hover growth back to nothing.
    Item {
        id: face
        objectName: "swatchFace"
        width: root.size
        height: root.size
        anchors.centerIn: parent

        Item {
            id: facePair
            anchors.fill: parent
            visible: false
            layer.enabled: true

            Item {
                anchors.fill: parent
                visible: root.sample.a < 1

                Repeater {
                    model: 16

                    delegate: Rectangle {
                        required property int index
                        width: face.width / 4
                        height: face.height / 4
                        x: (index % 4) * width
                        y: Math.floor(index / 4) * height
                        color: root._paint((index + Math.floor(index / 4)) % 2 === 0 ? Style.checkerLight : Style.checkerDark)
                    }
                }
            }

            Rectangle {
                objectName: "swatchSample"
                anchors.fill: parent
                color: root._paint(root.sample)
            }
        }

        Rectangle {
            id: faceMask
            anchors.fill: parent
            radius: Style.radiusSm
            color: "black"
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: parent
            visible: !root.empty
            source: facePair
            maskEnabled: true
            maskSource: faceMask
        }

        // The empty slot: an outline and nothing else. Not a dashed border and not
        // a plus glyph — both announce an action, and the slot is a place, with
        // the action stated by whatever put it there.
        Rectangle {
            anchors.fill: parent
            visible: root.empty
            color: "transparent"
            radius: Style.radiusSm
            border.width: Style.stroke(Style.spaceTight, Screen.devicePixelRatio)
            border.color: root._paint(Style.textMuted)
        }

        // The reading is fitted to the face, never cut: a plate wider than the
        // face (bounded a little beyond the footprint) beats an elided hex. On
        // a plate the ink is the theme's text, which reads on band.
        Rectangle {
            visible: !root.empty && root.reading.length > 0
            anchors.centerIn: parent
            width: Math.min(readingText.implicitWidth + Style.spaceTight * 2,
                root.width + Style.space1)
            height: readingText.implicitHeight + Style.spaceTight
            radius: Style.radiusSm
            color: root._plated ? root._paint(Style.band) : "transparent"

            Prose {
                id: readingText
                anchors.fill: parent
                anchors.leftMargin: Style.spaceTight
                anchors.rightMargin: Style.spaceTight
                role: "reading"
                font.pixelSize: Style.textXs
                color: root._paint(root._plated ? Style.text : root.ink)
                text: root.reading
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    TextMetrics {
        id: readingMetrics
        font: readingText.font
        text: root.reading
    }

    Rectangle {
        objectName: "swatchRing"
        anchors.fill: face
        anchors.margins: -root._selReach
        color: "transparent"
        radius: Style.radiusSm + root._selReach
        border.width: root._selStroke
        border.color: root._paint(Style.accent)
        opacity: root.selected ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }

    // The keyboard ring is its own layer sized to the FACE, because StateLayer
    // rings its parent and the pointer target is 44px: ringed there, it floated
    // 4 to 14px off a smaller swatch. Declared below the pointer layer so the
    // hand cursor stays the pointer layer's.
    StateLayer {
        anchors.fill: face
        anchors.margins: root.selected ? -root._selReach : 0
        target: null
        clickable: false
        interactive: root.enabled
        focused: root.focused && !root._pointerFocus
        focusRadius: Style.radiusSm + (root.selected ? root._selReach : 0)
    }

    // The layer covers the whole TARGET for the pointer and moves the face.
    // Pressing pushes the face in: a colour change would alter the very colour
    // being sampled.
    StateLayer {
        anchors.fill: parent
        target: face
        interactive: root.enabled
        hoverScale: root._hoverScale
        pressScale: Motion.pressScale
        onClicked: {
            root._pointerFocus = true;
            root.forceActiveFocus();
            root.activate();
        }
    }

    // A click focuses without ringing; the ring is for the keyboard.
    property bool _pointerFocus: false
    onActiveFocusChanged: if (!root.activeFocus) root._pointerFocus = false

    Keys.onSpacePressed: root.activate()
    Keys.onReturnPressed: root.activate()
    Keys.onEnterPressed: root.activate()
}
