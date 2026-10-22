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
// says which direction is welcome and defaults to none instead of assuming. The
// arrow carries the direction; a worsening trend adds a warning glyph, because
// the success and warning hues share one luminance and hue alone would read the
// same in greyscale.
//
// Natural width is the constant `contentWidth`, never the text: a long reading
// or label elides inside it, so a ticking value cannot resize the control.
// Everything sits at the start of its row: the reading row ends in a spacer
// that takes the slack, because a layout with nothing left to stretch spreads
// its items apart; the label row ends in the label, which fills it.
ColumnLayout {
    id: root

    required property string value
    property string label: ""
    property string unit: ""
    property string icon: ""
    // "" | "up" | "down" | "flat"
    property string trend: ""
    // Which direction is welcome. "up" | "down" | "none"
    property string good: "none"
    // hero for a clock, display for a card reading.
    property string emphasis: "display"
    // The constant natural width; a host that needs another one states it.
    property real contentWidth: Style.statWidth

    readonly property var _trends: ["", "up", "down", "flat"]
    readonly property var _goods: ["up", "down", "none"]
    readonly property bool _trendKnown: _trends.indexOf(trend) >= 0
    readonly property bool _goodKnown: _goods.indexOf(good) >= 0
    readonly property bool _directional: trend === "up" || trend === "down"
    readonly property bool _unwelcome: _directional && (good === "up" || good === "down") && trend !== good
    readonly property bool _welcome: _directional && trend === good
    // A unit and a trend belong to a reading; without one they would describe nothing.
    readonly property bool _measured: value.length > 0

    readonly property color _trendColor: {
        if (!_directional || good === "none" || !_goodKnown)
            return Style.textMuted;
        return trend === good ? Style.success : Style.warning;
    }

    // What colour and shape say, in words, for a reader that sees neither.
    readonly property string _trendWords: {
        if (!root._measured)
            return "";
        const direction = { up: qsTr("rising"), down: qsTr("falling"), flat: qsTr("steady") }[trend] ?? "";
        const verdict = root._unwelcome ? qsTr("worse") : root._welcome ? qsTr("better") : "";
        return [direction, verdict].filter(word => word.length > 0).join(", ");
    }

    // A readout: one name for the whole figure, never its parts.
    Accessible.role: Accessible.StaticText
    Accessible.name: [root.label, root._measured ? root.value + root.unit : qsTr("no reading"), root._trendWords]
        .filter(part => part.length > 0).join(", ")

    // A misspelt trend or good must not pass for a plausible reading, so it is
    // reported and drawn as nothing rather than as a fallback glyph.
    function _checkTrend(): void {
        Style.expect("Stat", "trend", trend, _trends);
    }
    function _checkGood(): void {
        Style.expect("Stat", "good", good, _goods);
    }
    Component.onCompleted: {
        _checkTrend();
        _checkGood();
    }
    onTrendChanged: _checkTrend()
    onGoodChanged: _checkGood()

    spacing: Style.space1

    RowLayout {
        Layout.preferredWidth: root.contentWidth
        Layout.maximumWidth: root.contentWidth
        spacing: Style.spaceTight

        // No reading yet is a dash, not a blank: an empty figure reads as a
        // control that failed to draw.
        Prose {
            Layout.fillWidth: true
            // Whole pixels: a layout rounds a width it hands out, and one
            // short of the text elides it.
            Layout.maximumWidth: Math.ceil(implicitWidth)
            Layout.alignment: Qt.AlignBaseline
            role: root.emphasis
            technical: true
            muted: !root._measured
            font.weight: root._measured ? Style.weightBold : Style.weightRegular
            text: root._measured ? root.value : "—"
            Accessible.ignored: true
        }
        // The unit is half the reading's size and sits on its baseline: "72"
        // and "%" at one size makes the unit compete with the number.
        Prose {
            Layout.alignment: Qt.AlignBaseline
            visible: root._measured && root.unit.length > 0
            role: root.emphasis === "hero" ? "heading" : "title"
            technical: true
            muted: true
            text: root.unit
            Accessible.ignored: true
        }
        SvgIcon {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Style.spaceTight
            visible: root._measured && root.trend.length > 0 && root._trendKnown
            name: root.trend === "up" ? "chevron-up"
                : root.trend === "down" ? "chevron-down"
                : root.trend === "flat" ? "minus"
                : ""
            size: Style.iconSm
            color: root._trendColor
        }
        SvgIcon {
            Layout.alignment: Qt.AlignVCenter
            visible: root._measured && root._unwelcome
            name: "alert-triangle"
            size: Style.iconXs
            color: Style.warning
        }
        Item { Layout.fillWidth: true }
    }

    RowLayout {
        Layout.preferredWidth: root.contentWidth
        Layout.maximumWidth: root.contentWidth
        visible: root.label.length > 0
        spacing: Style.spaceTight

        SvgIcon {
            visible: root.icon.length > 0
            name: root.icon
            size: Style.iconXs
            color: Style.textMuted
        }
        Prose {
            Layout.fillWidth: true
            role: "metadata"
            text: root.label
            Accessible.ignored: true
        }
    }
}
