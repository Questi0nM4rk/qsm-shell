pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// Deterministic calendar: consumers may inject both the shown month and today.
Item {
    id: root

    property date shown: new Date()
    property date today: new Date()
    signal monthShifted(int delta)

    function shiftMonth(delta: int): void {
        shown = new Date(shown.getFullYear(), shown.getMonth() + delta, 1);
        monthShifted(delta);
    }

    implicitWidth: body.implicitWidth
    implicitHeight: body.implicitHeight
    focus: true
    Keys.onLeftPressed: shiftMonth(-1)
    Keys.onRightPressed: shiftMonth(1)

    ColumnLayout {
        id: body
        anchors.fill: parent
        spacing: Style.space2

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.space2
            IconButton { objectName: "prevMonth"; icon: "chevron-left"; size: Style.iconSm; padding: Style.space2; color: Style.textMuted; onClicked: root.shiftMonth(-1) }
            Prose { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; role: "title"; text: Qt.formatDate(root.shown, "MMMM yyyy") }
            IconButton { objectName: "nextMonth"; icon: "chevron-right"; size: Style.iconSm; padding: Style.space2; color: Style.textMuted; onClicked: root.shiftMonth(1) }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: Style.spaceTight
            columnSpacing: Style.spaceTight
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                Prose { required property string modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; role: "reading"; font.pixelSize: Style.textXs; muted: true; text: modelData }
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
                    Prose {
                        anchors.centerIn: parent
                        role: "reading"
                        font.pixelSize: Style.textXs
                        font.weight: parent.isToday ? Style.weightBold : Style.weightRegular
                        text: parent.cellDate.getDate()
                        color: parent.isToday ? Style.textOnPrimary : parent.inMonth ? Style.text : Style.textMuted
                        opacity: parent.inMonth || parent.isToday ? 1 : 0.4
                    }
                }
            }
        }
    }

    // A MouseArea receives wheel events under the Qt6 Wayland QPA where a
    // WheelHandler does not. Off-axis events are handed back to an enclosing
    // scroller instead of being consumed without changing the month.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            if (event.angleDelta.y === 0) {
                event.accepted = false;
                return;
            }
            root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1);
        }
    }
}
