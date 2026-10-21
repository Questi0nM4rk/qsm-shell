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

    readonly property color _trendColor: {
        if (!_directional || good === "none" || !_goodKnown)
            return Style.textMuted;
        return trend === good ? Style.success : Style.warning;
    }

    // A misspelt trend or good must not pass for a plausible reading, so it is
    // reported and drawn as nothing rather than as a fallback glyph.
    function _checkTrend(): void {
        if (!_trendKnown)
            console.error(`Stat: unknown trend "${trend}" -- expected "", "up", "down" or "flat"`);
    }
    function _checkGood(): void {
        if (!_goodKnown)
            console.error(`Stat: unknown good "${good}" -- expected "up", "down" or "none"`);
    }
    Component.onCompleted: {
        _checkTrend();
        _checkGood();
    }
    onTrendChanged: _checkTrend()
    onGoodChanged: _checkGood()

    spacing: Style.spaceTight

    RowLayout {
        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: root.contentWidth
        Layout.maximumWidth: root.contentWidth
        spacing: Style.space1

        Prose {
            Layout.fillWidth: true
            Layout.maximumWidth: implicitWidth
            role: root.emphasis
            technical: true
            text: root.value
        }
        // The unit is smaller and sits on the reading's own baseline: "72" and
        // "%" at one size makes the unit compete with the number.
        Prose {
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: Style.spaceTight
            visible: root.unit.length > 0
            role: "label"
            technical: true
            muted: true
            text: root.unit
        }
        SvgIcon {
            Layout.alignment: Qt.AlignVCenter
            visible: root.trend.length > 0 && root._trendKnown
            name: root.trend === "up" ? "chevron-up"
                : root.trend === "down" ? "chevron-down"
                : root.trend === "flat" ? "minus"
                : ""
            size: Style.iconSm
            color: root._trendColor
        }
        SvgIcon {
            Layout.alignment: Qt.AlignVCenter
            visible: root._unwelcome
            name: "alert-triangle"
            size: Style.iconXs
            color: Style.warning
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignLeft
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
            Layout.maximumWidth: implicitWidth
            role: "metadata"
            text: root.label
        }
    }
}
