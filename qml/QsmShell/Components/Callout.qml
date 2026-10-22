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
Rectangle {
    id: root

    // info | success | warning | danger
    property string tone: "info"
    property string title: ""
    property string body: ""
    // Overrides the tone's own mark. Only for a condition whose meaning is
    // more specific than its severity ("offline", "muted").
    property string icon: ""
    // Consumer-owned recovery controls.
    default property alias actions: actionHost.data

    readonly property var _tones: ({
        info: { color: Style.info, icon: "info" },
        success: { color: Style.success, icon: "circle-check" },
        warning: { color: Style.warning, icon: "alert-triangle" },
        danger: { color: Style.danger, icon: "circle-alert" }
    })
    readonly property bool _toneKnown: _tones[tone] !== undefined
    readonly property var _kind: _tones[tone] ?? _tones.info
    readonly property color _tone: _kind.color
    readonly property string _icon: icon.length > 0 ? icon : _kind.icon

    // QML cannot throw out of a binding, so an unknown tone or icon is
    // reported on the error stream and drawn as info / nothing.
    on_ToneKnownChanged: _checkTone()
    Component.onCompleted: _checkTone()
    function _checkTone() {
        if (!_toneKnown)
            console.error(`Callout: unknown tone "${tone}" -- expected info, success, warning or danger`);
    }

    // What is wrong interrupts, what is merely so does not.
    Accessible.role: tone === "warning" || tone === "danger" ? Accessible.AlertMessage : Accessible.Note
    Accessible.name: root.title
    Accessible.description: root.body

    implicitHeight: content.implicitHeight + Style.space3 * 2
    // Constant: long copy wraps and elides inside it; a host sets `width`.
    implicitWidth: Style.controlWidth
    radius: Style.radiusBody
    color: Qt.tint(Style.surface, Qt.rgba(_tone.r, _tone.g, _tone.b, Style.calloutTintOpacity))

    // The severity rule down the leading edge. It is the third channel — after
    // the mark and the hue — and the only one readable from the corner of an
    // eye that is looking somewhere else.
    Rectangle {
        id: rule
        anchors.left: parent.left
        // Starts where the corner arc meets the leading edge: Item.clip only
        // clips to the rectangle, so a full-height rule would poke out of the
        // rounded corners.
        anchors.top: parent.top
        anchors.topMargin: root.radius
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.radius
        width: Style.stroke(Style.markThickness, root)
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

        // The mark centres on the first line of copy, whatever its height.
        SvgIcon {
            readonly property real _firstLine: root.title.length > 0 ? titleText.implicitHeight
                : root.body.length > 0 ? bodyText.implicitHeight : 0
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: _firstLine > 0 ? Math.round((_firstLine - size) / 2) : 0
            name: root._icon
            size: Style.iconMd
            color: root._tone
        }
        ColumnLayout {
            Layout.fillWidth: true
            // Without copy the column's own ceiling is the action's width, and
            // the row would centre it away from the mark.
            Layout.maximumWidth: Infinity
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            spacing: 0

            Prose {
                id: titleText
                Layout.fillWidth: true
                visible: root.title.length > 0
                role: "title"
                text: root.title
            }
            Prose {
                id: bodyText
                Layout.fillWidth: true
                visible: root.body.length > 0
                Layout.topMargin: root.title.length > 0 ? Style.space1 : 0
                role: "body"
                muted: true
                text: root.body
            }
            RowLayout {
                id: actionHost
                Layout.fillWidth: true
                // One space1 gap below the copy, and none when no action shows:
                // an empty host has zero implicit height.
                Layout.topMargin: implicitHeight > 0 && (root.title.length > 0 || root.body.length > 0) ? Style.space1 : 0
                spacing: Style.space2
            }
        }
    }
}
