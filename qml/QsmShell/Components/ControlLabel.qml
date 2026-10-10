pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T

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
T.Control {
    id: root

    property string text: ""
    property string icon: ""
    property bool required: false
    property bool clickable: false
    property string accessibleName: text
    // One scale per instance, set by the control this names (`Slider` its
    // own `_s`, `Field` the control it wraps): every measurement below is
    // its md-role number times this ratio.
    property real sizeScale: 1

    signal clicked()
    property bool _keyActivationHeld: false
    readonly property bool _available: root.enabled && root.clickable && root.hasContent
    readonly property list<T.Action> actions: [T.Action { objectName: "activate"; text: root.accessibleName; enabled: root._available; onTriggered: root.activate() }]

    function activate(): bool {
        if (!root._available)
            return false
        root.clicked()
        return true
    }

    function cancelKeyActivation(): void {
        root._keyActivationHeld = false
    }

    function updateAvailability(): void {
        if (root._available)
            return
        root.cancelKeyActivation()
        if (root.activeFocus)
            root.focus = false
    }

    readonly property bool hasContent: text !== "" || icon !== ""
    readonly property color _painted: root.enabled ? Style.textMuted : Style.disabled(Style.textMuted)

    visible: hasContent
    // Qt cannot remove its current Tab item; surrender focus before dropping eligibility.
    focusPolicy: _available || activeFocus ? Qt.StrongFocus : Qt.NoFocus
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Accessible.role: clickable && hasContent ? Accessible.Button : Accessible.StaticText
    Accessible.name: root.accessibleName
    Accessible.onPressAction: root.activate()

    onActiveFocusChanged: if (!activeFocus) cancelKeyActivation()
    onEnabledChanged: updateAvailability()
    onClickableChanged: updateAvailability()
    onHasContentChanged: updateAvailability()

    Keys.onPressed: event => {
        if (!root._available || (event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return && event.key !== Qt.Key_Space))
            return
        event.accepted = true
        if (event.isAutoRepeat || root._keyActivationHeld)
            return
        root._keyActivationHeld = true
    }

    Keys.onReleased: event => {
        if (event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return && event.key !== Qt.Key_Space)
            return
        event.accepted = true
        if (event.isAutoRepeat)
            return
        const activate = root._keyActivationHeld && root.activeFocus && root._available
        root.cancelKeyActivation()
        if (activate)
            root.activate()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Style.rhythm(Style.space1 * root.sizeScale)

        Loader {
            active: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: SvgIcon {
                name: root.icon
                size: Style.iconNear(Style.iconSm * root.sizeScale)
                color: root._painted
            }
        }
        Prose {
            visible: root.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            role: "label"
            text: root.text
            color: root._painted
            font.pixelSize: Style.textNear(Style.textSm * root.sizeScale)
        }
        // Needed, in a channel that is not colour alone.
        Prose {
            visible: root.required
            anchors.verticalCenter: parent.verticalCenter
            role: "label"
            color: root.enabled ? Style.danger : Style.disabled(Style.danger)
            text: "*"
            font.pixelSize: Style.textNear(Style.textSm * root.sizeScale)
        }
    }

    StateLayer {
        // The target, not the footprint: at least one large icon each way,
        // centred, so a two-line-tall hit box costs the layout nothing.
        anchors.centerIn: parent
        width: Math.max(parent.width, root.clickable ? Style.iconLg * root.sizeScale : 0)
        height: Math.max(parent.height, root.clickable ? Style.iconLg * root.sizeScale : 0)
        target: root
        interactive: root._available
        manualPressOverride: root._keyActivationHeld
        // The exclusive grab keeps a surrounding passive row tap from firing.
        gesturePolicy: TapHandler.ReleaseWithinBounds
        focusRadius: Style.radiusSm
        onClicked: {
            root.forceActiveFocus(Qt.MouseFocusReason)
            root.activate()
        }
    }
}
