import QtQuick

import qs.QsmShell.Style

// THE "this one" mark: the short accent pill that says which row is current.
//
// Every list that marks its current row answers the same question, so they
// share one mark and one animation instead of copies that drift.
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

    width: Style.stroke(root.strong ? Style.markThickness + Style.indicatorWidth : Style.markThickness, root)
    height: root.shown ? Style.markHeight : 0
    implicitWidth: width
    implicitHeight: height
    radius: Style.radiusPill
    // A bar this thin is a line with rounded ends: it snaps to the device grid
    // like any rule, instead of smearing its straight sides over a partial
    // column wherever its position falls between two.
    antialiasing: false
    color: root.markColor
    opacity: root.shown ? 1 : 0

    // It grows in and shrinks away, and the two are not the same motion: an
    // arrival lands, a departure gets out of the way, in less time than it
    // took to arrive.
    Behavior on height {
        NumberAnimation {
            duration: root.shown ? Motion.micro : Motion.exit(Motion.micro)
            easing.type: root.shown ? Motion.emphasizedEasing : Motion.exitEasing
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: root.shown ? Motion.micro : Motion.exit(Motion.micro)
            easing.type: root.shown ? Motion.standardEasing : Motion.exitEasing
        }
    }
    // Widening is neither an arrival nor a departure: both ends already exist.
    Behavior on width {
        NumberAnimation { duration: Motion.micro; easing.type: Motion.moveEasing }
    }
}
