pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml

import qs.QsmShell.Style

// Deterministic calendar: consumers may inject both the shown month and today.
Item {
    id: root

    property date shown: new Date()
    property date today: new Date()
    // A day cell is a square of the size table's `MonthCalendar` preset: md for
    // a rollout, sm for a card that has to share its height.
    property string size: "md"
    readonly property int _cell: Style.size("MonthCalendar", size)
    signal monthShifted(int delta)

    function shiftMonth(delta: int): void {
        shown = new Date(shown.getFullYear(), shown.getMonth() + delta, 1);
        monthShifted(delta);
    }

    // The widest month title of the shown year, so the natural width does not
    // follow the month name.
    readonly property real titleWidth: {
        let widest = 0;
        for (let i = 0; i < titleRuler.count; ++i)
            widest = Math.max(widest, titleRuler.objectAt(i).advanceWidth);
        return Math.ceil(widest);
    }

    // 120 is the platform's own unit, not a design number: one wheel notch.
    readonly property int _wheelNotch: 120
    property int _wheelAccumulator: 0

    implicitWidth: body.implicitWidth
    implicitHeight: body.implicitHeight
    focus: true
    Keys.onLeftPressed: shiftMonth(-1)
    Keys.onRightPressed: shiftMonth(1)

    ColumnLayout {
        id: body
        anchors.fill: parent
        spacing: Style.space1

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.space2
            IconButton { objectName: "prevMonth"; icon: "chevron-left"; accessibleName: qsTr("Previous month"); size: "sm"; color: Style.textMuted; onClicked: root.shiftMonth(-1) }
            Prose { id: title; Layout.fillWidth: true; Layout.preferredWidth: root.titleWidth; horizontalAlignment: Text.AlignHCenter; role: "title"; text: Qt.formatDate(root.shown, "MMMM yyyy") }
            IconButton { objectName: "nextMonth"; icon: "chevron-right"; accessibleName: qsTr("Next month"); size: "sm"; color: Style.textMuted; onClicked: root.shiftMonth(1) }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: Style.space1
            columnSpacing: Style.space1
            Repeater {
                model: 7
                Prose { required property int index; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; role: "reading"; muted: true; text: Qt.locale().standaloneDayName(index + 1, Locale.ShortFormat) }
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
                    Layout.preferredWidth: root._cell
                    Layout.preferredHeight: root._cell
                    Rectangle { anchors.centerIn: parent; width: Math.min(root._cell, Style.space5); height: width; radius: Style.radiusPill; color: parent.isToday ? Style.accent : "transparent" }
                    Prose {
                        anchors.centerIn: parent
                        role: "reading"
                        font.weight: parent.isToday ? Style.weightBold : Style.weightRegular
                        text: parent.cellDate.getDate()
                        color: parent.isToday ? Style.textOnPrimary : parent.inMonth ? Style.text : Style.textMuted
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
            // Accumulated, so a touchpad swipe of many small deltas is one
            // month per notch and not one per event.
            if (Math.sign(event.angleDelta.y) !== Math.sign(root._wheelAccumulator))
                root._wheelAccumulator = 0;
            root._wheelAccumulator += event.angleDelta.y;
            while (Math.abs(root._wheelAccumulator) >= root._wheelNotch) {
                const up = root._wheelAccumulator > 0;
                root._wheelAccumulator -= up ? root._wheelNotch : -root._wheelNotch;
                root.shiftMonth(up ? -1 : 1);
            }
        }
    }

    Instantiator {
        id: titleRuler
        model: 12
        delegate: TextMetrics {
            required property int index
            font: title.font
            text: Qt.formatDate(new Date(root.shown.getFullYear(), index, 1), "MMMM yyyy")
        }
    }
}
