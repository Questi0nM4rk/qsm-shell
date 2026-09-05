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
// where a label goes without colliding with the arc. A closed ring pushes its
// label outside the circle, where it stops belonging to it.
//
// The arc's own colour never carries the reading alone — the LENGTH does, and
// the number is in the middle.
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
    property color fill: Style.accent
    property color trackColor: Style.surfaceHover

    property int diameter: Style.ringDiameter
    property int strokeWidth: Style.ringStroke
    // Degrees. -90 is twelve o'clock; 360 closes the circle.
    property real startAngle: -90
    property real sweepAngle: 360

    // The reading is the focal point and steps with the ring: a 150px ring and
    // a 56px one cannot share a type size without one of them being wrong.
    property int readingSize: Style.textXl

    implicitWidth: diameter
    implicitHeight: diameter

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
            const radius = Math.min(cx, cy) - root.strokeWidth * 0.75;
            const start = root.startAngle * Math.PI / 180;
            const sweep = root.sweepAngle * Math.PI / 180;

            context.lineWidth = root.strokeWidth;
            context.lineCap = "round";
            context.strokeStyle = root.trackColor;
            context.beginPath();
            context.arc(cx, cy, radius, start, start + sweep);
            context.stroke();

            const fraction = Math.max(0, Math.min(1, root.value));
            // A round-capped arc of zero length still paints a dot, which
            // reads as "a little" when the answer is "none".
            if (fraction > 0.005) {
                context.strokeStyle = root.fill;
                context.beginPath();
                context.arc(cx, cy, radius, start, start + sweep * fraction);
                context.stroke();
            }
        }
    }

    onValueChanged: canvas.requestPaint()
    onFillChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onStrokeWidthChanged: canvas.requestPaint()
    onStartAngleChanged: canvas.requestPaint()
    onSweepAngleChanged: canvas.requestPaint()

    Column {
        anchors.centerIn: parent
        spacing: Style.spaceTight

        SvgIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.icon.length > 0
            name: root.icon
            size: root.readingSize
            color: root.iconColor
        }
        Prose {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.reading.length > 0
            role: "reading"
            font.pixelSize: root.readingSize
            text: root.reading
        }
        Prose {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.label.length > 0
            role: "metadata"
            text: root.label
        }
    }
}
