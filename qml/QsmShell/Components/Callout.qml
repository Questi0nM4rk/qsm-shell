import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// An inline message that stays: something failed, something is degraded,
// something needs saying before the person acts.
//
// WHY inline and not a toast: a toast leaves, and a condition that is still
// true must not. The rule is the trigger — a callout reports a STATE of the
// surface it sits in, a notification reports an EVENT that happened
// elsewhere. Anything that would still be true a minute from now belongs here.
//
// Every tone carries an icon as well as a hue, and the icon is not
// configurable per tone by accident: colour alone is invisible to a good share
// of people and to everyone glancing, so the mark is the channel that always
// works and the hue is the one that helps.
//
// An error message owes three things: what failed, where, and what to do about
// it. `title` and `body` carry the first two; the third goes in the action
// slot, because a callout that only apologises has moved the problem to the
// person without moving them any closer to solving it.
Card {
    id: root

    // Flat inside the surface that holds it.
    glow: false
    shadow: false

    // info | success | warning | danger
    property string tone: "info"
    property string title: ""
    property string body: ""
    // Overrides the tone's own mark. Only for a condition whose meaning is
    // more specific than its severity ("offline", "muted").
    property string icon: ""
    // Consumer-owned recovery controls.
    default property alias actions: actionHost.data

    readonly property color _tone: {
        switch (tone) {
        case "success": return Style.success;
        case "warning": return Style.warning;
        case "danger": return Style.danger;
        default: return Style.info;
        }
    }
    readonly property string _icon: {
        if (icon.length > 0)
            return icon;
        switch (tone) {
        case "success": return "circle-check";
        case "warning": return "alert-triangle";
        case "danger": return "circle-alert";
        default: return "info";
        }
    }

    implicitHeight: content.implicitHeight + Style.space3 * 2
    implicitWidth: content.implicitWidth + Style.space3 * 2 + rule.width
    radius: Style.radiusMd
    surfaceColor: Qt.tint(Style.surface, Qt.rgba(_tone.r, _tone.g, _tone.b, 0.1))
    // The severity rule runs the full height flush against the leading edge,
    // and Qt clamps a rectangle's radius to half its SHORT side -- so a 3px
    // rule cannot curve at the card's 12px corner and pokes out of it at both
    // ends. Clipping is the honest fix; the render pass is paid only while a
    // callout exists, which is only when something has gone wrong.
    clip: true

    // The severity rule down the leading edge. It is the third channel — after
    // the mark and the hue — and the only one readable from the corner of an
    // eye that is looking somewhere else.
    Rectangle {
        id: rule
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Style.markThickness
        color: root._tone
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: Style.space3 + rule.width
        anchors.rightMargin: Style.space3
        anchors.topMargin: Style.space3
        anchors.bottomMargin: Style.space3
        spacing: Style.space3

        SvgIcon {
            Layout.alignment: Qt.AlignTop
            name: root._icon
            size: Style.iconMd
            color: root._tone
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space1

            Prose {
                Layout.fillWidth: true
                visible: root.title.length > 0
                role: "title"
                text: root.title
            }
            Prose {
                Layout.fillWidth: true
                visible: root.body.length > 0
                role: "body"
                muted: true
                text: root.body
            }
            RowLayout {
                id: actionHost
                Layout.fillWidth: true
                Layout.topMargin: children.length > 0 ? Style.space1 : 0
                spacing: Style.space2
            }
        }
    }
}
