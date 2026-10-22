import QtQuick
import QtQuick.Shapes

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
// nothing, and the outcome is the point — the surface that started the work
// replaces this with the result, success or failure.
Item {
    id: root

    // The ring's box, on the icon scale: one spinner next to one glyph.
    property real size: Style.iconMd
    property color color: Style.primary
    // How much of the ring is drawn. A short arc reads as faster at the same
    // period, which is the cheapest way to say "busy" without spinning harder.
    property real sweep: 0.28
    // Stop the animation without removing the mark — for a surface that is
    // hidden but not destroyed, so an off-screen spinner is not burning a
    // frame. A stopped spinner draws only the unlit ring: a frozen arc would
    // read as a fraction, and a spinner has none to report.
    property bool running: true
    property string accessibleName: ""
    // Whether the arc is being turned right now: `running` AND on screen.
    readonly property bool turning: rotor.running

    // Proportional to the ring, because a fixed stroke on a 12px spinner is a
    // disc and on a 48px one is a hairline. In whole device pixels, so the ring
    // is the same weight on every monitor. It sits INSIDE the box: a stroke
    // centred on the boundary would lose half its width to the clip.
    readonly property real _stroke: Style.stroke(root.size * Style.spinnerStrokeRatio, root)
    readonly property real _radius: (root.size - root._stroke) / 2

    implicitWidth: size
    implicitHeight: size

    // A busy indicator with no total: a progress bar that reports no value.
    Accessible.role: Accessible.ProgressBar
    Accessible.name: root.accessibleName

    // Vector, not a bitmap: a Canvas rasterises at the item's LOGICAL size and
    // the compositor stretches it by the monitor scale, which softened every
    // edge, and rotating that texture resampled it again on every frame. The
    // curve renderer draws the arc at the window's own resolution.
    component Ring: Shape {
        id: ring
        property color ringColor: root.color
        property real sweepAngle: 360
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: ring.ringColor
            strokeWidth: root._stroke
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root._radius
                radiusY: root._radius
                startAngle: -90
                sweepAngle: ring.sweepAngle
            }
        }
    }

    // The unlit remainder, so the ring is a ring rather than a comet.
    Ring {
        ringColor: Qt.rgba(root.color.r, root.color.g, root.color.b, Style.ringTrackOpacity)
    }

    // Turning the lit arc costs one transform per frame. Constant motion is
    // linear: an eased turn would stall once per revolution.
    Ring {
        id: arc
        visible: root.running
        sweepAngle: 360 * root.sweep

        RotationAnimator on rotation {
            id: rotor
            from: 0
            to: 360
            duration: Motion.spin
            loops: Animation.Infinite
            running: root.running && root.visible
        }
    }
}
