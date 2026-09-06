import QtQuick

import qs.QsmShell.Style

// A trend, small enough to sit beside the number it explains.
//
// It carries SHAPE, not values: whether a thing is climbing, settling or
// spiking. That is why there are no axes, no gridlines and no labels — every
// one of them would ask to be read, and a sparkline is meant to be recognised.
// A reading anybody has to measure off this belongs in a real chart.
//
// The scale comes from the data unless the consumer pins it. Auto-scaling
// makes flat data look dramatic, so a series with a known domain (a
// percentage, a load average) should say so with `minimum` and `maximum`.
Canvas {
    id: root

    property var values: []
    property color color: Style.accent
    // Out of range means "take it from the data".
    property real minimum: NaN
    property real maximum: NaN
    // Shade under the line. Reads as volume rather than as a path — right for
    // a quantity, wrong for a rate.
    property bool area: false
    // 0 = derive from the height, which is right for one line in a small box.
    // A consumer STACKING two series on one scale has to state it: at the
    // derived weight two lines in a 56px box are ~4.7px each and merge into a
    // band, which reads as one thick trend rather than as two.
    property real thickness: 0

    readonly property real _thickness: thickness > 0
        ? thickness
        : Math.max(1, height / 12)

    readonly property real _min: isNaN(minimum) ? Math.min(...(values.length > 0 ? values : [0])) : minimum
    readonly property real _max: isNaN(maximum) ? Math.max(...(values.length > 0 ? values : [1])) : maximum

    implicitWidth: Style.controlHeightLg * 2
    implicitHeight: Style.controlHeightSm

    onPaint: {
        const c = getContext("2d");
        c.reset();
        const points = root.values;
        if (points.length < 2)
            return;

        // A flat series has no span to divide by, and a zero span would put
        // every point on the same line by dividing by zero rather than by
        // being flat. Centre it instead.
        const span = root._max - root._min;
        const thickness = root._thickness;
        const usable = root.height - thickness;
        const step = root.width / (points.length - 1);
        const yOf = value => span === 0
            ? root.height / 2
            : thickness / 2 + usable - ((value - root._min) / span) * usable;

        c.beginPath();
        c.moveTo(0, yOf(points[0]));
        for (let i = 1; i < points.length; i++)
            c.lineTo(i * step, yOf(points[i]));

        if (root.area) {
            c.lineTo(root.width, root.height);
            c.lineTo(0, root.height);
            c.closePath();
            c.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.18);
            c.fill();
            c.beginPath();
            c.moveTo(0, yOf(points[0]));
            for (let i = 1; i < points.length; i++)
                c.lineTo(i * step, yOf(points[i]));
        }

        c.lineWidth = thickness;
        c.lineCap = "round";
        c.lineJoin = "round";
        c.strokeStyle = root.color;
        c.stroke();
    }

    // EVERY painted input needs a trigger. A Canvas repaints when it is told
    // to and at no other time, so a property that changes the picture and has
    // no handler here leaves stale pixels until something else happens to
    // change.
    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onAreaChanged: requestPaint()
    onThicknessChanged: requestPaint()
    onMinimumChanged: requestPaint()
    onMaximumChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
