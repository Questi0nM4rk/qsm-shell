# MonthCalendar

`MonthCalendar` moves the month it shows while keeping a stable today marker.
Buttons, arrow keys, the page keys and vertical wheel input share `shiftMonth(delta)`; horizontal wheel input stays available to an enclosing scroller. The host owns `today`; `shown` starts from the host's value and the calendar moves it, reporting `monthShifted(delta)`.
states: any month; today in the month, before it or after it; every month is six rows of cells so the height never changes. Day cells are inert: the type shows a month and does not select a day. Today is the sole accent (the accent disc under a `textOnPrimary` digit, 8.87:1); weekday names and dates outside the month recede to `textMuted`.
pointer: the previous and next buttons are 32 px targets; the wheel shifts one month per 120 units accumulated, so a touchpad swipe is one month per notch.
keyboard: the buttons are tab stops (Space and Return); Left and PageUp, Right and PageDown shift a month from the calendar or from a button inside it, through one dispatcher.
screen reader: a table named by the month; the weekday names are column headers read in full; every day is a cell that says its full date and "today" on the marked one, the digit itself is not read twice.
size: `size` names a preset of the MonthCalendar table, the day cell's side (md 32, sm 24); natural size is constant: 248 x 268 at md (header 32, rows 4 px apart, weekday row 16, six rows of 32), 192 x 220 at sm; the month title is the widest of the year so its width never follows the month name, and below md it is abbreviated. Measured at 1.25: the cell pitch is 36 on both axes with 4 px gaps, the today disc is 24 px centred in its cell with zero offset, the digit is within 0.22 px of the cell centre.
not designed: date selection, ranges, locale-specific week starts (weeks begin on Monday), or a dense multi-month picker.
tokens: Style only; no local colours or measurements.
