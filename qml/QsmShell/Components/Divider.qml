import QtQuick
import qs.QsmShell.Style

// `inset` insets the drawn line itself so it takes effect for both fixed-width
// and anchored consumers, without forcing any particular layout style. The
// implicit 1px horizontal line is preserved.
Rectangle {
    id: root
    property real inset: 0
    property real strength: .35
    implicitHeight: 1
    color: "transparent"
    Rectangle {
        id: line
        anchors.verticalCenter: parent.verticalCenter
        height: 1
        width: Math.max(0, parent.width - root.inset * 2)
        anchors.left: parent.left
        anchors.leftMargin: root.inset
        color: Style.outline
        opacity: root.strength
    }
}
