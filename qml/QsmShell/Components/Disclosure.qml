import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// A heading that opens.
//
// The trigger is narrow on purpose: advanced or rare detail, collapsed, with
// the surface working sensibly for someone who never opens it. It is NOT a way
// to fit a primary path into a small space — hiding the main thing behind a
// chevron makes it undiscoverable, and undiscoverable is indistinguishable
// from absent.
//
// The whole heading is the target, not just the chevron: a 12px glyph is well
// under any usable size, and a person aiming at a word they can read is aiming
// at the thing they mean.
//
// The chevron ROTATES rather than swapping glyphs, because the rotation is
// what says the two states are one thing in two positions.
ColumnLayout {
    id: root

    property string title: ""
    property string icon: ""
    property bool expanded: false
    // A count or a state on the closed heading, so the group says something
    // about its contents without being opened.
    property string badge: ""
    property bool focused: root.activeFocus

    default property alias content: bodyHost.data

    signal toggled(bool expanded)

    spacing: Style.space1

    Item {
        id: heading
        Layout.fillWidth: true
        implicitHeight: Style.controlHeightSm

        RowLayout {
            anchors.fill: parent
            spacing: Style.space2

            SvgIcon {
                id: chevron
                name: "chevron-right"
                size: Style.iconSm
                color: Style.textMuted
                rotation: root.expanded ? 90 : 0

                Behavior on rotation {
                    NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
                }
            }
            SvgIcon {
                visible: root.icon.length > 0
                name: root.icon
                size: Style.iconSm
                color: Style.text
            }
            Prose {
                Layout.fillWidth: true
                role: "label"
                text: root.title
            }
            Badge {
                visible: root.badge.length > 0
                text: root.badge
            }
        }

        StateLayer {
            anchors.fill: parent
            // The CHEVRON answers: it is the part that means "there is more",
            // and growing the whole heading shoves the rows below it.
            target: chevron
            focused: root.focused
            focusRadius: Style.radiusSm
            hoverScale: 1.15
            pressScale: 0.88
            onClicked: root.toggled(!root.expanded)
        }
    }

    // Collapsed content is not merely invisible — it is not laid out, so a
    // closed group takes exactly its heading's height and the rhythm of the
    // surface around it does not change.
    ColumnLayout {
        id: bodyHost
        Layout.fillWidth: true
        Layout.leftMargin: Style.space5
        visible: root.expanded
        spacing: Style.space1
    }

    Keys.onSpacePressed: root.toggled(!root.expanded)
    Keys.onReturnPressed: root.toggled(!root.expanded)
}
