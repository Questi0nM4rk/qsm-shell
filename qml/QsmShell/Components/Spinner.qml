import QtQuick

import qs.QsmShell.Style

// "This is running, and I cannot tell you for how long."
//
// That sentence is the whole trigger. A spinner is the indicator for the
// response tier past about a second where the END is unknowable — a scan, a
// probe, a device waking up. The moment a total IS knowable, this is the wrong
// component and `ProgressBar` is the right one: a spinner in front of a known
// quantity throws away information the person wanted.
//
// It never disappears on its own. A spinner that simply vanishes has reported
// nothing, and the outcome was the point — the surface that started the work
// replaces this with the result, success or failure.
Item {
    id: root

    property real size: Style.iconMd
    property color color: Style.accent
    // How much of the ring is drawn. A short arc reads as faster at the same
    // period, which is the cheapest way to say "busy" without spinning harder.
    property real sweep: 0.28
    // Stop the animation without removing the mark — for a surface that is
    // hidden but not destroyed, so an off-screen spinner is not burning a
    // repaint every frame.
    property bool running: true

    implicitWidth: size
    implicitHeight: size

    Canvas {
        id: arc
        anchors.fill: parent
        // The line has to fit INSIDE the box: an arc stroked on the boundary
        // loses half its width to the clip and reads thinner at the top than
        // at the sides.
        // Proportional to the ring, because a fixed stroke on a 12px spinner
        // is a disc and on a 48px one is a hairline. The ratio is the library's
        // ring stroke against its ring diameter, so the two read as one family.
        readonly property real thickness: Math.max(1,
            root.size * (Style.ringStroke / Style.ringDiameter) * 3)

        onPaint: {
            const c = getContext("2d");
            c.reset();
            const centre = width / 2;
            const radius = centre - thickness / 2;
            c.lineWidth = thickness;
            c.lineCap = "round";
            // The unlit remainder, so the ring is a ring rather than a comet.
            c.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.18);
            c.beginPath();
            c.arc(centre, centre, radius, 0, Math.PI * 2);
            c.stroke();
            c.strokeStyle = root.color;
            c.beginPath();
            c.arc(centre, centre, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * root.sweep);
            c.stroke();
        }

        Connections {
            target: root
            function onColorChanged() { arc.requestPaint(); }
            function onSweepChanged() { arc.requestPaint(); }
        }
    }

    // Rotating the painted item costs one transform per frame; repainting the
    // canvas would cost a full rasterisation.
    RotationAnimator {
        target: arc
        from: 0
        to: 360
        duration: Motion.spin
        loops: Animation.Infinite
        running: root.running && root.visible
    }
}
