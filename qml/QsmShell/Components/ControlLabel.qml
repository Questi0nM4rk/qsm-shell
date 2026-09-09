pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Style

// The one label element for naming a control from outside it: a glyph, a
// text, a required mark, in the muted label role. `Field` puts it above a
// text box; `Slider` puts it on any of its four sides. It is the same element
// in both places so the two never drift into two label styles.
//
// `clickable` makes it an action surface with the five states through
// `StateLayer` and a hit box at least one large icon tall, whatever its text
// measures. The hit box overflows the footprint rather than growing it: when
// it grew the footprint, a slider's track moved the moment its label became
// clickable. What the click means is the host's: a slider's mute, a field's
// focus. Off, it is a caption and takes no pointer.
Item {
    id: root

    property string text: ""
    property string icon: ""
    property bool required: false
    property bool clickable: false

    signal clicked()

    readonly property bool hasContent: text !== "" || icon !== ""
    readonly property color _painted: root.enabled ? Style.textMuted : Style.disabled(Style.textMuted)

    visible: hasContent
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Style.space1

        Loader {
            active: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: SvgIcon {
                name: root.icon
                size: Style.iconSm
                color: root._painted
            }
        }
        Prose {
            visible: root.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            role: "label"
            text: root.text
            color: root._painted
        }
        // Needed, in a channel that is not colour alone.
        Prose {
            visible: root.required
            anchors.verticalCenter: parent.verticalCenter
            role: "label"
            color: root.enabled ? Style.danger : Style.disabled(Style.danger)
            text: "*"
        }
    }

    StateLayer {
        // The target, not the footprint: at least one large icon each way,
        // centred, so a two-line-tall hit box costs the layout nothing.
        anchors.centerIn: parent
        width: Math.max(parent.width, root.clickable ? Style.iconLg : 0)
        height: Math.max(parent.height, root.clickable ? Style.iconLg : 0)
        target: root
        interactive: root.clickable && root.enabled
        focusRadius: Style.radiusSm
        onClicked: root.clicked()
    }
}
