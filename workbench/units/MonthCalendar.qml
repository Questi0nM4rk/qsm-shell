import QtQuick

import qs.QsmShell.Components

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property string todayChoice: "this-month"
    property int shifts: 0
    property int lastDelta: 0

    readonly property date today: {
        switch (todayChoice) {
        case "before": return new Date(2026, 6, 12)
        case "after": return new Date(2026, 9, 4)
        default: return new Date(2026, 7, 30)
        }
    }

    implicitWidth: calendar.implicitWidth
    implicitHeight: calendar.implicitHeight

    MonthCalendar {
        id: calendar

        shown: new Date(2026, 7, 1)
        today: root.today

        onMonthShifted: delta => {
            root.shifts++
            root.lastDelta = delta
            root.eventRecorder?.("intent", "month-shifted", { delta })
        }
    }

    readonly property var controls: [
        { label: "today", options: [
            { label: "before", set: { todayChoice: "before" } },
            { label: "this-month", set: { todayChoice: "this-month" } },
            { label: "after", set: { todayChoice: "after" } }
        ] }
    ]

    readonly property var integration: ({
        events: ["month-shifted"],
        actions: ["shift-previous", "shift-next"],
        observables: {
            shown: () => Qt.formatDate(calendar.shown, "yyyy-MM"),
            "today-marker": () => Qt.formatDate(calendar.today, "yyyy-MM-dd"),
            shifts: () => root.shifts,
            "last-delta": () => root.lastDelta
        },
        runAction: name => {
            if (name === "shift-previous") { calendar.shiftMonth(-1); return true }
            if (name === "shift-next") { calendar.shiftMonth(1); return true }
            return false
        }
    })
}
