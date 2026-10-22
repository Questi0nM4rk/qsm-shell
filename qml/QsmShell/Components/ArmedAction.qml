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

    readonly property bool armed: root._armed

    signal fired
    // Armed and then abandoned (timeout or disarm()), never on a confirmed
    // fire. A control that changed its wording needs to know to change it back.
    signal disarmed

    function trigger(): void {
        if (!root.destructive || root._armed) {
            root._armed = false;
            timer.stop();
            root.fired();
            return;
        }
        root._armed = true;
        timer.restart();
    }

    // The host calls this when the pointer leaves the control: this object has
    // no pointer, and an "armed" that outlives the pointer is a trap laid for
    // the next click. Emits `disarmed`; a confirmed fire does not.
    function disarm(): void {
        if (!root._armed)
            return;
        root._armed = false;
        timer.stop();
        root.disarmed();
    }

    // Escape takes the question back. Disarms and says whether there was a
    // question to take back, so a host accepts the key only when it answered
    // it, and an unarmed Escape still reaches the surface:
    //
    //     Keys.onEscapePressed: event => event.accepted = guard.cancel()
    function cancel(): bool {
        if (!root._armed)
            return false;
        root.disarm();
        return true;
    }

    property bool _armed: false

    property Timer _timer: Timer {
        id: timer
        interval: root.timeout
        onTriggered: root.disarm()
    }
}
