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
    // Luminous text, not the accent: a trend is a passive reading.
    property color color: Style.text
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

    // A twelfth of the height, in whole device pixels: a fractional weight
    // paints a flat run as two soft rows instead of one crisp one.
    readonly property real _thickness: thickness > 0
        ? thickness
        : Style.stroke(height / 12, root)

    readonly property real _min: isNaN(minimum) ? Math.min(...(values.length > 0 ? values : [0])) : minimum
    readonly property real _max: isNaN(maximum) ? Math.max(...(values.length > 0 ? values : [1])) : maximum

    // A preset NAME of the size table (the Control family's): the height, and
    // the width is three of it, the proportion a trend reads best in.
    property string size: "md"
    implicitHeight: Style.size("Sparkline", root.size)
    implicitWidth: implicitHeight * 3

    // A graphic with a text equivalent: how many values and where the series
    // starts and ends. A host whose neighbour already says it sets
    // `Accessible.ignored`.
    function _say(value: real): string {
        return String(Number(Number(value).toPrecision(3)));
    }
    Accessible.role: Accessible.Graphic
    Accessible.name: values.length === 0 ? qsTr("Trend, no data")
        : values.length === 1 ? qsTr("Trend, one value, %1").arg(root._say(values[0]))
        : qsTr("Trend, %1 values, from %2 to %3").arg(values.length)
            .arg(root._say(values[0])).arg(root._say(values[values.length - 1]))

    onPaint: {
        const c = getContext("2d");
        c.reset();
        const points = root.values;
        const thickness = root._thickness;

        // Round caps reach thickness/2 past each end, so the run is inset by
        // that much and the stroke stays inside the box.
        const left = thickness / 2;
        const right = root.width - thickness / 2;
        const usable = root.height - thickness;
        // A flat series centres its line, with the stroke's top edge on a
        // device row so the line is one crisp run.
        const dpr = root.Window.window?.devicePixelRatio ?? 1;
        const flatY = Math.round(usable / 2 * dpr) / dpr + thickness / 2;

        // Nothing yet is a quiet line on the floor and one sample is a dot at
        // the end, so a first-sample box never reads as a graph that failed.
        if (points.length < 2) {
            c.strokeStyle = root.color;
            c.lineWidth = thickness;
            c.lineCap = "round";
            c.beginPath();
            if (points.length === 0) {
                c.moveTo(left, root.height - thickness / 2);
                c.lineTo(right, root.height - thickness / 2);
                c.stroke();
            } else {
                c.fillStyle = root.color;
                const span = root._max - root._min;
                const y = span === 0
                    ? flatY
                    : thickness / 2 + usable - (Math.min(Math.max(points[0], root._min), root._max) - root._min) / span * usable;
                c.arc(right, y, thickness / 2, 0, 2 * Math.PI);
                c.fill();
            }
            return;
        }

        // A flat series has no span to divide by, and a zero span would put
        // every point on the same line by dividing by zero rather than by
        // being flat. Centre it instead. A value past a pinned extent sits on
        // that extent, so the stroke never leaves the box.
        const span = root._max - root._min;
        const step = (right - left) / (points.length - 1);
        const yOf = value => span === 0
            ? flatY
            : thickness / 2 + usable - ((Math.min(Math.max(value, root._min), root._max) - root._min) / span) * usable;

        const trace = () => {
            c.beginPath();
            c.moveTo(left, yOf(points[0]));
            for (let i = 1; i < points.length; i++)
                c.lineTo(left + i * step, yOf(points[i]));
        };

        if (root.area) {
            trace();
            c.lineTo(right, root.height);
            c.lineTo(left, root.height);
            c.closePath();
            c.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, Style.areaFillOpacity);
            c.fill();
        }

        trace();
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
