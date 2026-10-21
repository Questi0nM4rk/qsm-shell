import QtQuick
import qs.QsmShell.Style

// The one line: a straight rule of whole device pixels, so it paints the same
// rows wherever it sits.
//
// `strength` is how loud it is. `Style.dividerOpacity` inside a surface, and
// `Style.dividerBandOpacity` in the band, where nothing but the rule groups
// what sits on it.
//
// `inset` insets the DRAWN LINE rather than the item, so it works the same for
// a fixed-width consumer and an anchored one without forcing a layout style.
// The item's own height is free: the line stays centred in it, which is what
// lets a separator claim a gap and still be one line of ink.
Item {
    id: root

    property real inset: 0
    property real strength: Style.dividerOpacity

    implicitHeight: Style.stroke(1, Screen.devicePixelRatio)

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.inset
        width: Math.max(0, parent.width - root.inset * 2)
        height: Style.stroke(1, Screen.devicePixelRatio)
        color: Qt.alpha(Style.textMuted, root.strength)
    }
}
