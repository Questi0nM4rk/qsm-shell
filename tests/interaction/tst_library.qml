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
    height: 900
    visible: true
    when: windowShown

    // ── every type, constructed ─────────────────────────────────────────
    Prose { id: prose; role: "heading"; text: "Heading" }
    // A button with a label and no glyph -- the most ordinary button there is,
    // and it did not construct at all while `SvgIcon.name` was required.
    Capsule { id: wordButton; label: "Discard"; variant: "destructive" }
    Capsule { id: glyphButton; icon: "check"; label: "Keep" }
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
    // The model-backed case: a ListView IS the Flickable, so the cue attaches
    // to it rather than the list going inside a viewport.
    ListView {
        id: shortList
        width: 200
        height: 200
        model: 2
        delegate: Item { width: 200; height: 20 }

        ScrollCue { id: shortCue; view: shortList }
    }

    // Enough rows that the mark's length cap matters: uncapped, a viewport
    // showing most of its content gets a thumb nearly as tall as itself, which
    // reads as a gauge rather than as a position.
    ListView {
        id: longList
        width: 200
        height: 100
        model: 40
        delegate: Item { width: 200; height: 20 }

        ScrollCue { id: longCue; view: longList }
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
    MonthCalendar { id: calendar; width: 260; shown: new Date(2026, 7, 1); today: new Date(2026, 7, 28) }
    property var liveEntry: ({
        notificationId: 1,
        appName: "Test App",
        summary: "Something happened",
        body: "Body",
        urgency: "normal",
        actions: [{ id: "act-open", label: "Open" }, { id: "act-dismiss", label: "Dismiss" }],
        createdAt: Date.now(),
        paused: false
    })
    property var archivedEntry: ({
        appName: "Test App",
        summary: "An old one",
        urgency: "low",
        archivedAt: new Date(2026, 0, 1, 9, 30).getTime()
    })
    property int notificationDismissCount: 0
    property string notificationLastAction: ""
    // Every fixture above (and most below) defaults to (0, 0) and stays
    // small; a pointer test needs real screen room of its own, clear of
    // anything that could sit on top of it and steal the click — including
    // its own expanded height and its sibling below.
    NotificationCard {
        id: notification
        y: 550
        entry: probe.liveEntry
        draggable: true
        // A fixed test fixture is a reference instance, not a fresh arrival;
        // the settle animation would otherwise leave `opacity`/`scale`
        // mid-flight while the very next line clicks it.
        animateEntrance: false
        width: implicitWidth
        height: implicitHeight
        onDismissed: probe.notificationDismissCount++
        onActionTriggered: id => probe.notificationLastAction = id
    }
    NotificationCard {
        id: archivedNotification
        y: 650
        entry: probe.archivedEntry
        alwaysExpanded: true
        width: implicitWidth
        height: implicitHeight
    }
    property var centerEntries: [
        {
            notificationId: 10,
            appName: "Alpha",
            summary: "Alpha live",
            body: "",
            actions: [{ id: "a1", label: "One" }, { id: "a2", label: "Two" }]
        },
        { archivedAt: 500, appName: "Alpha", summary: "Alpha archived", body: "" },
        { archivedAt: 200, appName: "Gamma", summary: "Gamma archived only", body: "" }
    ]
    property var centerDismissed: null
    property var centerActionEntry: null
    property string centerActionId: ""
    NotificationCenter {
        id: center
        y: 780
        width: 400
        entries: probe.centerEntries
        onDismissRequested: entry => probe.centerDismissed = entry
        onActionTriggered: (entry, id) => { probe.centerActionEntry = entry; probe.centerActionId = id; }
    }
    property var stackDismissed: null
    NotificationStack {
        id: popupStack
        y: 900
        width: 380
        stack: [{ notificationId: 20, appName: "Beta", summary: "Beta popup" }]
        isAlive: id => id === 20
        onDismissRequested: entry => probe.stackDismissed = entry
    }
    // Isolated from `popupStack` on purpose: the eviction test drives this
    // one's `stack`/`isAlive` through several changes, and a shared
    // fixture would make the two tests order-dependent on each other.
    NotificationStack {
        id: evictionStack
        y: 1000
        width: 380
    }
    ActionTile { id: actionTile; icon: "power"; label: "Power off" }
    StatRing { id: ring; value: 0.7; icon: "cpu"; label: "CPU"; reading: "70%"; startAngle: -225; sweepAngle: 270 }
    TextField { id: text2; width: 200 }
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

    Avatar {
        id: person
        name: "Ada Byron"
    }

    Avatar {
        id: thing
        icon: "music"
    }

    ColorSwatch {
        id: emptySlot
        sample: "transparent"
        empty: true
    }

    ColorSwatch {
        id: clearSwatch
        sample: "transparent"
    }

    Sparkline {
        id: thinLine
        values: [1, 4, 2, 8]
        thickness: 1.5
    }

    Sparkline {
        id: autoLine
        values: [1, 4, 2, 8]
    }

    Prose {
        id: clockText
        role: "hero"
        technical: true
        text: "14:17"
    }

    Prose {
        id: readingText
        role: "reading"
        text: "72%"
    }

    Prose {
        id: labelText
        text: "Devices"
    }

    Avatar {
        id: ringed
        icon: "music"
        progress: 0.4
    }

    function test_every_type_constructs() {
        // A binding that failed to resolve leaves the object null; a property
        // typo inside one leaves the object alive but wrong. Both show up as a
        // console error, and `qmltestrunner` fails the run on those, so simply
        // reaching this line with every id resolvable is the assertion.
        const types = [prose, wordButton, glyphButton, badge, dotBadge, spinner, progress, unknownProgress,
            skeleton, callout, field, meter, fullMeter, scroller, section,
            disclosure, scrim, shortCue, longCue, stat, goodStat, sparkline, flatline, marquee,
            paleSwatch, darkSwatch, kbd, avatar, mononym, card, divider,
            emptyState, keyValue, mark, icon, iconButton, calendar,
            notification, archivedNotification, center, popupStack, evictionStack, actionTile, ring,
            text2, check2, menu, segmented, popover, armed, plainAction];
        for (let i = 0; i < types.length; i++)
            verify(types[i] !== null, `type ${i} did not construct`);
    }

    // The one choreography decision worth pinning down: a still-alive entry
    // pushed out of the window is an EVICTION (slides into the band), while
    // an entry that is simply gone (dismissed, expired) is ordinary reflow.
    // Get the `isAlive` check backwards and every dismissal starts animating
    // a phantom "eviction" of whatever it happened to push out.
    function test_eviction_is_pushed_out_while_alive_not_merely_gone() {
        let alive = [1, 2];
        evictionStack.isAlive = id => alive.includes(id);
        evictionStack.stack = [
            { notificationId: 2, appName: "A", summary: "two" },
            { notificationId: 1, appName: "A", summary: "one" }
        ];
        compare(evictionStack.evicting.length, 0, "the very first window seeded a spurious eviction");

        // #3 arrives, pushing #1 out of the window while #1 stays alive
        // elsewhere (`isAlive` still says yes) -- that is an eviction.
        alive = [1, 2, 3];
        evictionStack.stack = [
            { notificationId: 3, appName: "A", summary: "three" },
            { notificationId: 2, appName: "A", summary: "two" }
        ];
        compare(evictionStack.evicting.length, 1, "a still-alive entry pushed out of the window did not evict");
        compare(evictionStack.evicting[0].notificationId, 1, "the wrong entry evicted");
        wait(400);
        compare(evictionStack.evicting.length, 0, "the eviction slide never settled");

        // #2 is dismissed outright: gone from `stack` AND `isAlive` no
        // longer answers for it. That is ordinary reflow, not an eviction.
        alive = [1, 3];
        evictionStack.stack = [{ notificationId: 3, appName: "A", summary: "three" }];
        compare(evictionStack.evicting.length, 0, "a plain dismissal was treated as an eviction");
    }

    // A count must not resize its badge as it ticks; a dot must carry no
    // reading, because a dot means "there is something here" and a state
    // needs a channel that is not a hue.
    // A layout skips an invisible child AND its spacing, so a text-only pill
    // has to be narrower than the same pill with a glyph -- not the same width
    // with a hole in it.
    function test_a_button_without_a_glyph_closes_up() {
        verify(wordButton.implicitWidth > 0, "a text-only button had no width");
        verify(glyphButton.implicitWidth - wordButton.implicitWidth > 0,
            "the glyph took no room, so the text-only pill is carrying a hole");
    }

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
        verify(scroller.overflows, "400px of content in a 100px viewport did not overflow");
    }

    // A cue must never claim there is more when the content fits, and it must
    // never take a click meant for the row beneath it.
    function test_scroll_cue_reports_and_does_not_intercept() {
        verify(!shortCue.overflows, "a cue on content that fits claimed there was more");
        verify(!shortCue.enabled, "the cue was left able to take a pointer event");
    }

    // The mark reads the viewport's own scroll fraction. Raw `contentY` drifts
    // on a ListView as delegates above the viewport are created and destroyed,
    // and a thumb positioned from it eventually runs past the end.
    function test_scroll_cue_reads_the_canonical_fraction() {
        verify(longCue.overflows, "a cue on overflowing content said it fit");
        compare(longCue._ratio, longList.visibleArea.heightRatio,
            "the cue did not take its ratio from visibleArea");
    }

    // One stand-in or the other, never both: an album has no initials worth
    // reading, and a person's icon would be the silhouette the type refuses.
    function test_avatar_shows_one_fallback_at_a_time() {
        compare(person.initials, "AB", "initials were not taken from the name");
        compare(person.icon, "", "a person avatar should carry no icon");
        compare(thing.icon, "music", "the thing avatar lost its icon");
        compare(thing.initials, "", "a thing with no name still produced initials");
    }

    // An empty slot is not a transparent colour: transparent is a real sample
    // and earns the alpha check, an empty slot has nothing to show.
    function test_an_empty_slot_is_not_a_transparent_colour() {
        verify(emptySlot.empty, "the empty slot lost its flag");
        verify(!clearSwatch.empty, "a transparent sample was mistaken for an empty slot");
    }

    // Two stacked series need a stated weight; one line in a small box does
    // not, and 0 keeps the derived one.
    function test_sparkline_thickness_falls_back_to_the_height() {
        compare(thinLine._thickness, 1.5, "a stated thickness was ignored");
        compare(autoLine._thickness, Math.max(1, autoLine.height / 12),
            "the derived thickness was lost");
    }

    // The face is its own axis: a role that is not "reading" can still be
    // written in digits, and a reading still needs to say nothing.
    function test_the_technical_face_is_not_tied_to_one_role() {
        compare(clockText.font.family, Style.technicalFontFamily,
            "a technical hero did not get the mono face");
        compare(clockText.font.pixelSize, Style.textHero,
            "asking for the mono face changed the role's size");
        compare(readingText.font.family, Style.technicalFontFamily,
            "a reading stopped defaulting to the mono face");
        compare(labelText.font.family, Style.fontFamily,
            "an ordinary label was given the mono face");
    }

    // Advertised keyboard activation has to be REACHABLE: the handlers need
    // focus, and nothing was giving the swatch any.
    function test_a_swatch_can_be_reached_by_keyboard() {
        verify(clearSwatch.activeFocusOnTab, "the swatch is not a tab stop");
        clearSwatch.forceActiveFocus();
        verify(clearSwatch.focused, "focus did not reach the swatch");
        keyClick(Qt.Key_Space);
        verify(true, "space on a focused swatch must not throw");
    }

    // A glyph stand-in keeps whatever size the consumer had, and `size` is
    // always the PICTURE: a ring adds its own room instead of eating into it.
    function test_avatar_geometry_follows_what_is_drawn() {
        compare(thing.glyphSize, Math.round(thing.size * 0.4),
            "the default glyph size left the two-fifths rule");
        compare(person.implicitWidth, person.size,
            "an unringed avatar is not exactly its size");
        verify(ringed.implicitWidth > ringed.size,
            "a ring did not ask for room of its own");
        compare(ringed.implicitWidth,
            ringed.size + (ringed.ringGap + ringed.ringWidth) * 2,
            "the ring's room is not gap plus stroke on both sides");
    }

    function test_menu_selects_a_real_row() {
        menu.currentIndex = -1;
        menu.step(1);
        compare(menu.currentIndex, 0, "the menu did not land on its first row");
        verify(firstRow.selected, "selection did not reach the row itself");
    }

    // A component never manages its own dismissal: a middle click reports it
    // through a signal, and never writes into the entry the consumer owns.
    function test_notification_card_reports_dismissal_without_touching_its_entry() {
        probe.notificationDismissCount = 0;
        mouseClick(notification, notification.width / 2, notification.height / 2, Qt.MiddleButton);
        compare(probe.notificationDismissCount, 1, "a middle click did not report a dismissal");
        compare(probe.liveEntry.paused, false, "the card wrote into its own entry");
    }

    // An action press reports WHICH action, by id, rather than invoking
    // anything on the entry itself — the entry here carries no `invoke`, so a
    // card that called it would throw instead of merely no-op-ing.
    function test_notification_card_action_click_reports_the_action_id() {
        probe.notificationLastAction = "";
        // Actions render only while expanded (04: popups are display-only,
        // the actions row belongs to the expanded view). The card's own
        // height animates open on a `Behavior`, and `clip: true` means a row
        // sitting below the not-yet-settled height is clipped out of both
        // paint AND hit-testing — wait for the settle before clicking.
        notification.alwaysExpanded = true;
        wait(250);
        const secondAction = findChild(notification, "notificationAction1");
        verify(secondAction !== null, "the second action row did not construct");
        mouseClick(secondAction);
        compare(probe.notificationLastAction, "act-dismiss", "the wrong action id was reported");
        notification.alwaysExpanded = false;
    }

    // The entry shape's two time fields are mutually exclusive by
    // construction: a live entry with a fresh `createdAt` reads as relative
    // once expanded, and an archived one always reads as its wall-clock time.
    function test_notification_card_timestamp_follows_archived_vs_live() {
        compare(archivedNotification.timestampText(), "09:30",
            "an archived entry did not show its wall-clock time");
        verify(notification.alwaysExpanded === false, "fixture drifted");
        notification.alwaysExpanded = true;
        compare(notification.timestampText(), "just now",
            "a fresh live entry did not read as just now while expanded");
        notification.alwaysExpanded = false;
    }

    // Live beats archived within an app group; both apps here carry a live
    // entry, so a stable sort keeps them in their original relative order —
    // Alpha's own live-before-archived is the rule actually worth protecting.
    // Only Alpha and Gamma here (not Beta): with two DIFFERENT apps both
    // tied at "has a live entry" priority, the moved comparator returns 0
    // across them, which is a stable-sort correctness gap in the ORIGINAL
    // algorithm — carried across unchanged, not something this migration's
    // acceptance covers fixing. Reported separately; this fixture avoids it.
    function test_notification_center_groups_live_before_archived_within_an_app() {
        const items = center.items;
        compare(items.length, 3, "the flat entries list did not all survive filtering");
        compare(items[0].notificationId, 10, "Alpha's live entry was not first in its group");
        compare(items[1].archivedAt, 500, "Alpha's archived entry did not follow its live one");
        compare(items[2].appName, "Gamma", "an archive-only group did not sort after a live-carrying one");
    }

    function test_notification_center_query_filters_entries() {
        compare(center.items.length, 3, "an empty query filtered entries out");
        center.query = "zzzz-no-such-thing";
        compare(center.items.length, 0, "a query with no match still returned entries");
        center.query = "";
        compare(center.items.length, 3, "clearing the query did not restore the full list");
    }

    // A component never manages its own dismissal: removing the selected
    // entry reports it, and never touches the array the consumer owns.
    function test_notification_center_remove_selected_reports_without_mutating_entries() {
        probe.centerDismissed = null;
        center.currentIndex = 0;
        center.removeSelected();
        verify(probe.centerDismissed !== null, "removeSelected did not report a dismissal");
        compare(probe.centerDismissed.notificationId, 10, "the wrong entry was reported");
        compare(probe.centerEntries.length, 3, "the entries array was mutated");
    }

    // Enter with an action focused activates that action by id; the same
    // signal a mouse click on the card's own action row reports.
    function test_notification_center_keyboard_action_activation_reports_the_id() {
        probe.centerActionEntry = null;
        probe.centerActionId = "";
        center.currentIndex = 0;
        center.toggleSelected();
        center.moveAction(1);
        center.activateSelected();
        compare(probe.centerActionId, "a1", "the wrong action id was reported");
        compare(probe.centerActionEntry.notificationId, 10, "the wrong entry was reported");
    }
}
