import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

Rectangle {
    id: root
    property string placeholder: ""
    property alias text: input.text
    property bool compact: false
    property bool horizontalKeys: false
    property bool interceptLeft: false
    property bool interceptDelete: false
    property bool interceptTab: false
    signal accepted
    signal escaped
    signal moveUp
    signal moveDown
    signal movePrev
    signal moveNext
    signal removeRequested
    signal movedBack
    signal focusNext
    signal focusPrevious
    // Consumer owns keyboard/pointer selection policy.
    signal selectionClaimed
    readonly property int fieldTextSize: compact ? Style.textMd : Style.textLg
    function focusField(): void { input.forceActiveFocus(); }
    function setText(value: string): void { input.text = value; }
    implicitHeight: compact ? Style.controlHeight : Style.controlHeightLg
    radius: Style.radiusMd
    color: Style.surface
    border.width: input.activeFocus ? 1 : 0
    border.color: Style.accent
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.space3
        anchors.rightMargin: Style.space3
        spacing: Style.space3
        SvgIcon { name: "search"; size: root.compact ? Style.iconMd : 26; color: input.activeFocus ? Style.text : Style.textMuted }
        Item {
            Layout.fillWidth: true
            implicitHeight: root.fieldTextSize * 1.8
            Prose { anchors.fill: parent; visible: input.text.length === 0; role: "label"; muted: true; font.pixelSize: root.fieldTextSize; verticalAlignment: Text.AlignVCenter; text: root.placeholder }
            TextInput {
                id: input
                anchors.fill: parent
                color: Style.text
                selectionColor: Style.accent
                selectedTextColor: Style.background
                verticalAlignment: TextInput.AlignVCenter
                font.family: Style.fontFamily
                font.pixelSize: root.fieldTextSize
                clip: true
                onTextEdited: root.selectionClaimed()
                Keys.onUpPressed: { root.selectionClaimed(); root.moveUp(); }
                Keys.onDownPressed: { root.selectionClaimed(); root.moveDown(); }
                Keys.onReturnPressed: { root.selectionClaimed(); root.accepted(); }
                Keys.onEnterPressed: { root.selectionClaimed(); root.accepted(); }
                Keys.onEscapePressed: root.escaped()
                Keys.onDeletePressed: event => { if (root.interceptDelete) { root.selectionClaimed(); root.removeRequested(); } else event.accepted = false; }
                Keys.onLeftPressed: event => { if (root.interceptLeft) { root.selectionClaimed(); root.movedBack(); } else if (root.horizontalKeys) { root.selectionClaimed(); root.movePrev(); } else event.accepted = false; }
                Keys.onRightPressed: event => { if (root.horizontalKeys) { root.selectionClaimed(); root.moveNext(); } else event.accepted = false; }
                Keys.onPressed: event => { if (root.interceptTab && event.key === Qt.Key_Tab) { root.selectionClaimed(); if (event.modifiers & Qt.ShiftModifier) root.focusPrevious(); else root.focusNext(); } }
            }
        }
    }
}
