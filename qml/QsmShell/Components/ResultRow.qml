import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

// Search result presentation built on MenuRowItem.
Item {
    id: root
    required property var item
    required property bool selected
    property bool compact: false
    property bool header: false
    property bool danger: false
    signal activated
    signal hoveredEntered

    readonly property string _sub: {
        const sub = root.item && root.item.sub != null ? String(root.item.sub) : ""
        const label = root.item && root.item.label != null ? String(root.item.label) : ""
        return root.header ? "" : (sub.length > 0 && sub.toLowerCase() !== label.toLowerCase() ? sub : "")
    }

    implicitWidth: row.implicitWidth
    implicitHeight: root.header
        ? Style.space4 + Style.space2
        : (root.compact ? 40 : row.implicitHeight)

    MenuRowItem {
        id: row
        anchors.fill: parent
        icon: root.header || !root.item ? "" : (root.item.icon ?? "")
        primary: root.item ? (root.item.label ?? "") : ""
        supporting: root._sub
        header: root.header
        danger: root.danger
        selected: root.selected && !root.header
        onActivated: root.activated()
        onHoveredChanged: if (row.hovered) root.hoveredEntered()
    }
}
