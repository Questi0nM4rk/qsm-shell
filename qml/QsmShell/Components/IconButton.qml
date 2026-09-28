import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

T.Control {
    id: root

    required property string icon
    property int size: Style.iconMd
    property color color: Style.text
    property string accessibleName: icon
    readonly property color paintedColor: root.enabled ? root.color : Style.disabled(root.color)
    signal clicked

    focusPolicy: Qt.StrongFocus

    implicitWidth: size + leftPadding + rightPadding
    implicitHeight: size + topPadding + bottomPadding
    padding: Style.space3

    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName

    function activate(): void {
        if (root.enabled)
            root.clicked()
    }

    readonly property list<T.Action> actions: [
        T.Action { text: root.accessibleName; enabled: root.enabled; onTriggered: root.activate() }
    ]

    contentItem: Item {
        implicitWidth: root.size
        implicitHeight: root.size

        SvgIcon {
            id: glyph
            anchors.centerIn: parent
            name: root.icon
            size: root.size
            color: root.paintedColor
        }
    }

    StateLayer {
        anchors.fill: parent
        target: glyph
        focusRadius: height / 2
        onClicked: {
            root.forceActiveFocus()
            root.activate()
        }
    }

    Keys.onReturnPressed: event => { event.accepted = true; root.activate() }
    Keys.onEnterPressed: event => { event.accepted = true; root.activate() }
    Keys.onSpacePressed: event => { event.accepted = true; root.activate() }
}
