import QtQuick
import qs.QsmShell.Style

// The one line: a straight rule of whole device pixels, so it paints the same
// rows wherever it sits.
//
// `strength` is how loud it is. A rule inside a surface is quiet; one drawn
// directly in the band (`inBand`) is stronger, because nothing but the rule
// groups what sits on it.
//
// `inset` insets the DRAWN LINE rather than the item, so it works the same for
// a fixed-width consumer and an anchored one without forcing a layout style.
// The item's own height is free: the line stays centred in it, which is what
// lets a separator claim a gap and still be one line of ink.
Item {
    id: root

    property real inset: 0
    // The rule sits directly in the band, not inside a surface.
    property bool inBand: false
    property real strength: root.inBand ? Style.dividerBandOpacity : Style.dividerOpacity

    readonly property real thickness: Style.stroke(Style.hairline, root)

    implicitHeight: root.thickness

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.inset
        width: Math.max(0, parent.width - root.inset * 2)
        height: root.thickness
        color: Qt.alpha(Style.textMuted, root.strength)
    }
}
