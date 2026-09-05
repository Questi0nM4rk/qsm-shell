import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// One number, read at a glance, with what it is underneath it.
//
// The reading comes FIRST and largest. A stat whose label outweighs its value
// is a label with a number attached, and a dashboard of those has no focal
// point at all — which is the same as having nothing emphasised.
//
// `trend` is the one place this component spends colour, and it earns it:
// up-is-good is not universal (latency, temperature, disk usage), so `good`
// says which direction is welcome instead of assuming. The arrow carries the
// direction, the hue only reinforces it.
ColumnLayout {
    id: root

    required property string value
    property string label: ""
    property string unit: ""
    property string icon: ""
    // "" | "up" | "down" | "flat"
    property string trend: ""
    // Which direction is welcome. "up" | "down" | "none"
    property string good: "up"
    // hero for a clock, display for a card reading.
    property string emphasis: "display"

    readonly property color _trendColor: {
        if (trend === "" || trend === "flat" || good === "none")
            return Style.textMuted;
        return trend === good ? Style.success : Style.warning;
    }

    spacing: Style.spaceTight

    RowLayout {
        Layout.alignment: Qt.AlignLeft
        spacing: Style.space1

        Prose {
            role: root.emphasis
            text: root.value
        }
        // The unit is smaller and sits on the reading's own baseline: "72" and
        // "%" at one size makes the unit compete with the number.
        Prose {
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: Style.spaceTight
            visible: root.unit.length > 0
            role: "reading"
            muted: true
            text: root.unit
        }
        SvgIcon {
            Layout.alignment: Qt.AlignVCenter
            visible: root.trend.length > 0
            name: root.trend === "up" ? "chevron-up"
                : root.trend === "down" ? "chevron-down"
                : "minus"
            size: Style.iconSm
            color: root._trendColor
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignLeft
        visible: root.label.length > 0
        spacing: Style.spaceTight

        SvgIcon {
            visible: root.icon.length > 0
            name: root.icon
            size: Style.iconXs
            color: Style.textMuted
        }
        Prose {
            role: "metadata"
            text: root.label
        }
    }
}
