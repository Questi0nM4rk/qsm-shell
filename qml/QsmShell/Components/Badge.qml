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
// signal rather than a state, so it ignores `tone` and is always neutral.
Rectangle {
    id: root

    // neutral | accent | success | warning | danger | info
    property string tone: "neutral"
    property string text: ""
    property string icon: ""
    // What a screen reader says when `text` does not say it: the dot and the
    // icon-only form have no reading of their own.
    property string accessibleName: ""
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
        case "neutral": return Style.textMuted;
        default: throw new Error(`Badge: unknown tone "${tone}"`);
        }
    }
    readonly property color _hue: dot ? Style.textMuted : _tone
    // On a filled badge the reading sits ON the tone, so it takes the ground
    // colour rather than the text colour — text-on-accent is the one place
    // this palette cannot be read.
    // A tinted badge's reading is its tone pulled toward the text colour:
    // the bare tone on its own tint is below 4.5:1 at this size.
    readonly property color _prose: filled ? Style.textOnPrimary
        : Qt.tint(_hue, Qt.rgba(Style.text.r, Style.text.g, Style.text.b, Style.badgeInkMix))
    // The reading settles with the fill; on its own it would snap while the
    // fill is still half way between two tones.
    property color _ink: _prose
    Behavior on _ink {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    // A count is a number with a ceiling: past 99 it reads "99+". It sits in
    // one fixed chip, so 9 becoming 10 never changes the badge's width and
    // whatever is laid out beside it does not move.
    readonly property bool _count: /^\d+$/.test(root.text)
    readonly property string _shown: root._count && Number(root.text) > 99 ? "99+" : root.text

    implicitHeight: dot ? Style.badgeDot : Style.badgeHeight
    // A count takes the fixed chip; any other reading grows into a pill
    // rather than stretching the glyph's own box.
    implicitWidth: dot
        ? implicitHeight
        : root._count ? Style.badgeWidth
        : Math.max(implicitHeight, content.implicitWidth + Style.space2)
    radius: Style.radiusPill
    color: filled ? _hue : Qt.rgba(_hue.r, _hue.g, _hue.b, Style.badgeTintOpacity)
    visible: dot || text.length > 0 || icon.length > 0

    Accessible.role: Accessible.StaticText
    Accessible.name: accessibleName !== "" ? accessibleName : text
    Accessible.ignored: !visible

    function _checkName(): void {
        if (visible && accessibleName === "" && text === "")
            console.warn("Badge: a dot or icon-only badge has no accessibleName -- a screen reader hears nothing")
    }
    Component.onCompleted: _checkName()
    onVisibleChanged: _checkName()

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
            color: root._ink
        }
        Prose {
            visible: root.text.length > 0
            // The technical face has tabular digits, so a ticking number does
            // not shift the text inside the chip either.
            role: "reading"
            font.pixelSize: Style.textXs
            color: root._ink
            text: root._shown
        }
    }
}
