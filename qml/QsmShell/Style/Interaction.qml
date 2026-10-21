pragma Singleton

import QtQuick

// Facts about who is driving, shared by every component that answers a
// pointer. Not styling: this is the one place a consumer states something the
// components cannot see for themselves.
QtObject {
    property int sliderDecreaseKey: Qt.Key_N
    property int sliderIncreaseKey: Qt.Key_O

    // Is a hover-enter allowed to CLAIM the selection?
    //
    // In a searchable list the pointer and the keyboard drive one cursor, and
    // they fight: while someone types, the results reshuffle under a cursor
    // that never moved, and whichever row happens to slide beneath it would
    // otherwise steal the selection mid-keystroke. Worse on a compositor that
    // hides the cursor while typing, because then the theft comes from a
    // pointer the person cannot even see.
    //
    // So the rule is: a hover the POINTER did not cause gets no say. The
    // library cannot know when that is — only the consumer knows that a key
    // was just pressed and the pointer has not moved since — so the consumer
    // sets this, and every component honours it without being asked.
    //
    // Default true: a shell that never sets it lets the pointer select.
    property bool pointerSelects: true
}
