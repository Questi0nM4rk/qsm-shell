import QtQuick

import qs.QsmShell.Style

// THE "this one" mark: the short accent pill that says which row is current.
//
// A launcher result, a device row, a menu row and a notification in the
// history all answer the same question, and each of them used to answer it by
// drawing its own 3x18 rectangle with its own animation. Four copies of one
// idiom is four places for it to drift, and it had already started to: some
// grew in, some only faded, and one changed width while the others did not.
//
// The consumer positions it — a mark belongs to the row's own layout, and a
// component that anchors itself into its parent cannot be reused by a parent
// that wants it somewhere else. Everything about how it LOOKS and how it
// arrives lives here.
Rectangle {
    id: root

    // Is this the current one.
    property bool shown: false
    // A heavier presence, for a list where the current row is also the one the
    // keyboard is on. Wider, not brighter: brightness is already spoken for.
    property bool strong: false
    property color markColor: Style.accent
    // What a SHOWN-but-not-strong mark reads at. A list cursor is either gone
    // or fully present, so this defaults to 1 and every existing consumer is
    // unaffected. A mark that never leaves (a notification's urgency tick,
    // present on every row and only THICKENING on select) needs a third,
    // dimmer level for "here, but not the current one" — brightening it too
    // would spend the same signal `strong` already owns.
    property real restOpacity: 1

    width: root.strong ? Style.markThickness + Style.spaceTight : Style.markThickness
    height: root.shown ? Style.markHeight : 0
    radius: width / 2
    color: root.markColor
    opacity: root.shown ? (root.strong ? 1 : root.restOpacity) : 0

    // It grows in and shrinks away, and the two are not the same motion: an
    // arrival lands, a departure gets out of the way.
    Behavior on height {
        NumberAnimation {
            duration: Motion.micro
            easing.type: root.shown ? Motion.emphasizedEasing : Motion.exitEasing
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: Motion.micro
            easing.type: root.shown ? Motion.standardEasing : Motion.exitEasing
        }
    }
    // Widening is neither an arrival nor a departure: both ends already exist.
    Behavior on width {
        NumberAnimation { duration: Motion.micro; easing.type: Motion.moveEasing }
    }
}
