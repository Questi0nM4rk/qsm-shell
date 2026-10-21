import QtQuick
import qs.QsmShell.Style

// One thin line.
//
// `inset` insets the DRAWN LINE rather than the item, so it works the same for
// a fixed-width consumer and an anchored one without forcing a layout style.
// The item's own height is free: the line stays centred in it, which is what
// lets a separator claim a gap and still be one pixel of ink.
//
// `lineColor` and `thickness` exist because a rule inside a band is not the
// same rule as a rule inside a card: the band's is heavier and drawn in the
// muted text colour, not the outline. Two consumers asked for it before it
// was added, and both had written their own Rectangle to get it.
Rectangle {
    id: root

    property real inset: 0
    property real strength: Style.dividerOpacity
    property color lineColor: Style.textMuted
    property real thickness: 1

    implicitHeight: thickness
    color: "transparent"

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.inset
        width: Math.max(0, parent.width - root.inset * 2)
        height: root.thickness
        color: root.lineColor
        opacity: root.strength
    }
}
