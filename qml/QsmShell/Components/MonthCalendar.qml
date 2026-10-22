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
    // The month title of the shown month. Below the md cell the full month name
    // plus its chevrons is wider than the seven cells, so it is abbreviated and
    // the calendar's natural width stays the grid's.
    property string titleFormat: root._cell < Style.size("MonthCalendar", "md") ? "MMM yyyy" : "MMMM yyyy"
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
    // Arrows and the page keys are one route with the buttons and the wheel,
    // through one dispatcher. They reach here from the calendar itself or from
    // a button inside it that has focus.
    Keys.onPressed: event => {
        const delta = event.key === Qt.Key_Left || event.key === Qt.Key_PageUp ? -1
            : event.key === Qt.Key_Right || event.key === Qt.Key_PageDown ? 1 : 0;
        if (delta === 0)
            return;
        event.accepted = true;
        root.shiftMonth(delta);
    }

    // The month as a table of dated cells: a reader moves by cell and hears the
    // full date, and which one is today, which the fill alone would not say.
    Accessible.role: Accessible.Table
    Accessible.name: Qt.formatDate(root.shown, "MMMM yyyy")

    ColumnLayout {
        id: body
        anchors.fill: parent
        spacing: Style.space1

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.space2
            IconButton { objectName: "prevMonth"; icon: "chevron-left"; accessibleName: qsTr("Previous month"); size: "sm"; color: Style.textMuted; onClicked: root.shiftMonth(-1) }
            Prose { id: title; Layout.fillWidth: true; Layout.preferredWidth: root.titleWidth; horizontalAlignment: Text.AlignHCenter; role: "title"; text: Qt.formatDate(root.shown, root.titleFormat) }
            IconButton { objectName: "nextMonth"; icon: "chevron-right"; accessibleName: qsTr("Next month"); size: "sm"; color: Style.textMuted; onClicked: root.shiftMonth(1) }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: Style.space1
            columnSpacing: Style.space1
            Repeater {
                model: 7
                Prose {
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: Style.rhythm(implicitHeight)
                    horizontalAlignment: Text.AlignHCenter
                    role: "reading"
                    muted: true
                    text: Qt.locale().standaloneDayName(index + 1, Locale.ShortFormat)
                    Accessible.role: Accessible.ColumnHeader
                    Accessible.name: Qt.locale().standaloneDayName(index + 1, Locale.LongFormat)
                }
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
                    readonly property string dateName: Qt.formatDate(cellDate, "dddd d MMMM yyyy") + (isToday ? ", " + qsTr("today") : "")
                    Accessible.role: Accessible.Cell
                    Accessible.name: dateName
                    Rectangle { anchors.centerIn: parent; visible: parent.isToday; width: Math.min(root._cell, Style.space5); height: width; radius: Style.radiusPill; color: Style.accent }
                    Prose {
                        anchors.centerIn: parent
                        Accessible.ignored: true
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
            text: Qt.formatDate(new Date(root.shown.getFullYear(), index, 1), root.titleFormat)
        }
    }
}
