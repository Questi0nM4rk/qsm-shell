pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// A colour slot: the colour shown as itself with a short reading on it, or the
// empty state when there is no colour in it yet.
//
// A colour has to survive its ground. A sample that falls short of the graphic
// floor against a step of the ladder it may sit on (a swatch may equal its
// ground) paints a hairline at its edge, the border that encodes what colour
// cannot (AGENTS.md, borders). The ink of the reading is chosen by measuring
// the sample, never by assuming the theme is dark.
//
// The checkerboard under a translucent colour is not decoration: a 20%-alpha
// swatch over the shell's own surface looks like a different opaque colour,
// which is exactly the confusion a colour tool must not create.
//
// The painted FACE stays compact (`size`, what the callers chose) and is
// centred in a TARGET that never drops below the Blueprint's floor, so a 24px
// sample in a palette row still answers on a full target without its hit zone
// overlapping a sibling's. Selection and focus belong to the face; the target
// itself paints nothing.
// NOT clipped. `clip` would shave the StateLayer's hover growth back to the
// swatch's own bounds, so the swatch would answer a pointer by not moving.
// The sample, the check and the edge carry the corner themselves.
Item {
    id: root

    required property color sample
    // No colour in this slot YET, which is not the same as a transparent
    // colour: transparent is a real sample and gets the alpha check, while an
    // empty slot has nothing to show and says so with an outline. A picker's
    // "click here to sample something" square is the case. `sample` stays
    // required so a typo in a binding is still caught -- an empty slot passes
    // "transparent" and this flag, which says what it means out loud.
    property bool empty: false
    // Shown on the face, one line: what fits the face is read, the rest is
    // elided. Empty draws the sample alone.
    property string reading: ""
    // The painted face's square side. The layout footprint is the face
    // widened to the target floor, never the other way round.
    property real size: Style.size("ColorSwatch", "md")
    // The smallest footprint and hit zone. A dense palette sets it to the
    // pointer floor so a grid is as tight as its faces.
    property real target: Style.swatchTarget
    property bool selected: false
    property bool focused: root.activeFocus
    // Keyboard focus, the only focus that rings: a click focuses without one.
    readonly property bool visualFocus: root.focused && !root._pointerFocus

    // The keyboard handlers below need focus, so the swatch is a tab stop and
    // a pointer press moves focus here.
    activeFocusOnTab: enabled

    // A swatch always has a name: the host's reading, else the colour's own
    // value, else what an empty slot is.
    Accessible.role: Accessible.Button
    Accessible.name: root.reading.length > 0 ? root.reading
        : root.empty ? qsTr("Empty colour slot") : root.sample.toString()
    Accessible.description: root.reading.length > 0 && !root.empty ? root.sample.toString() : ""
    // `selected` is a fact a screen reader has to hear, not only a ring.
    Accessible.checkable: true
    Accessible.checked: root.selected
    Accessible.onPressAction: root.activate()

    signal clicked

    // What is actually SEEN behind the face: the sample itself, or a
    // translucent one laid over each cell of the check, because the ink has to
    // read on the worse of the two and an edge has to hold against both.
    readonly property var _seen: root.sample.a < 1
        ? [Qt.tint(Style.checkerLight, root.sample), Qt.tint(Style.checkerDark, root.sample)]
        : [root.sample]

    // The worst contrast this ink would face on this swatch.
    function _worst(candidate: color): real {
        return Math.min(...root._seen.map(seen => Style.contrast(seen, candidate)));
    }

    // Whichever of the theme's two inks actually reads on this sample.
    readonly property color ink: _worst(Style.text) >= _worst(Style.band)
        ? Style.text
        : Style.band

    // On a mid-tone neither ink reaches the text floor (the better of the two
    // bottoms out at 3.7:1), and a reading nobody can read is the one failure
    // this swatch exists to prevent. Then the reading sits on a band plate,
    // whose text ink reads on band by the ladder.
    readonly property bool _plated: !root.empty && root.reading.length > 0
        && root._worst(root.ink) < Style.contrastText

    // Whether the face paints its edge. A swatch cannot know its ground, so it
    // measures against every step of the ladder it may sit on: a sample under
    // the graphic floor against any of them gets the edge on all, and looks
    // the same wherever a host puts it.
    readonly property bool contained: !root.empty
        && [Style.band, Style.surface, Style.overlay].some(ground =>
            root._seen.some(seen => Style.contrast(seen, ground) < Style.contrastGraphic))

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

    // Selected is identity: an accent ring OUTSIDE the face with a hairline gap,
    // so a pale or accent sample keeps its own edge and the ring keeps 3:1
    // against the host (WCAG 1.4.11). The reach (gap plus stroke) stays under
    // the 4 px between dense palette faces, so a selected ring never lies on a
    // neighbour. The keyboard ring steps out beyond it while selected.
    readonly property real _selStroke: Style.stroke(Style.indicatorWidth, root)
    readonly property real _selReach: root._selStroke + Style.stroke(Style.hairline, root)

    // Hover growth is capped to about one pixel a side: a fixed ratio let a
    // 52px face overhang its footprint by 2px, and it is movement, so reduced
    // motion drops it.
    readonly property real _hoverScale: Style.reducedMotion ? 1
        : 1 + Math.min(Motion.hoverScale - 1, Style.spaceTight / root.size)

    // Disabled dims each painted role by COLOUR, never by composite opacity:
    // opacity on the stack applies to every child separately, so a dimmed
    // translucent sample would show its own fill through itself and stop being
    // two layers. The sample keeps its alpha, so a translucent sample still
    // reveals the check beneath it instead of turning into an opaque fake.
    function _paint(c: color): color {
        if (root.enabled)
            return c;
        const d = Style.disabled(c);
        return Qt.rgba(d.r, d.g, d.b, c.a);
    }

    // The check's grid: odd, so all four corner cells share a colour and the
    // only curve is the ground's own.
    readonly property int _cells: 5
    readonly property var _darkCells: Array.from({ length: root._cells * root._cells }, (_, i) => i)
        .filter(i => (Math.floor(i / root._cells) + i % root._cells) % 2 === 1)

    readonly property real _dpr: root.Window.window?.devicePixelRatio ?? 1

    // The TARGET: the layout footprint, never below the floor, so palette
    // siblings never receive overlapping hit zones. The face stays `size`
    // and sits centred inside it.
    implicitWidth: Math.max(size, target)
    implicitHeight: Math.max(size, target)

    // The FACE: the alpha check under the sample, the edge, the empty outline
    // and the reading. Hover and press change this item's size by whole device
    // pixels, which never moves the layout footprint.
    Item {
        id: face
        objectName: "swatchFace"
        width: root.size + 2 * pointerLayer.growth
        height: width
        // Centred on a whole device pixel: `anchors.centerIn` rounds to a
        // whole LOGICAL pixel, which at 1.25 puts an edge between two rows.
        x: Math.round((root.width - width) / 2 * root._dpr) / root._dpr
        y: Math.round((root.height - height) / 2 * root._dpr) / root._dpr

        // A light rounded ground with dark cells on top: no mask, so the
        // corner is the rectangle's own, anti-aliased by the scene graph.
        Rectangle {
            anchors.fill: parent
            visible: !root.empty && root.sample.a < 1
            radius: Style.radiusSm
            color: root._paint(Style.checkerLight)

            Repeater {
                model: root._darkCells

                delegate: Rectangle {
                    required property int modelData
                    width: face.width / root._cells
                    height: width
                    x: (modelData % root._cells) * width
                    y: Math.floor(modelData / root._cells) * height
                    color: root._paint(Style.checkerDark)
                }
            }
        }

        Rectangle {
            objectName: "swatchSample"
            anchors.fill: parent
            visible: !root.empty
            radius: Style.radiusSm
            color: root._paint(root.sample)
        }

        // The containment edge, INSIDE the face so the footprint and the
        // hover growth stay what they were.
        Rectangle {
            objectName: "swatchEdge"
            anchors.fill: parent
            visible: root.contained
            color: "transparent"
            radius: Style.radiusSm
            border.width: Style.stroke(Style.hairline, root)
            border.color: root._paint(Style.textMuted)
        }

        // The empty slot: an outline and nothing else. Not a dashed border and not
        // a plus glyph -- both announce an action, and the slot is a place, with
        // the action stated by whatever put it there.
        Rectangle {
            anchors.fill: parent
            visible: root.empty
            color: "transparent"
            radius: Style.radiusSm
            border.width: Style.stroke(Style.indicatorWidth, root)
            border.color: root._paint(Style.textMuted)
        }

        // The reading is whole or absent: one that does not fit the face is not painted (an elided "P..." reads as a different
        // value, and a plate wider than the face lies on the selection ring).
        // The host sizes the face for what it reads; the name still carries it.
        Rectangle {
            visible: !root.empty && root.reading.length > 0
                && width <= root.size - Style.spaceTight * 2
            anchors.centerIn: parent
            width: readingText.implicitWidth + Style.spaceTight * 2
            height: readingText.implicitHeight + Style.spaceTight
            radius: Style.radiusXs
            color: root._plated ? root._paint(Style.band) : "transparent"

            Prose {
                id: readingText
                anchors.fill: parent
                anchors.leftMargin: Style.spaceTight
                anchors.rightMargin: Style.spaceTight
                role: "reading"
                font.pixelSize: Style.textNear(Style.textSm * root.size / Style.size("ColorSwatch", "md"))
                color: root._paint(root._plated ? Style.text : root.ink)
                text: root.reading
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
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
        clickable: false
        interactive: root.enabled
        focused: root.visualFocus
        focusRadius: Style.radiusSm + (root.selected ? root._selReach : 0)
    }

    // The layer covers the whole TARGET for the pointer and moves the face; the
    // ring above is the only one, so this layer never rings the target.
    // Pressing pushes the face in: a colour change would alter the very colour
    // being sampled.
    StateLayer {
        id: pointerLayer
        anchors.fill: parent
        extent: root.size
        interactive: root.enabled
        focused: false
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

    // One dispatcher, because a named handler beside `onPressed` still fires.
    // A key is keyboard use, so it brings the ring back after a click; a held
    // key does not repeat the action.
    Keys.onPressed: event => {
        if (event.key !== Qt.Key_Space && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
            return;
        event.accepted = true;
        if (event.isAutoRepeat)
            return;
        root._pointerFocus = false;
        root.activate();
    }
}
