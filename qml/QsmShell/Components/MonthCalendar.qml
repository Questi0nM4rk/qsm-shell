pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// Deterministic calendar: consumers may inject both the shown month and today.
ColumnLayout {
    id: root

    property date shown: new Date()
    property date today: new Date()
    signal monthShifted(int delta)

    function shiftMonth(delta: int): void {
        shown = new Date(shown.getFullYear(), shown.getMonth() + delta, 1);
        monthShifted(delta);
    }

    spacing: Style.space2
    focus: true
    Keys.onLeftPressed: shiftMonth(-1)
    Keys.onRightPressed: shiftMonth(1)

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.space2
        IconButton { icon: "chevron-left"; size: Style.iconSm; padding: Style.space2; color: Style.textMuted; onClicked: root.shiftMonth(-1) }
        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(root.shown, "MMMM yyyy"); color: Style.text; font.family: Style.fontFamily; font.pixelSize: Style.textMd; font.weight: Style.weightBold }
        IconButton { icon: "chevron-right"; size: Style.iconSm; padding: Style.space2; color: Style.textMuted; onClicked: root.shiftMonth(1) }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: Style.spaceTight
        columnSpacing: Style.spaceTight
        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            Text { required property string modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: modelData; color: Style.textMuted; font.family: Style.technicalFontFamily; font.pixelSize: Style.textXs }
        }
        Repeater {
            model: 42
            Item {
                required property int index
                readonly property date cellDate: {
                    const first = new Date(root.shown.getFullYear(), root.shown.getMonth(), 1);
                    return new Date(first.getFullYear(), first.getMonth(), 1 - ((first.getDay() + 6) % 7) + index);
                }
                readonly property bool inMonth: cellDate.getMonth() === root.shown.getMonth()
                readonly property bool isToday: cellDate.getFullYear() === root.today.getFullYear() && cellDate.getMonth() === root.today.getMonth() && cellDate.getDate() === root.today.getDate()
                Layout.fillWidth: true
                Layout.preferredHeight: Style.space5
                Rectangle { anchors.centerIn: parent; width: Style.space5 - Style.spaceTight; height: Style.space5 - Style.spaceTight; radius: width / 2; color: parent.isToday ? Style.accent : "transparent" }
                Text { anchors.centerIn: parent; text: parent.cellDate.getDate(); color: parent.isToday ? Style.background : parent.inMonth ? Style.text : Style.textMuted; opacity: parent.inMonth || parent.isToday ? 1 : 0.4; font.family: Style.technicalFontFamily; font.pixelSize: Style.textXs; font.weight: parent.isToday ? Style.weightBold : Style.weightRegular }
            }
        }
    }
    WheelHandler { onWheel: event => root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1) }
}
