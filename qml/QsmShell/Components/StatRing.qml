import QtQuick

import qs.QsmShell.Style

// A fraction, drawn as an arc, with its reading in the middle.
//
// It is a `Meter` bent into a circle, and the reason to have both is the
// reason to bend it: a bar compares well against other bars stacked in a
// column, a ring reads as ONE quantity at a glance and holds a number in its
// middle. A card of four rings is scannable; the same four as bars is a chart
// nobody asked for.
//
// `startAngle` and `sweepAngle` make it a three-quarter ring as easily as a
// closed one, and the open form is not decoration: the gap at the bottom is
// where a label goes without colliding with the arc. A closed ring keeps its
// label inside the circle too, in the hole the arc leaves.
//
// The arc's own colour never carries the reading alone — the LENGTH does, and
// the number is in the middle. The fill is the active part of a track, so it
// reads `primary`, the way a `Meter` does, never the accent a passive metric
// has no claim on.
Item {
    id: root

    // 0..1
    property real value: 0
    // The number in the middle, already formatted. A ring showing "72%" and
    // one showing "3.4 GB" are the same component; formatting is the caller's,
    // because only the caller knows the unit and the precision that matter.
    property string reading: ""
    property string label: ""
    property string icon: ""
    property color iconColor: Style.text
    property color fill: Style.primary
    property color trackColor: Style.overlay

    // A preset NAME of the StatRing size table; the diameter below is the one
    // number it resolves to, and stating it is the escape hatch.
    property string size: "md"
    property int diameter: Style.size("StatRing", root.size)
    // A proportion of the ring, in whole device pixels, so a smaller ring keeps
    // its look instead of a fixed stroke that is a disc on a small one.
    property real strokeWidth: Style.stroke(root._box * Style.ringStrokeRatio, root)
    // Degrees. -90 is twelve o'clock; 360 closes the circle.
    property real startAngle: -90
    property real sweepAngle: 360

    // The reading is the focal point and steps with the ring: a 150px ring and
    // a 64px one cannot share a type size without one of them being wrong. It
    // is the md reading times the live box over the md diameter, snapped to
    // the type scale up to display (a 240px ring reads at 28, not at 22 in a
    // hollow); a caller that states it owns the number.
    readonly property real _readingWanted: Style.textXl * root._box / Style.ringDiameter
    property int readingSize: [Style.textSm, Style.textMd, Style.textLg, Style.textXl, Style.textDisplay]
        .reduce((best, step) => Math.abs(step - root._readingWanted) < Math.abs(best - root._readingWanted) ? step : best)

    implicitWidth: diameter
    implicitHeight: diameter

    // A passive output: no pointer, wheel, keyboard, focus or selection.
    Accessible.role: Accessible.StaticText
    Accessible.name: [root.label, root.reading].filter(part => part.length > 0).join(", ")

    // The live ring box. It tracks the rendered size, never the diameter
    // preference, so caller-set geometry cannot overflow.
    readonly property real _box: Math.min(root.width, root.height)
    // The arc's centreline sits this many strokes inside the box edge, so the
    // outer edge is a quarter stroke clear of it and the anti-aliased rim is
    // never cut by the canvas.
    readonly property real _strokeInset: 0.75

    // The column the centred content may take: the square inscribed in the
    // hole of the ring. The painted stroke reaches _box/2 - inset x stroke +
    // stroke/2 from the centre, so the hole's radius is
    // _box/2 - (inset + 1/2) x stroke, and the inscribed square's side is
    // sqrt(2) times that. Long text elides inside it instead of crossing the
    // arc.
    // Even, so the column centres on a whole pixel instead of a half.
    readonly property int _contentWidth: Math.max(0, 2 * Math.floor(Math.SQRT2 * (root._box / 2 - (root._strokeInset + 0.5) * root.strokeWidth) / 2))
    readonly property int _iconSize: Style.iconNear(root.readingSize)
    // The text rows' own height, independent of the icon so that hiding the
    // icon cannot resize the stack back into fitting.
    readonly property real _textHeight: (readingText.visible ? readingText.implicitHeight : 0)
        + (labelText.visible ? labelText.implicitHeight : 0)
        + (readingText.visible && labelText.visible ? Style.spaceTight : 0)
    // A glyph that would push the stack out of the hole is dropped: the reading
    // and label carry the meaning, and a glyph across the arc carries none.
    readonly property bool _iconFits: root.icon.length > 0
        && root._textHeight + (root._textHeight > 0 ? Style.spaceTight : 0) + root._iconSize <= root._contentWidth

    // The fraction on screen: the value clamped, and eased, because a reading
    // that snaps between samples reads as jitter. Reduced motion removes the
    // glide; a one-shot position animation is removed, never shortened.
    property real _shown: Math.max(0, Math.min(1, root.value))
    Behavior on _shown {
        enabled: !Style.reducedMotion
        NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const context = getContext("2d");
            context.reset();
            const cx = width / 2;
            const cy = height / 2;
            // The inset scales with the stroke, so a thinner ring on a smaller
            // card keeps the same proportion rather than the same gap.
            const radius = Math.min(cx, cy) - root.strokeWidth * root._strokeInset;
            const start = root.startAngle * Math.PI / 180;
            const sweep = root.sweepAngle * Math.PI / 180;

            context.lineWidth = root.strokeWidth;
            context.lineCap = "round";
            context.strokeStyle = root.trackColor;
            context.beginPath();
            context.arc(cx, cy, radius, start, start + sweep);
            context.stroke();

            // A round-capped arc of zero length still paints a dot, which
            // reads as "a little" when the answer is "none".
            if (root._shown > 0.005) {
                context.strokeStyle = root.fill;
                context.beginPath();
                context.arc(cx, cy, radius, start, start + sweep * root._shown);
                context.stroke();
            }
        }
    }

    on_ShownChanged: canvas.requestPaint()
    onFillChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onStrokeWidthChanged: canvas.requestPaint()
    onStartAngleChanged: canvas.requestPaint()
    onSweepAngleChanged: canvas.requestPaint()
    // The arc is drawn from the live geometry, so a resize repaints too.
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Column {
        anchors.centerIn: parent
        width: root._contentWidth
        clip: true
        spacing: Style.spaceTight

        SvgIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root._iconFits
            name: root.icon
            size: root._iconSize
            color: root.iconColor
        }
        Prose {
            id: readingText
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: root.reading.length > 0
            role: "reading"
            font.pixelSize: root.readingSize
            text: root.reading
            Accessible.ignored: true
        }
        Prose {
            id: labelText
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: root.label.length > 0
            role: "metadata"
            text: root.label
            Accessible.ignored: true
        }
    }
}
