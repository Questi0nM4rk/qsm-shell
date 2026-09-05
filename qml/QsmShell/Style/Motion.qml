pragma Singleton

import QtQuick

import qs.QsmShell.Style

// THE motion vocabulary. Two questions only: how long, and along which curve.
//
// Duration is named by the ROLE of the change, never by a number, so a call
// site says what it is doing rather than how many milliseconds it wants.
// Nothing a person is waiting on runs longer than `fast`; anything above that
// is a surface arriving or leaving, which is a different kind of event.
//
// Curves come in three, and the split is not decoration. A thing arriving
// should land — decelerate into place, so the eye catches it at the end. A
// thing leaving should get out of the way — accelerate away, because nobody
// watches an exit. A thing MOVING between two places it already occupies is
// neither, so it eases at both ends.
//
// Reduced motion shortens every duration rather than removing the animation:
// a change with no transition at all reads as a glitch, not as calm.
QtObject {
    // press — the acknowledgement under a finger. Anything slower feels late.
    readonly property int press: Style.reducedMotion ? 40 : Tokens.motionPress
    // micro — hover, toggle, a colour or opacity settling.
    readonly property int micro: Style.reducedMotion ? 60 : Tokens.motionMicro
    // fast — a control changing shape, a row disclosing. The ceiling for
    // anything the pointer or the keyboard is waiting on.
    readonly property int fast: Style.reducedMotion ? 80 : Tokens.motionFast
    // medium — a popout or a menu arriving.
    readonly property int medium: Style.reducedMotion ? 100 : Tokens.motionMedium
    // large — a whole surface rolling out or retracting.
    readonly property int large: Style.reducedMotion ? 120 : Tokens.motionLarge

    // Enter: decelerate in, so the arrival is where the eye lands.
    readonly property int standardEasing: Easing.OutCubic
    // Enter, with more authority — a surface rather than a control.
    readonly property int emphasizedEasing: Easing.OutQuart
    // Exit: accelerate away. Using an enter curve on an exit is why a
    // disappearing thing can feel like it hesitated.
    readonly property int exitEasing: Easing.InCubic
    // Move or resize between two states that both already exist: eased at
    // both ends, because neither end is an arrival.
    readonly property int moveEasing: Easing.InOutCubic
}
