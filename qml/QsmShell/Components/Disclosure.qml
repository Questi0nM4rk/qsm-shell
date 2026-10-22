import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

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
    // Keyboard focus on the heading, which is when its ring shows.
    readonly property bool focused: heading.visualFocus

    default property alias content: bodyHost.data

    signal toggled(bool expanded)
    readonly property list<T.Action> actions: [T.Action { text: "Toggle"; enabled: root.enabled; onTriggered: root.toggle() }]

    function toggle(): void {
        if (root.enabled)
            root.toggled(!root.expanded)
    }

    spacing: Style.space1

    T.AbstractButton {
        id: heading
        objectName: "disclosureHeading"
        Layout.fillWidth: true
        implicitHeight: Style.size("Disclosure", "sm")
        focusPolicy: Qt.StrongFocus
        hoverEnabled: root.enabled
        onClicked: root.toggle()
        Accessible.role: Accessible.Button
        Accessible.name: root.title
        Accessible.description: root.badge
        Accessible.expandable: true
        Accessible.expanded: root.expanded
        Accessible.onPressAction: root.toggle()
        // A held key toggles once, on release, not at the key-repeat rate.
        ActivationKeys {
            id: keys
            available: root.enabled
            onActivated: root.toggle()
        }
        Keys.forwardTo: [keys]

        // Declared before the row so the hover disc paints under the label.
        StateLayer {
            anchors.fill: parent
            // The disc over the heading is the body: it grows and tints, and
            // the chevron keeps its size. Growing the whole heading would
            // shove the rows below it, so the ratio is the chevron's.
            extent: Style.iconSm
            host: heading
            focused: root.focused
            focusRadius: Style.radiusSm
            hoverTint: true
            pressScale: Motion.pressScale
            manualPressOverride: keys.held
        }

        // The content sits a step in from the body's edges, so the chevron and
        // the badge are not pressed against the corners the disc rounds.
        RowLayout {
            id: headingRow
            anchors.fill: parent
            anchors.leftMargin: Style.space2
            anchors.rightMargin: Style.space2
            spacing: Style.space2

            SvgIcon {
                id: chevron
                name: "chevron-right"
                size: Style.iconSm
                color: root.enabled ? Style.textMuted : Style.disabled(Style.textMuted)
                rotation: root.expanded ? 90 : 0

                // A toggle from the keyboard (the ring is showing) snaps: an
                // action the hand repeats gets no animation.
                Behavior on rotation {
                    enabled: !Style.reducedMotion && !root.focused
                    NumberAnimation { duration: Motion.fast; easing.type: Motion.moveEasing }
                }
            }
            SvgIcon {
                visible: root.icon.length > 0
                name: root.icon
                size: Style.iconSm
                color: root.enabled ? Style.text : Style.disabled(Style.text)
            }
            Prose {
                id: titleLabel
                Layout.fillWidth: true
                role: "label"
                color: root.enabled ? Style.text : Style.disabled(Style.text)
                text: root.title
            }
            Badge {
                visible: root.badge.length > 0
                text: root.badge
            }
        }
    }

    // Collapsed content is not merely invisible — it is not laid out, so a
    // closed group takes exactly its heading's height and the rhythm of the
    // surface around it does not change.
    ColumnLayout {
        id: bodyHost
        Layout.fillWidth: true
        // The body hangs from the title's left edge, wherever the icon puts it.
        Layout.leftMargin: headingRow.anchors.leftMargin + titleLabel.x
        Layout.rightMargin: headingRow.anchors.rightMargin
        Layout.topMargin: Style.space2
        visible: root.expanded
        spacing: Style.space1
    }

}
