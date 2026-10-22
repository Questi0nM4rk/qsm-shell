import QtQuick
import QtQuick.Layouts

// The label column of a Checkbox or a Radio: whatever the host puts in the
// default slot, at a constant width so a long label elides inside it instead
// of growing the control, and the text that names the control when the host
// states no name. One owner, so the two never name themselves differently.
Item {
    id: root

    // The column's width while it holds anything. A constant, never derived
    // from the content.
    property real columnWidth: 0
    readonly property bool hasContent: root.children.length > 0
    // The first slotted item that carries text.
    readonly property string text: {
        for (const item of root.children) {
            if (typeof item.text === "string" && item.text !== "")
                return item.text;
        }
        return "";
    }

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignVCenter
    // The host binds its label's width to this slot's, so a long label elides
    // here instead of growing the control.
    clip: true
    implicitWidth: root.hasContent ? root.columnWidth : 0
    implicitHeight: childrenRect.height
}
