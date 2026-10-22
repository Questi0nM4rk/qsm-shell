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
// therefore carries TEXT, or an ICON, or both — `dot` is the one exception:
// a filled circle that says "there is something here" and nothing more. It
// takes `tone` like any badge (neutral until a host says otherwise) and is
// always filled, because a 12 % tint of an 8 px disc is not a mark.
Rectangle {
    id: root

    // neutral | accent | success | warning | danger | info
    property string tone: "neutral"
    property string text: ""
    property string icon: ""
    // What a screen reader says when `text` does not say it: the dot and the
    // icon-only form have no reading of their own.
    property string accessibleName: ""
    // Presence only: a filled circle with no reading. Use it for "unread" or a
    // status riding a picture; whatever it means must also reach a screen
    // reader through `accessibleName`, because a hue alone does not.
    property bool dot: false
    // Filled reads louder than tinted. A count that must be noticed is filled;
    // a status that merely accompanies a name is not.
    property bool filled: false

    // An unknown tone is reported (`Style.expect`) and drawn neutral.
    readonly property color _tone: Style.tones[tone] ?? Style.tones.neutral
    // On a filled badge the reading sits ON the tone, so it takes the ground
    // colour rather than the text colour — text-on-accent is the one place
    // this palette cannot be read.
    // A tinted badge's reading is its tone pulled toward the text colour:
    // the bare tone on its own tint is below 4.5:1 at this size.
    readonly property color _prose: filled ? Style.textOnPrimary
        : Qt.tint(_tone, Qt.rgba(Style.text.r, Style.text.g, Style.text.b, Style.badgeInkMix))
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
    // rather than stretching the glyph's own box, one end radius of air on
    // each side so the first letter starts where the curve ends (a lone glyph
    // is the circle). A marker is not a paragraph: past `_maxWidth` the
    // reading elides.
    readonly property real _maxWidth: Style.rhythm(Style.controlWidth / 3)
    readonly property real _padding: root.text.length > 0 ? Style.space4 : 0
    implicitWidth: dot
        ? implicitHeight
        : root._count ? Style.badgeWidth
        : Math.min(root._maxWidth, Math.max(implicitHeight, content.implicitWidth + root._padding))
    radius: Style.radiusPill
    color: filled || dot ? _tone : Qt.rgba(_tone.r, _tone.g, _tone.b, Style.badgeTintOpacity)
    visible: dot || text.length > 0 || icon.length > 0

    Accessible.role: Accessible.StaticText
    Accessible.name: accessibleName !== "" ? accessibleName : text
    Accessible.ignored: !visible

    function _checkName(): void {
        if (visible && accessibleName === "" && text === "")
            console.warn("Badge: a dot or icon-only badge has no accessibleName -- a screen reader hears nothing")
    }
    Component.onCompleted: {
        _checkName()
        Style.expect("Badge", "tone", tone, Object.keys(Style.tones))
    }
    onVisibleChanged: _checkName()
    onToneChanged: Style.expect("Badge", "tone", tone, Object.keys(Style.tones))

    Behavior on color {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    RowLayout {
        id: content
        // A reading with no glyph beside it fills the badge and centres inside
        // it: its box then spans whole device pixels, where a row centred
        // around a fractional text width would not. A glyph and a reading
        // centre as one row.
        readonly property bool _alone: root.icon.length === 0
        x: _alone ? 0 : (root.width - width) / 2
        width: _alone ? root.width : implicitWidth
        height: root.height
        visible: !root.dot
        spacing: Style.spaceTight

        SvgIcon {
            Layout.alignment: Qt.AlignVCenter
            visible: root.icon.length > 0
            name: root.icon
            size: Style.iconXs
            color: root._ink
        }
        Prose {
            Layout.fillWidth: content._alone
            Layout.maximumWidth: root._maxWidth - root._padding - (root.icon.length > 0 ? Style.iconXs + Style.spaceTight : 0)
            Layout.alignment: content._alone ? Qt.AlignHCenter : 0
            Layout.fillHeight: true
            horizontalAlignment: content._alone ? Text.AlignHCenter : Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            visible: root.text.length > 0
            // A count is a value in the technical face, whose tabular digits
            // keep a ticking number from shifting the text inside the chip; a
            // word is a word, in the UI face.
            role: root._count ? "reading" : "label"
            color: root._ink
            text: root._shown
        }
    }
}
