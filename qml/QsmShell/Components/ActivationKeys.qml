import QtQuick

// The keyboard half of a button, once. Space, Return and Enter read as pressed
// while held and act once, on release, as a native button does. A held key
// repeats a release and a press of its own (`isAutoRepeat`) and neither is the
// key coming up, so one hold can never act twice, flicker a toggle at the
// repeat rate, or arm a control and then confirm it. The hold is dropped when
// the host stops being available or loses focus, so no release is ever owed.
//
// The host lists it in `Keys.forwardTo`, shows `held` as its pressed look
// (a layer's `manualPressOverride`) and answers `activated`. Unavailable, it
// takes no key at all, so a surface above still gets Return and Space.
//
//     ActivationKeys { id: keys; available: root.enabled; onActivated: root.activate() }
//     Keys.forwardTo: [keys]
Item {
    id: root

    property bool available: true
    readonly property bool held: root._held

    signal activated

    property bool _held: false
    readonly property bool _hostFocused: root.parent?.activeFocus ?? false

    function cancel(): void {
        root._held = false;
    }

    function _isActivationKey(key: int): bool {
        return key === Qt.Key_Space || key === Qt.Key_Return || key === Qt.Key_Enter;
    }

    onAvailableChanged: if (!root.available) root.cancel()
    on_HostFocusedChanged: if (!root._hostFocused) root.cancel()

    Keys.onPressed: event => {
        if (!root.available || !root._isActivationKey(event.key))
            return;
        event.accepted = true;
        if (!event.isAutoRepeat)
            root._held = true;
    }

    Keys.onReleased: event => {
        if (!root._held || !root._isActivationKey(event.key))
            return;
        event.accepted = true;
        if (event.isAutoRepeat)
            return;
        root._held = false;
        root.activated();
    }
}
