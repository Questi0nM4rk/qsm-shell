import QtQuick
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style

// THE row's law is the most valuable thing this file pins: UNAVAILABLE
// (`disabled`) and NOT-A-TARGET (`interactive: false`) both refuse a click
// and a hover claim identically, but they are not the same state -- a
// disabled row admits it, a report-only row does not. `neutral()` parks the
// pointer away from every row first, because `hoveredEntered` only fires on
// a false -> true transition and a stale hover from a previous test would
// hide that.
TestCase {
    id: probe

    name: "ListRow"
    width: 400
    height: 600
    visible: true
    when: windowShown

    function neutral() { mouseMove(probe, 390, 510); }

    function cleanup() {
        // Restore the shared singleton so one test's gate can never poison
        // the next -- Interaction.pointerSelects is consumer-owned state,
        // not per-instance.
        Interaction.pointerSelects = true;
    }

    ListRow { id: plainRow; x: 20; y: 20; width: 300; height: 32; primary: "Plain" }
    SignalSpy { id: plainClicked; target: plainRow; signalName: "activated" }
    SignalSpy { id: plainHovered; target: plainRow; signalName: "hoveredEntered" }

    ListRow { id: disabledRow; x: 20; y: 70; width: 300; height: 32; primary: "Disabled"; disabled: true }
    SignalSpy { id: disabledClicked; target: disabledRow; signalName: "activated" }

    // The state this type exists to demonstrate: reports the truth at full
    // strength, is not a click target, and must never claim `disabled`.
    ListRow { id: reportRow; x: 20; y: 120; width: 300; height: 32; primary: "Report"; interactive: false }
    SignalSpy { id: reportClicked; target: reportRow; signalName: "activated" }

    ListRow { id: headerRow; x: 20; y: 170; width: 300; height: 32; primary: "Header"; header: true }
    SignalSpy { id: headerClicked; target: headerRow; signalName: "activated" }

    ListRow { id: separatorRow; x: 20; y: 220; width: 300; height: 12; separator: true }
    SignalSpy { id: separatorClicked; target: separatorRow; signalName: "activated" }

    // ── slot geometry ────────────────────────────────────────────────────
    // Leading: no icon and no leading content versus an icon, everything
    // else identical. If the box costs nothing while empty, the whole
    // difference is the box plus the one spacing gap it introduces.
    ListRow { id: noLeading; x: 20; y: 260; primary: "X" }
    ListRow { id: withLeading; x: 20; y: 300; primary: "X"; icon: "wifi" }

    // Trailing: empty versus populated. The empty trailing slot must have
    // zero layout footprint; a populated slot keeps its natural footprint.
    ListRow { id: noTrailing; x: 20; y: 340; primary: "X" }
    ListRow {
        id: withTrailing
        x: 20; y: 380; primary: "X"
        Prose { id: trailingReading; role: "reading"; text: "99%" }
    }

    // Report-only with recede: a reading row must stay at full strength.
    ListRow { id: reportWithRecede; x: 20; y: 420; primary: "Report"; interactive: false; recede: true }
    ListRow { id: plainWithRecede; x: 20; y: 460; primary: "Plain"; recede: true }
    ListRow {
        id: trailingActionRow
        x: 20; y: 488; width: 300; height: 32; primary: "Action"
        ControlLabel { id: trailingAction; text: "Details"; clickable: true }
    }
    SignalSpy { id: trailingActionClicked; target: trailingAction; signalName: "clicked" }
    SignalSpy { id: trailingActionRowClicked; target: trailingActionRow; signalName: "activated" }
    ListRow {
        id: trailingReadingRow
        x: 20; y: 528; width: 300; height: 32; primary: "Reading"
        ControlLabel { id: trailingReadingAction; text: "99%" }
    }
    SignalSpy { id: trailingReadingRowClicked; target: trailingReadingRow; signalName: "activated" }

    function test_plain_row_answers_a_real_click_and_a_real_hover() {
        neutral();
        plainClicked.clear();
        plainHovered.clear();

        mouseMove(plainRow, 10, 16);
        compare(plainRow.hovered, true, "a plain row did not report hover under a real pointer move");
        compare(plainHovered.count, 1, "a plain row did not hand hoveredEntered upward on a real hover");

        mouseClick(plainRow, 10, 16);
        compare(plainClicked.count, 1, "a plain row did not fire activated on a real click");
    }

    function test_trailing_control_label_owns_its_click_and_passive_content_does_not() {
        neutral();
        trailingActionClicked.clear();
        trailingActionRowClicked.clear();
        mouseClick(trailingAction, trailingAction.width / 2, trailingAction.height / 2);
        compare(trailingActionClicked.count, 1, "the trailing ControlLabel did not receive its physical click");
        compare(trailingActionRowClicked.count, 0, "the child click also activated the row");

        trailingActionRowClicked.clear();
        mouseClick(trailingActionRow, 10, 16);
        compare(trailingActionRowClicked.count, 1, "a body click did not activate the row");

        trailingReadingRowClicked.clear();
        mouseClick(trailingReadingAction, trailingReadingAction.width / 2, trailingReadingAction.height / 2);
        compare(trailingReadingRowClicked.count, 1, "a passive trailing reading did not activate the row");
    }

    function test_callers_share_the_pointer_activation_route() {
        plainClicked.clear();

        plainRow.activate();
        compare(plainClicked.count, 1, "activate() did not emit the row's action");

        disabledRow.activate();
        compare(plainClicked.count, 1, "a disabled row activated through its programmatic route");
    }

    // UNAVAILABLE: the action exists, cannot be taken now, and the row says so.
    function test_disabled_row_admits_it_and_refuses_the_click_and_hover() {
        neutral();
        disabledClicked.clear();

        compare(disabledRow.disabled, true, "a disabled row did not report its own disabled state");
        mouseMove(disabledRow, 10, 16);
        compare(disabledRow.hovered, false, "a disabled row claimed hover under a real pointer move");
        mouseClick(disabledRow, 10, 16);
        compare(disabledClicked.count, 0, "a disabled row fired activated on a real click");
    }

    // NOT-A-TARGET: the row only reports. It refuses the same routes a
    // disabled row refuses, but it must never claim to be `disabled` --
    // that would tell a caller checking `disabled` to show a stale reading
    // as unavailable rather than as live-but-unpickable.
    function test_report_only_row_refuses_the_same_routes_without_claiming_disabled() {
        neutral();
        reportClicked.clear();

        mouseMove(reportRow, 10, 16);
        compare(reportRow.hovered, false, "a report-only row claimed hover under a real pointer move");
        mouseClick(reportRow, 10, 16);
        compare(reportClicked.count, 0, "a report-only row fired activated on a real click");

        compare(reportRow.disabled, false,
            "a report-only row reported disabled -- unavailable and not-a-target collapsed into one state");
        compare(disabledRow.disabled, true,
            "the disabled row's own flag changed -- the two rows are not independent axes");
    }

    function test_header_is_not_a_target() {
        neutral();
        headerClicked.clear();

        mouseMove(headerRow, 10, 16);
        compare(headerRow.hovered, false, "a header row claimed hover under a real pointer move");
        mouseClick(headerRow, 10, 16);
        compare(headerClicked.count, 0, "a header row fired activated on a real click");
    }

    function test_separator_is_not_a_target() {
        neutral();
        separatorClicked.clear();

        mouseMove(separatorRow, 10, 6);
        compare(separatorRow.hovered, false, "a separator row claimed hover under a real pointer move");
        mouseClick(separatorRow, 10, 6);
        compare(separatorClicked.count, 0, "a separator row fired activated on a real click");
    }

    // `selected` is consumer-owned. A row that flips it on its own click or
    // hover would be managing state a list is supposed to own.
    function test_selected_is_reported_honestly_and_never_written_by_the_row_itself() {
        neutral();
        plainRow.selected = false;

        mouseMove(plainRow, 10, 16);
        mouseClick(plainRow, 10, 16);
        compare(plainRow.selected, false, "a click or a hover flipped selected without the consumer asking");

        plainRow.selected = true;
        compare(plainRow.selected, true, "an explicit selected write was not honoured back");
        plainRow.selected = false;
    }

    // The one place a hover reader in this library defers to a fact it
    // cannot see itself: whether the pointer, rather than a reshuffling list,
    // caused the hover. `hovered` is the raw pointer fact and stays true;
    // only the upward signal a list would act on is gated.
    function test_a_hover_that_is_not_the_pointers_gets_no_say() {
        neutral();
        plainHovered.clear();

        Interaction.pointerSelects = false;
        mouseMove(plainRow, 10, 16);
        compare(plainRow.hovered, true, "hovered stopped reporting the raw pointer fact");
        compare(plainHovered.count, 0, "hoveredEntered fired while a hover was not allowed to claim the selection");
    }

    // ListRow itself has no keyboard route -- Menu owns Return/Space and
    // fires the row's own `activated` through its connection to the current
    // row. This pins the ABSENCE: if a keyboard route is ever added directly
    // to the type, this fails the day it lands, which is the point.
    function test_the_row_itself_has_no_keyboard_route() {
        plainClicked.clear();
        plainRow.forceActiveFocus();
        compare(plainRow.focused, true, "the row did not take keyboard focus");

        keyClick(Qt.Key_Return);
        keyClick(Qt.Key_Space);
        compare(plainClicked.count, 0,
            "activated fired from a bare key event on the row itself -- ListRow gained its own keyboard route, "
            + "update this test to pin what it now does");
    }

    // The leading box costs nothing while empty: the whole difference an
    // icon makes is its own box plus the one spacing gap that appears
    // alongside it.
    function test_an_empty_leading_slot_takes_no_space() {
        compare(withLeading.implicitWidth - noLeading.implicitWidth, withLeading.leadingSize + Style.space2,
            "an icon did not cost exactly its box plus one spacing gap -- the empty leading slot is not free");
    }

    // The trailing slot costs nothing while empty: the whole difference a
    // trailing item makes is its own implicit width plus the one spacing
    // gap that appears alongside it.
    function test_an_empty_trailing_slot_takes_no_space() {
        const delta = withTrailing.implicitWidth - noTrailing.implicitWidth;
        const expected = trailingReading.implicitWidth + Style.space2;
        verify(Math.abs(delta - expected) <= 1,
            "a trailing item did not cost its width plus one spacing gap -- the empty trailing slot is not free");
    }

    // A report-only row (interactive: false) renders at full strength even
    // when recede is true. It refuses hover/click like a disabled row, but
    // its content does not dim -- a live reading is not stale.
    function test_report_only_row_renders_at_full_strength_even_with_recede() {
        compare(reportWithRecede.receded, false, "a report-only row with recede reported receding");
        compare(reportWithRecede.proseColor, Style.text,
            "a report-only row with recede did not render at full strength");

        // The plain interactive row with recede (not selected) recedes by colour.
        compare(plainWithRecede.receded, true, "an interactive row with recede did not report receding");
        compare(plainWithRecede.proseColor, Style.recede(Style.text),
            "an interactive row with recede did not recede");

        // Both should still refuse hover and click
        neutral();
        mouseMove(reportWithRecede, 10, 16);
        compare(reportWithRecede.hovered, false, "a report-only row claimed hover");
        mouseClick(reportWithRecede, 10, 16);
        // No signal spy on reportWithRecede, but we know it doesn't emit from other tests

        neutral();
        mouseMove(plainWithRecede, 10, 16);
        compare(plainWithRecede.hovered, true, "an interactive row did not report hover");
        compare(plainWithRecede.receded, false, "a hovered row kept receding");
    }
}
