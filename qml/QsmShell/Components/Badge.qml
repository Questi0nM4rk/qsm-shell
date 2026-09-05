import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// A small marker that says what STATE a thing is in: a pending count riding a
// cell's corner, a "connected" next to a network name, an unread dot.
//
// One axis: `tone`, which is the semantic status set and nothing else. There
// is no "blue badge" and no "big badge", because a badge that has to be told
// how to look is a badge the surface is styling by hand again.
//
// Meaning never travels in the colour alone (`tone` is a hue, and a hue is
// invisible to a good number of people and to anyone glancing). A badge
// therefore carries TEXT, or an ICON, or both — `dot` is the one exception,
// and it exists only for "there is something here", which is a presence
// signal rather than a state.
Rectangle {
    id: root

    // neutral | accent | success | warning | danger | info
    property string tone: "neutral"
    property string text: ""
    property string icon: ""
    // Presence only: a filled circle with no reading. Use it for "unread",
    // never for a state a person has to distinguish from another state.
    property bool dot: false
    // Filled reads louder than tinted. A count that must be noticed is filled;
    // a status that merely accompanies a name is not.
    property bool filled: false

    readonly property color _tone: {
        switch (tone) {
        case "accent": return Style.accent;
        case "success": return Style.success;
        case "warning": return Style.warning;
        case "danger": return Style.danger;
        case "info": return Style.info;
        default: return Style.textMuted;
        }
    }
    // On a filled badge the reading sits ON the tone, so it takes the ground
    // colour rather than the text colour — text-on-accent is the one place
    // this palette cannot be read.
    readonly property color _prose: filled ? Style.background : _tone

    implicitHeight: dot ? Style.spaceTight * 2 + Style.space1 : Style.badgeHeight
    // A single character stays circular; anything longer grows into a pill
    // rather than stretching the glyph's own box.
    implicitWidth: dot
        ? implicitHeight
        : Math.max(implicitHeight, content.implicitWidth + Style.space2)
    radius: height / 2
    color: filled ? _tone : Qt.rgba(_tone.r, _tone.g, _tone.b, 0.18)
    visible: dot || text.length > 0 || icon.length > 0

    Behavior on color {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    RowLayout {
        id: content
        anchors.centerIn: parent
        visible: !root.dot
        spacing: Style.spaceTight

        SvgIcon {
            visible: root.icon.length > 0
            name: root.icon
            size: Style.iconXs
            color: root._prose
        }
        Prose {
            visible: root.text.length > 0
            // A count must not resize the badge as it ticks 9 → 10, which is
            // exactly what the proportional face does.
            role: "reading"
            font.pixelSize: Style.textXs
            color: root._prose
            text: root.text
        }
    }
}
