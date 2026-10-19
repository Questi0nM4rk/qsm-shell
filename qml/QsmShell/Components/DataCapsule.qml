import QtQuick
import QtQuick.Effects
import QtQuick.Templates as T

import qs.QsmShell.Style

T.Control {
    id: root

    default property alias content: slot.data

    property bool shown: false
    property int timeout: 0
    property bool hoverStay: true
    property bool interactive: false
    property string actionLabel: "Open"
    property string accessibleName: ""
    property string size: "md"
    property int orientation: Qt.Horizontal
    property real bodySize: Style.size("DataCapsule", size)
    readonly property real sizeScale: bodySize / Style.size("DataCapsule", "md")
    property real preferredLength: Style.rhythm(Style.controlWidth * sizeScale)
    property real radius: Style.rolloutRadius
    property color surfaceColor: Style.band
    property bool elevated: true

    readonly property bool pointerHovered: pointer.hovered
    readonly property bool keepOpen: (hoverStay && pointerHovered)
        || root.activeFocus || slot.activeFocus
    readonly property bool present: shown || opacity > 0
    readonly property bool acceptsInput: shown && enabled
    property real _remaining: 0
    property real _deadline: 0
    property bool _armed: false

    signal activated
    signal timeoutRequested

    readonly property list<T.Action> actions: [
        T.Action {
            text: root.actionLabel
            enabled: root.acceptsInput && root.interactive
            onTriggered: root.activate()
        },
        T.Action { text: "Restart timeout"; enabled: root.shown; onTriggered: root.restart() },
        T.Action { text: "Cancel timeout"; onTriggered: root.reset() }
    ]

    padding: Style.rhythm(Style.space3 * sizeScale)
    implicitWidth: orientation === Qt.Horizontal ? preferredLength : bodySize
    implicitHeight: orientation === Qt.Horizontal ? bodySize : preferredLength
    visible: present
    opacity: shown ? 1 : 0
    hoverEnabled: true
    focusPolicy: acceptsInput && interactive ? Qt.StrongFocus : Qt.NoFocus

    Accessible.role: interactive ? Accessible.Button : Accessible.Grouping
    Accessible.name: interactive ? actionLabel : accessibleName
    Accessible.onPressAction: root.activate()

    function activate(): bool {
        if (!root.acceptsInput || !root.interactive)
            return false;
        root.activated();
        return true;
    }

    function remainingTime(): int {
        return Math.max(0, Math.ceil(expiry.running ? root._deadline - Date.now() : root._remaining));
    }

    function reset(): void {
        expiry.stop();
        root._armed = false;
        root._remaining = 0;
        root._deadline = 0;
    }

    function restart(): void {
        root.reset();
        if (!root.shown || root.timeout <= 0)
            return;
        root._remaining = root.timeout;
        root._armed = true;
        root.syncTimeout();
    }

    function syncTimeout(): void {
        if (expiry.running) {
            root._remaining = Math.max(0, root._deadline - Date.now());
            expiry.stop();
        }
        if (!root._armed || !root.shown || root.keepOpen)
            return;
        root._deadline = Date.now() + root._remaining;
        expiry.interval = Math.max(1, Math.ceil(root._remaining));
        expiry.start();
    }

    onShownChanged: {
        if (shown)
            root.restart();
        else {
            root.reset();
            root.focus = false;
            slot.focus = false;
        }
    }
    onTimeoutChanged: root.restart()
    onKeepOpenChanged: root.syncTimeout()
    Component.onCompleted: root.restart()

    Behavior on opacity {
        NumberAnimation {
            duration: root.shown ? Motion.medium : Motion.micro
            easing.type: root.shown ? Motion.standardEasing : Motion.exitEasing
        }
    }

    Timer {
        id: expiry
        onTriggered: {
            root._armed = false;
            root._remaining = 0;
            root._deadline = 0;
            root.timeoutRequested();
        }
    }

    // The hover observer is on the ancestor so child controls retain hover.
    HoverHandler {
        id: pointer
        parent: root
        enabled: root.acceptsInput
    }

    background: Surface {
        base: root.surfaceColor
        radius: root.radius
        hovered: root.interactive && root.pointerHovered
        pressed: body.pressed
        layer.enabled: root.elevated && !Style.reducedEffects
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Style.shadow
            shadowOpacity: Style.floatingShadowOpacity
            shadowBlur: Style.floatingShadowBlur
            shadowVerticalOffset: Style.floatingShadowOffset
            blurMax: Style.floatingShadowExtent
        }

        StateLayer {
            anchors.fill: parent
            host: root
            target: null
            interactive: root.acceptsInput && root.interactive
            focusRadius: root.radius
        }
    }

    contentItem: FocusScope {
        id: slot
        z: 1
        clip: true
        enabled: root.acceptsInput
    }

    property Item _bodyInput: MouseArea {
        id: body
        parent: root
        anchors.fill: parent
        enabled: root.acceptsInput && root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.forceActiveFocus();
            root.activate();
        }
    }

    Keys.onReturnPressed: event => { event.accepted = root.activate(); }
    Keys.onEnterPressed: event => { event.accepted = root.activate(); }
    Keys.onSpacePressed: event => { event.accepted = root.activate(); }
}
