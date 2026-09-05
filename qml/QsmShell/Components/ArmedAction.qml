pragma ComponentBehavior: Bound

import QtQuick

// Arm, then fire. The confirmation for something that cannot be undone, when
// a dialog would be too much ceremony for the gesture.
//
// WHY it is a component and not four lines in each control: two controls in
// the consuming shell had grown their own copy — a bool, a timer, a reset on
// pointer-leave — and they already disagreed about the timeout and about
// whether leaving disarms. A confirmation that behaves differently in two
// places is worse than no confirmation, because the person learns the lenient
// one and is caught by the strict one.
//
// The ladder this sits on matters: constraint beats a safe default beats a
// consequence preview beats undo beats confirmation, in that order. Reach for
// this only at the bottom of that ladder — a routine action that confirms
// trains the reflex click that removes the protection it was added for.
//
// `destructive: false` makes `trigger()` fire immediately, so a control does
// not need two code paths for "this one asks" and "this one does not".
QtObject {
    id: root

    property bool destructive: true
    // How long the intent stands. Long enough to move a pointer deliberately,
    // short enough that a forgotten arm does not fire on a stray later click.
    property int timeout: 3000

    readonly property bool armed: state.armed
    // What the control should SAY while armed. Empty leaves the wording to
    // the control; the point is that the same surface that names the action
    // is the one that asks for confirmation, never a different one.
    property string confirmLabel: ""

    signal fired
    // Armed and then abandoned. A control that changed its wording needs to
    // know to change it back.
    signal disarmed

    function trigger(): void {
        if (!root.destructive || state.armed) {
            root.disarm();
            root.fired();
            return;
        }
        state.armed = true;
        timer.restart();
    }

    // Leaving the control abandons the intent. The gesture and the intent are
    // one thing: an "armed" that outlives the pointer is a trap laid for the
    // next click.
    function disarm(): void {
        if (!state.armed)
            return;
        state.armed = false;
        timer.stop();
        root.disarmed();
    }

    property QtObject _state: QtObject {
        id: state
        property bool armed: false
    }

    property Timer _timer: Timer {
        id: timer
        interval: root.timeout
        onTriggered: root.disarm()
    }
}
