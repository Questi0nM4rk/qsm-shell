import QtQuick
import QtQuick.Effects

import qs.QsmShell.Style

// A masked picture, with something to show when there is no picture.
//
// Round by default. `radius` is here because the masking is the hard part and
// it should exist once: a rounded SQUARE has exactly the same problem as a
// circle, since item clipping is rectangular either way.
//
// For a PERSON the fallback is their initials, never a silhouette glyph: a row
// of identical silhouettes distinguishes nobody, and the fallback is the state
// that actually ships most of the time. For a thing that has no name to
// initialise — album art, a station logo — set `icon` instead and the glyph
// stands in. One of the two, never both: `icon` wins if it is set, because a
// caller that set it has said the initials would be meaningless.
//
// `status` rides the corner rather than tinting the whole mark: tinting a
// photograph to say "online" damages the photograph and says it faintly.
//
// `progress` rides the RIM, for the same reason and one more: "a picture with
// how-far-through drawn around it" is ONE thing, and a consumer assembling it
// out of a ring and a picture assembles it differently every time. It was
// built twice in the one consuming shell — a circle with a full ring on one
// surface, a square with a half ring on another, the arc hidden behind the
// square's own corners — which is the whole argument for this type owning it.
Item {
    id: root

    property url source: ""
    // The name the initials come from. Two words give two letters, one gives
    // one — three letters is a monogram, not a glance.
    property string name: ""
    property real size: Style.size("Avatar", "md")
    property color background: Style.overlay
    // Empty = no dot. Otherwise a Badge tone.
    property string status: ""

    // How far through, 0..1, drawn as a ring around the picture. Below 0 there
    // is no ring and the item is exactly `size`.
    property real progress: -1
    property color progressColor: Style.text
    // The ring's empty part: a line of content, drawn in the band so it
    // reads on the overlay picture it circles.
    property color progressTrack: Style.overlay
    // The ring is 6% of the diameter, at least 2px: thick enough to read as
    // progress at every size, thin enough that the picture stays the subject.
    // A proportion of the picture, so it scales with it, not a token.
    property real ringWidth: Math.max(Style.spaceTight, Math.round(size * 0.06))
    // Air between the picture and its ring, so the two read as a thing and its
    // frame rather than as one thick border.
    property real ringGap: Style.spaceTight

    readonly property bool _ringed: progress >= 0
    // Both sides of the ring: the gap, then the stroke measured from the arc's
    // inner edge. StatRing centres the arc `_strokeInset` strokes inside its box
    // and the stroke reaches half a stroke either side of that, so the inner
    // edge sits (inset + 1/2) strokes in. Each side rounds to a whole pixel so
    // the room stays even and the picture stays on the pixel grid.
    readonly property real _ringRoom: _ringed ? 2 * Math.round(ringGap + (ring._strokeInset + 0.5) * ringWidth) : 0
    // The stand-in for a thing rather than a person. Set this OR `name`.
    property string icon: ""
    // How big the stand-in is drawn. Two-fifths of the diameter is the rule
    // for initials — big enough to read, small enough that two letters clear
    // the circle at every size — and it is only a DEFAULT for a glyph, whose
    // weight varies with the icon. A consumer that had a size before this type
    // existed states it rather than being silently resized.
    property real glyphSize: Math.round(size * 0.4)
    // Round by default, because that is what a portrait is. A consumer that
    // frames a thing rather than a face states its own corner: album art is a
    // sleeve, and a sleeve is square with the room's rounding on it.
    //
    // Measured from `size`, which IS the picture's box: the ground, the mask
    // and this corner all follow the same number, and the item's own width may
    // be larger because a ring asked for room.
    property real radius: size / 2

    readonly property string initials: {
        const words = name.trim().split(/\s+/).filter(word => word.length > 0);
        if (words.length === 0)
            return "";
        if (words.length === 1)
            return words[0].charAt(0).toUpperCase();
        return String(words[0].charAt(0) + words[words.length - 1].charAt(0)).toUpperCase();
    }

    // `size` is always the PICTURE. A ring adds its own room, so a consumer
    // that turns one on does not have to work out what to shrink.
    implicitWidth: size + _ringRoom
    implicitHeight: size + _ringRoom

    StatRing {
        id: ring
        anchors.fill: parent
        visible: root._ringed
        diameter: root.width
        strokeWidth: root.ringWidth
        value: root.progress
        fill: root.progressColor
        trackColor: root.progressTrack
    }

    Rectangle {
        id: ground
        anchors.centerIn: parent
        width: root.size
        height: root.size
        radius: root.radius
        color: root.background

        SvgIcon {
            anchors.centerIn: parent
            visible: portrait.status !== Image.Ready && root.icon.length > 0
            name: root.icon
            size: Style.iconNear(root.glyphSize)
            color: Style.textMuted
        }

        Prose {
            anchors.centerIn: parent
            visible: portrait.status !== Image.Ready && root.icon.length === 0
            role: "title"
            font.pixelSize: Style.textNear(root.glyphSize)
            muted: true
            text: root.initials
        }
    }

    // A round photograph needs a real alpha MASK. Item clipping is
    // rectangular, and a Rectangle with a radius and `layer.enabled` does not
    // mask its children either — the first version did exactly that and the
    // photograph stayed square, sitting over the round ground it was supposed
    // to fill. `MultiEffect.maskSource` is the mechanism that actually cuts
    // the corners.
    Image {
        id: portrait
        anchors.fill: ground
        source: root.source
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    Rectangle {
        id: circleMask
        anchors.fill: ground
        radius: root.radius
        color: "black"
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: ground
        visible: portrait.status === Image.Ready
        source: portrait
        maskEnabled: true
        maskSource: circleMask
    }

    // The dot is a fifth of the picture on the rhythm, centred on the rim at
    // 45 degrees so it straddles the edge at every size. The corner of a
    // rounded box is an arc of radius `_arc` whose centre is `size / 2 - _arc`
    // from the middle; on a circle that is the centre itself, on a square it
    // is the box corner.
    // Built only with a status: Badge throws on an unknown tone, and "" is one.
    Loader {
        readonly property real _arc: Math.min(root.radius, root.size / 2)
        readonly property real _offset: root.size / 2 - _arc + _arc * Math.SQRT1_2

        width: height
        height: Style.rhythm(root.size * 0.2)
        x: Math.round(root.width / 2 + _offset - width / 2)
        y: Math.round(root.height / 2 + _offset - height / 2)
        active: root.status.length > 0
        sourceComponent: Badge {
            tone: root.status
            dot: true
            filled: true
        }
    }
}
