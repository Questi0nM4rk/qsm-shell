# MonthCalendar

`MonthCalendar` moves the host-owned month while keeping a stable today marker.
Buttons, arrow keys, and vertical wheel input share `shiftMonth(delta)`;
horizontal wheel input remains available to an enclosing scroller.
The seven-column grid has a fixed natural size and uses only `Style` tokens.
Today is the sole accent; weekday and out-of-month dates recede quietly.

Not designed: date selection, ranges, locale-specific week starts, or a
dense multi-month picker.
