pragma ComponentBehavior: Bound

import QtQuick

// Arm, then fire. The confirmation for something that cannot be undone, when
// a dialog would be too much ceremony for the gesture.
//
// WHY it is a component and not four lines in each control: a bool, a timer
// and a reset on pointer-leave copied into two controls disagree about the
// timeout and about whether leaving disarms. A confirmation that behaves
// differently in two places is worse than no confirmation, because the person
// learns the lenient one and is caught by the strict one.
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
    onDestructiveChanged: root.disarm()
    // How long the intent stands. Long enough to move a pointer deliberately,
    // short enough that a forgotten arm does not fire on a stray later click.
    property int timeout: 3000

    readonly property bool armed: state.armed

    signal fired
    // Armed and then abandoned (timeout or disarm()), never on a confirmed
    // fire. A control that changed its wording needs to know to change it back.
    signal disarmed

    function trigger(): void {
        if (!root.destructive || state.armed) {
            state.armed = false;
            timer.stop();
            root.fired();
            return;
        }
        state.armed = true;
        timer.restart();
    }

    // The host calls this when the pointer leaves the control: this object has
    // no pointer, and an "armed" that outlives the pointer is a trap laid for
    // the next click. Emits `disarmed`; a confirmed fire does not.
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
