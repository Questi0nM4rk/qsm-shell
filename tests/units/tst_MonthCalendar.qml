import QtQuick
import QtTest

import qs.QsmShell.Components

// The wheel route is the realistic regression surface: WheelHandler is dead
// under the Qt6 Wayland QPA, so this uses a real MouseArea wheel event.
TestCase {
    id: probe

    name: "MonthCalendar"
    width: 400
    height: 1240
    visible: true
    when: windowShown

    MonthCalendar {
        id: wheelCal
        x: 50; y: 20; width: 300; height: 260
        shown: new Date(2026, 7, 1)
        today: new Date(2026, 7, 28)
    }
    SignalSpy { id: wheelSpy; target: wheelCal; signalName: "monthShifted" }

    MonthCalendar {
        id: keyCal
        x: 50; y: 300; width: 300; height: 260
        shown: new Date(2026, 7, 1)
        today: new Date(2026, 7, 28)
    }

    MonthCalendar {
        id: buttonCal
        x: 50; y: 580; width: 300; height: 260
        shown: new Date(2026, 7, 1)
        today: new Date(2026, 7, 28)
    }

    property int scrollerNotches: 0
    Item {
        id: scroller
        x: 50; y: 860; width: 300; height: 260

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: probe.scrollerNotches++
        }

        MonthCalendar {
            id: scrollCal
            anchors.fill: parent
            shown: new Date(2026, 7, 1)
            today: new Date(2026, 7, 28)
        }
    }

    function init() {
        wheelCal.shown = new Date(2026, 7, 1);
        keyCal.shown = new Date(2026, 7, 1);
        buttonCal.shown = new Date(2026, 7, 1);
        scrollCal.shown = new Date(2026, 7, 1);
        probe.scrollerNotches = 0;
        wheelSpy.clear();
    }

    function test_wheel_pages_exactly_once_per_direction() {
        mouseMove(wheelCal, 150, 130);

        mouseWheel(wheelCal, 150, 130, 0, 120);
        compare(wheelSpy.count, 1, "one upward notch did not page exactly once");
        compare(wheelSpy.signalArguments[0][0], -1, "an upward notch did not report delta -1");
        compare(wheelCal.shown.getMonth(), 6, "an upward notch did not page back to July");

        mouseWheel(wheelCal, 150, 130, 0, -120);
        compare(wheelSpy.count, 2, "one downward notch did not page exactly once");
        compare(wheelSpy.signalArguments[1][0], 1, "a downward notch did not report delta 1");
        compare(wheelCal.shown.getMonth(), 7, "a downward notch did not page forward to August");
    }

    function test_wheel_pages_across_the_year_boundary() {
        wheelCal.shown = new Date(2026, 11, 1);
        wheelSpy.clear();
        mouseMove(wheelCal, 150, 130);

        mouseWheel(wheelCal, 150, 130, 0, -120);
        compare(wheelSpy.count, 1, "a downward notch on December did not page exactly once");
        compare(wheelCal.shown.getFullYear(), 2027, "paging forward out of December did not reach 2027");
        compare(wheelCal.shown.getMonth(), 0, "paging forward out of December did not reach January");
    }

    function test_arrow_keys_shift_the_shown_month() {
        keyCal.forceActiveFocus();

        keyClick(Qt.Key_Left);
        compare(keyCal.shown.getMonth(), 6, "Left did not page back to July");

        keyClick(Qt.Key_Right);
        compare(keyCal.shown.getMonth(), 7, "Right did not page forward to August");
    }

    function test_header_buttons_shift_the_shown_month() {
        const prev = findChild(buttonCal, "prevMonth");
        const next = findChild(buttonCal, "nextMonth");
        verify(prev !== null, "the previous-month button lost its objectName");
        verify(next !== null, "the next-month button lost its objectName");

        mouseClick(prev);
        compare(buttonCal.shown.getMonth(), 6, "the previous-month button did not page back to July");

        mouseClick(next);
        compare(buttonCal.shown.getMonth(), 7, "the next-month button did not page forward to August");
    }

    function test_off_axis_wheel_reaches_the_enclosing_scroller() {
        mouseMove(scrollCal, 150, 130);

        mouseWheel(scrollCal, 150, 130, 0, 120);
        compare(scrollCal.shown.getMonth(), 6, "the calendar did not take an on-axis notch");
        compare(probe.scrollerNotches, 0, "the calendar also passed on a handled notch");

        mouseWheel(scrollCal, 150, 130, 120, 0);
        compare(scrollCal.shown.getMonth(), 6, "a horizontal wheel moved the calendar");
        compare(probe.scrollerNotches, 1, "an off-axis wheel was swallowed");
    }
}
