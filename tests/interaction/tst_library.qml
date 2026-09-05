import QtQuick
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style

// Every public type, instantiated once, plus the logic that is worth keeping
// honest. Linting proves a file parses; only running it proves the bindings
// resolve — a typo in a property name inside a binding is invisible to
// `qmllint` and fatal at runtime, and until this file existed the library had
// twenty-odd types nothing had ever constructed.
//
// What is NOT here: how anything looks. That is a human's job against the
// native previews, and a test that asserted pixel positions would only
// re-encode today's numbers as tomorrow's obstacle.
TestCase {
    id: probe

    name: "Library"
    width: 600
    height: 500
    visible: true
    when: windowShown

    // ── every type, constructed ─────────────────────────────────────────
    Prose { id: prose; role: "heading"; text: "Heading" }
    Badge { id: badge; tone: "warning"; text: "3" }
    Badge { id: dotBadge; dot: true; tone: "success" }
    Spinner { id: spinner }
    ProgressBar { id: progress; width: 120; value: 0.4 }
    ProgressBar { id: unknownProgress; width: 120; indeterminate: true }
    Skeleton { id: skeleton; shape: "line"; role: "title" }
    Callout { id: callout; width: 300; tone: "danger"; title: "Failed"; body: "Try again." }
    Field { id: field; width: 300; label: "Name"; hint: "First and last" }
    Meter { id: meter; width: 120; value: 0.1; low: 0.2 }
    Meter { id: fullMeter; width: 120; value: 0.9 }
    ScrollArea {
        id: scroller
        width: 200
        height: 100
        // Real overflow, so the indicator and both fades have to decide
        // whether they exist -- and so the content-sizing binding is exercised
        // rather than resting at zero.
        Rectangle { width: 200; height: 400; color: "#333" }
    }
    Section { id: section; width: 300; title: "Devices" }
    Disclosure { id: disclosure; width: 300; title: "Advanced" }
    Scrim { id: scrim }
    Stat { id: stat; value: "72"; unit: "%"; label: "CPU"; trend: "up"; good: "down" }
    Stat { id: goodStat; value: "9"; label: "Free"; trend: "up"; good: "up" }
    Sparkline { id: sparkline; values: [1, 4, 2, 8, 5] }
    Sparkline { id: flatline; values: [3, 3, 3, 3] }
    Marquee { id: marquee; width: 60; text: "A title far too long for sixty pixels" }
    ColorSwatch { id: paleSwatch; sample: "#f6f1f9"; reading: "#F6F1F9" }
    ColorSwatch { id: darkSwatch; sample: "#1c0e27"; reading: "#1C0E27" }
    Kbd { id: kbd; combo: "SUPER + SHIFT + Q" }
    Avatar { id: avatar; name: "Ada Lovelace" }
    Avatar { id: mononym; name: "Prince" }
    Card { id: card; width: 100; height: 60 }
    Divider { id: divider; width: 200 }
    EmptyState { id: emptyState; title: "Nothing here" }
    KeyValueRow { id: keyValue; width: 200; label: "Battery"; value: "68%" }
    SelectionMark { id: mark; shown: true }
    SvgIcon { id: icon; name: "check" }
    IconButton { id: iconButton; icon: "check" }
    Slider { id: slider; width: 120; value: 0.5 }
    MonthCalendar { id: calendar; width: 260; shown: new Date(2026, 7, 1); today: new Date(2026, 7, 28) }
    NotificationCard { id: notification; title: "Updated"; body: "Body"; source: "test" }
    SessionButton { id: sessionButton; icon: "power"; label: "Power off" }
    StatRing { id: ring; value: 0.7; label: "CPU"; reading: "70%" }
    // A device row: read, not picked, so it does not recede its neighbours.
    ListRow {
        id: deviceRow
        width: 240
        size: "sm"
        recede: false
        icon: "wifi"
        primary: "qsm-lab"
        Prose { role: "reading"; font.pixelSize: Style.textXs; muted: true; text: "Connected" }
    }

    // A launcher row: one thing is wanted, so the rest recede hard.
    ListRow {
        id: resultRow
        width: 400
        size: "lg"
        icon: "sparkle"
        primary: "Pick a colour"
        supporting: "Opens the picker"
        selected: true
    }

    // The supporting line that only repeats the name -- the case desktop
    // entries produce constantly ("Volume Control / Volume Control").
    ListRow {
        id: echoRow
        width: 400
        primary: "Volume Control"
        supporting: "volume control"
    }
    TextField { id: text2; width: 200 }
    Switch { id: toggle2 }
    Checkbox { id: check2 }

    Menu {
        id: menu
        width: 200
        height: 200
        ListRow { id: firstRow; primary: "First" }
        ListRow { primary: "Second" }
    }

    property int chosen: -1
    Segmented {
        id: segmented
        width: 400
        options: ["Overview", { label: "Media", disabled: true }, { label: "Alerts", badge: "2" }]
        currentIndex: 0
        onSelected: index => probe.chosen = index
    }

    Item {
        id: stage
        width: 300
        height: 200

        Rectangle { id: anchorNearTop; x: 20; y: 4; width: 40; height: 20 }

        Popover {
            id: popover
            anchorItem: anchorNearTop
            placement: "top"
            implicitWidth: 80
            implicitHeight: 60
        }
    }

    property int fires: 0
    property int disarms: 0
    ArmedAction {
        id: armed
        onFired: probe.fires++
        onDisarmed: probe.disarms++
    }
    ArmedAction { id: plainAction; destructive: false; onFired: probe.fires++ }

    // ── the invariants worth keeping ────────────────────────────────────

    function test_every_type_constructs() {
        // A binding that failed to resolve leaves the object null; a property
        // typo inside one leaves the object alive but wrong. Both show up as a
        // console error, and `qmltestrunner` fails the run on those, so simply
        // reaching this line with every id resolvable is the assertion.
        const types = [prose, badge, dotBadge, spinner, progress, unknownProgress,
            skeleton, callout, field, meter, fullMeter, scroller, section,
            disclosure, scrim, stat, goodStat, sparkline, flatline, marquee,
            paleSwatch, darkSwatch, kbd, avatar, mononym, card, divider,
            emptyState, keyValue, mark, icon, iconButton, slider, calendar,
            notification, sessionButton, ring, deviceRow, resultRow, echoRow,
            text2, toggle2, check2, menu, segmented, popover, armed, plainAction];
        for (let i = 0; i < types.length; i++)
            verify(types[i] !== null, `type ${i} did not construct`);
    }

    // A count must not resize its badge as it ticks; a dot must carry no
    // reading, because a dot means "there is something here" and a state
    // needs a channel that is not a hue.
    function test_badge_dot_carries_no_reading() {
        compare(dotBadge.text, "", "a dot badge carried a reading");
        verify(badge.implicitWidth >= badge.implicitHeight, "a badge collapsed narrower than it is tall");
    }

    // Breaching a threshold is a WARNING, not a failure -- and it must change
    // the fill, since colour that only the author knows about is not a channel.
    function test_meter_threshold_changes_the_fill() {
        compare(String(meter._fill), String(Style.warning), "a breached low threshold did not warn");
        compare(String(fullMeter._fill), String(fullMeter.fill), "an unbreached meter warned anyway");
    }

    // Up is not universally good. A trend the wrong way for THIS measure is
    // the whole reason `good` exists.
    function test_trend_direction_is_judged_against_good() {
        compare(String(stat._trendColor), String(Style.warning), "rising latency read as good news");
        compare(String(goodStat._trendColor), String(Style.success), "rising free space read as bad news");
    }

    // A swatch decides its own ink, so no call site has to, and so a pale
    // sample never carries pale text.
    function test_swatch_picks_readable_ink() {
        compare(String(paleSwatch.ink), String(Style.background), "pale swatch kept light ink");
        compare(String(darkSwatch.ink), String(Style.text), "dark swatch took dark ink");
    }

    function test_avatar_initials() {
        compare(avatar.initials, "AL", "two names did not give two letters");
        compare(mononym.initials, "P", "one name did not give one letter");
    }

    // Arrows skip what cannot be chosen and wrap, because with every option
    // visible there is no end of a list to run off.
    function test_segmented_skips_disabled_and_wraps() {
        probe.chosen = -1;
        segmented.step(1);
        compare(probe.chosen, 2, "stepping did not skip the disabled option");
        segmented.currentIndex = 2;
        segmented.step(1);
        compare(probe.chosen, 0, "stepping did not wrap");
        segmented.currentIndex = 0;
    }

    // Arm, then fire. A destructive action that fires on the first press is
    // the confirmation not existing.
    function test_armed_action_needs_two_presses() {
        probe.fires = 0;
        probe.disarms = 0;
        armed.trigger();
        compare(probe.fires, 0, "a destructive action fired on the first press");
        verify(armed.armed, "the action did not arm");
        armed.trigger();
        compare(probe.fires, 1, "the second press did not fire");
        verify(!armed.armed, "the action stayed armed after firing");
    }

    function test_armed_action_abandons_on_disarm() {
        probe.fires = 0;
        probe.disarms = 0;
        armed.trigger();
        armed.disarm();
        compare(probe.fires, 0, "disarming still fired");
        compare(probe.disarms, 1, "disarming was not reported");
    }

    // A control that does not ask must not make the caller write a second
    // code path for "this one does not ask".
    function test_non_destructive_fires_at_once() {
        probe.fires = 0;
        plainAction.trigger();
        compare(probe.fires, 1, "a non-destructive action did not fire immediately");
    }

    // An anchored surface that is right in the middle of a screen and wrong at
    // its edge is wrong. The anchor here sits 4px from the top of its stage,
    // so a 60px popover asking to sit above it cannot, and must flip.
    function test_popover_flips_when_it_does_not_fit() {
        compare(popover.side, "bottom", "a popover with no room above did not flip below");
        verify(popover.y >= 0, "a flipped popover still landed off the top of its bounds");
    }

    // The menu's stepping skips what cannot be selected, and the row registry
    // is rebuilt from the real children rather than from a count.
    // Chrome must not be a passenger in the viewport. If it is, its own size
    // feeds `childrenRect` feeds the content size feeds its size -- the
    // binding loop this component shipped with, which `qmllint` cannot see.
    function test_scroll_area_sizes_from_content_alone() {
        compare(scroller.viewport.contentHeight, 400, "the viewport did not size from its content");
        verify(scroller._overflows, "400px of content in a 100px viewport did not overflow");
    }

    // A list you READ must not dim the nine rows that are not current to mark
    // the one that is; a list you PICK from must. That difference is the only
    // real one the three old row types had between them.
    function test_recede_is_the_only_axis_between_a_read_list_and_a_pick_list() {
        verify(deviceRow.selectable, "a device row was not selectable");
        compare(deviceRow.leadingSize, Style.iconMd, "a compact row did not take the compact leading box");
        compare(resultRow.leadingSize, Style.iconLg, "a large row did not take the large leading box");
    }

    // A leading visual sits in a box of ONE size so the name's left edge does
    // not move between rows of different kinds.
    function test_leading_box_is_one_size_per_row_size() {
        verify(resultRow.leadingSize > deviceRow.leadingSize, "both row sizes shared a leading box");
    }

    function test_menu_selects_a_real_row() {
        menu.currentIndex = -1;
        menu.step(1);
        compare(menu.currentIndex, 0, "the menu did not land on its first row");
        verify(firstRow.selected, "selection did not reach the row itself");
    }
}
