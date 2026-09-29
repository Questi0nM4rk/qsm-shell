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
    property real size: Style.controlHeight
    property bool selected: false
    property bool focused: root.activeFocus

    // The keyboard handlers below need focus, and nothing was giving it: no
    // tab stop, and a pointer press that never moved focus here. The five
    // states law counts a state the component cannot express as a state it
    // does not have, and this one was written down and unreachable.
    activeFocusOnTab: enabled

    Accessible.role: Accessible.Button
    Accessible.name: root.reading

    signal clicked

    // The swatch decides its own ink so no call site has to, and it decides it
    // by MEASURING rather than by assuming the theme is dark. The first
    // version returned `Style.background` for a pale sample and `Style.text`
    // for a dark one, which is only right while background is the dark one —
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
    readonly property color _seenLight: _over("#ffffff")
    readonly property color _seenDark: _over("#c0c0c0")

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
    readonly property color ink: _worst(Style.text) >= _worst(Style.background)
        ? Style.text
        : Style.background

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
                        color: root._paint((index + Math.floor(index / 4)) % 2 === 0 ? "#ffffff" : "#c0c0c0")
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
            border.width: 1
            border.color: root._paint(Style.outline)
        }

        // Focus belongs to the face, not the target: an accent ring outside
        // the body at the half step, concentric, under the reading.
        Rectangle {
            anchors.fill: parent
            anchors.margins: -Style.spaceTight
            visible: root.focused && root.enabled
            color: "transparent"
            radius: Style.radiusSm + Style.spaceTight
            border.width: 1
            border.color: Style.accent
        }

        // The selection ring is drawn LAST, over the sample.
        //
        // It used to be the root's own `border`, which a Rectangle paints behind
        // its children — so the opaque sample filling the root covered it, and
        // `clip: true` finished the job. The advertised ring was never once
        // visible. It is still a ring rather than a mark ON the swatch, because a
        // mark drawn on top changes the thing being sampled.
        Rectangle {
            objectName: "swatchRing"
            anchors.fill: parent
            color: "transparent"
            radius: Style.radiusSm
            border.width: root.selected ? Style.markThickness - 1 : 0
            // The ring is drawn in the ink this swatch already measured, not in
            // the accent: an accent ring on an accent-coloured swatch is
            // invisible, and a colour tool shows arbitrary colours by definition.
            // Same law as the reading — contrast against the SAMPLE, never a
            // fixed colour that happens to work on most of them.
            border.color: root._paint(root.empty ? Style.accent : root.ink)

            Behavior on border.width {
                NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
            }
        }

        Prose {
            anchors.centerIn: parent
            visible: !root.empty && root.reading.length > 0
            role: "reading"
            font.pixelSize: Style.textXs
            color: root._paint(root.ink)
            text: root.reading
        }
    }

    // The layer covers the whole TARGET for the pointer, but grows only the
    // face and paints no ring of its own: indication belongs to the face.
    StateLayer {
        anchors.fill: parent
        target: face
        interactive: root.enabled
        focused: false
        focusRadius: Style.radiusSm
        hoverScale: 1.08
        pressScale: 0.94
        onClicked: {
            root.forceActiveFocus();
            root.activate();
        }
    }

    Keys.onSpacePressed: root.activate()
    Keys.onReturnPressed: root.activate()
}
