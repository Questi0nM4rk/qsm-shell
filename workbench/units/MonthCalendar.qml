pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Components

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property string todayChoice: "this-month"
    property string preset: "md"
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
        size: root.preset

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
        ] },
        { label: "size", options: [
            { label: "sm", set: { preset: "sm" } },
            { label: "md", set: { preset: "md" } }
        ] }
    ]

    // The calendar's own parts, found by what they are: a button by its
    // objectName, a day cell by the date it carries.
    function descendants(item: Item): var {
        return Array.from(item.children).reduce((all, child) => all.concat([child], root.descendants(child)), [])
    }
    function button(name: string): Item {
        return root.descendants(calendar).find(item => item.objectName === name) ?? null
    }
    function cells(): var {
        return root.descendants(calendar).filter(item => item.cellDate !== undefined)
    }

    readonly property var integration: ({
        events: ["month-shifted"],
        actions: ["shift-previous", "shift-next"],
        targets: ({
            calendar: () => calendar,
            scene: () => root,
            previous: () => root.button("prevMonth"),
            next: () => root.button("nextMonth")
        }),
        observables: {
            shown: () => Qt.formatDate(calendar.shown, "yyyy-MM"),
            "today-marker": () => Qt.formatDate(calendar.today, "yyyy-MM-dd"),
            shifts: () => root.shifts,
            "last-delta": () => root.lastDelta,
            "accessible-name": () => calendar.Accessible.name,
            "cell-count": () => root.cells().length,
            // Exactly the marked day says it is today.
            "today-announced": () => {
                const all = root.cells()
                const said = all.filter(cell => cell.dateName.endsWith(qsTr("today")))
                return said.length === all.filter(cell => cell.isToday).length
                    && said.every(cell => cell.isToday)
            },
            "cell-size": () => root.cells()[0].width
        },
        runAction: name => {
            if (name === "shift-previous") { calendar.shiftMonth(-1); return true }
            if (name === "shift-next") { calendar.shiftMonth(1); return true }
            return false
        }
    })
}
