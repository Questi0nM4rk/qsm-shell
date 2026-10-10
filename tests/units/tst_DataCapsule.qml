import QtQuick
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style

TestCase {
    id: probe
    name: "DataCapsule"
    width: 1000
    height: 800
    visible: true
    when: windowShown

    property int opened: 0
    property int nested: 0
    property int expired: 0
    property bool answerExpiry: true
    property int soundOpened: 0
    property int soundExpired: 0

    QtObject { id: reducedTheme; property bool reducedMotion: true }

    DataCapsule {
        id: capsule
        x: 80
        y: 80
        interactive: true
        onActivated: probe.opened++
        onTimeoutRequested: {
            probe.expired++;
            if (probe.answerExpiry)
                capsule.shown = false;
        }
        IconButton {
            id: inner
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon: "check"
            onClicked: probe.nested++
        }
    }

    // The composition the unit and the story host: a real reading in the slot,
    // the value HOST-owned and written back through the gesture, so a change
    // to the capsule's own geometry has to leave the model alone and leave
    // every route into the slot working. Geometry lives only where the owner
    // of the capsule put it: the capsule takes its own natural size, which for
    // a vertical `lg` is 96 x 572.
    property int reading: 42
    property int muted: 0

    DataCapsule {
        id: sound
        x: 420
        y: 200
        size: "md"
        interactive: true
        onActivated: probe.soundOpened++
        onTimeoutRequested: probe.soundExpired++
        Slider {
            id: level
            anchors.fill: parent
            orientation: sound.orientation
            size: sound.size
            raised: true
            value: probe.reading / 100
            labelIcon: "volume"
            labelPosition: sound.orientation === Qt.Vertical ? "below" : "left"
            labelClickable: true
            wheelUnits: Style.sliderKeyboardUnits
            onMoved: probe.reading = Math.round(level.value * 100)
            onLabelClicked: {
                probe.muted++;
                probe.reading = 0;
            }
        }
    }

    function init() {
        capsule.shown = false;
        capsule.reset();
        capsule.timeout = 0;
        capsule.hoverStay = true;
        capsule.interactive = true;
        capsule.enabled = true;
        probe.opened = 0;
        probe.nested = 0;
        probe.expired = 0;
        probe.answerExpiry = true;
        mouseMove(probe, 600, 320);
        capsule.shown = true;
        tryCompare(capsule, "opacity", 1);

        sound.shown = false;
        sound.reset();
        sound.timeout = 0;
        sound.hoverStay = true;
        sound.interactive = true;
        sound.enabled = true;
        sound.size = "md";
        sound.orientation = Qt.Vertical;
        probe.reading = 42;
        probe.muted = 0;
        probe.soundOpened = 0;
        probe.soundExpired = 0;
        mouseMove(probe, 600, 320);
        sound.shown = true;
        tryCompare(sound, "opacity", 1);
    }

    function cleanup() {
        capsule.shown = false;
        capsule.reset();
        sound.shown = false;
        sound.reset();
    }

    function test_pointer_keyboard_programmatic_and_nested_action() {
        mouseClick(capsule, capsule.padding + 10, capsule.height / 2);
        compare(probe.opened, 1);
        capsule.forceActiveFocus();
        keyClick(Qt.Key_Return);
        keyClick(Qt.Key_Space);
        verify(capsule.activate());
        compare(probe.opened, 4);
        mouseClick(inner);
        compare(probe.nested, 1);
        compare(probe.opened, 4, "nested action also activated capsule");
        mouseClick(capsule, 2, 2);
        compare(probe.opened, 5, "capsule padding is a dead action zone");
        verify(capsule.shown, "activation must not dismiss host state");
    }

    function test_timed_hover_resume_and_host_dismissal() {
        mouseMove(inner, inner.width / 2, inner.height / 2);
        tryCompare(capsule, "pointerHovered", true);
        capsule.timeout = 120;
        wait(180);
        compare(probe.expired, 0, "hover did not pause expiry over nested content");
        mouseMove(probe, 600, 320);
        tryCompare(capsule, "keepOpen", false);
        tryCompare(probe, "expired", 1);
        compare(capsule.shown, false);
        compare(capsule.acceptsInput, false);
        tryCompare(capsule, "present", false);
    }

    function test_focus_retention_and_restart_same_value() {
        inner.forceActiveFocus();
        tryCompare(capsule, "keepOpen", true);
        capsule.timeout = 120;
        wait(180);
        compare(probe.expired, 0);
        capsule.shown = false;
        capsule.shown = true;
        tryCompare(capsule, "keepOpen", false);
        capsule.restart();
        wait(60);
        capsule.restart();
        wait(70);
        compare(probe.expired, 0, "repeat presentation failed to refresh timeout");
        tryCompare(probe, "expired", 1);
    }

    function test_reset_persistent_and_single_intent_without_host_response() {
        capsule.timeout = 80;
        capsule.reset();
        wait(160);
        compare(probe.expired, 0, "reset left pending work");
        capsule.timeout = 0;
        wait(160);
        compare(probe.expired, 0, "persistent capsule expired");
        probe.answerExpiry = false;
        capsule.timeout = 80;
        tryCompare(probe, "expired", 1);
        verify(capsule.shown, "component mutated host visibility");
        wait(160);
        compare(probe.expired, 1, "expiry intent repeated without a new presentation");
    }

    function test_passive_disabled_hidden_and_interrupted_fade() {
        capsule.interactive = false;
        mouseClick(capsule, 20, capsule.height / 2);
        verify(!capsule.activate());
        compare(probe.opened, 0);
        capsule.interactive = true;
        capsule.enabled = false;
        verify(!capsule.activate());
        capsule.enabled = true;
        capsule.shown = false;
        verify(!capsule.activate());
        compare(capsule.acceptsInput, false);
        capsule.shown = true;
        tryCompare(capsule, "opacity", 1);
        verify(capsule.present);
        capsule.shown = false;
        tryCompare(capsule, "present", false);
    }

    // ── the sound capsule: the composition the unit and the story host ──
    // The cases below all run against `sound`, whose slot holds a real Slider
    // with the reading HOST-owned. Every one drives a REAL pointer, wheel or
    // key event, and every assertion is on a fact the host reads afterwards --
    // never on a size, a colour or a rendered pixel.

    // The wheel is how a volume capsule is actually used, so it is the route
    // these cases lean on: it moves the host's reading through the slot while
    // the capsule stays put.
    function test_a_wheel_notch_in_the_slot_moves_the_host_reading() {
        mouseMove(level, level.width / 2, level.height / 2);
        mouseWheel(level, level.width / 2, level.height / 2, 0, 120);
        wait(60);
        compare(probe.reading, 47, "a wheel notch did not move the host's reading by wheelUnits");

        mouseWheel(level, level.width / 2, level.height / 2, 0, -120);
        wait(60);
        compare(probe.reading, 42, "a notch back did not return the reading");
    }

    // The nested label is the slot's OWN action. A capsule that wraps it must
    // not swallow it and must not turn it into a capsule activation: a mute
    // click mutes, and the body it sits on does not open.
    function test_the_slot_label_acts_for_itself_and_not_as_the_body() {
        const label = findChild(level, "sliderLabel");
        verify(label !== null, "the slider lost its label objectName");

        mouseMove(label, label.width / 2, label.height / 2);
        mouseClick(label, label.width / 2, label.height / 2);
        compare(probe.muted, 1, "the slot label did not take its own click");
        compare(probe.reading, 0, "the mute did not reach the host's reading");
        compare(probe.soundOpened, 0, "the slot label also opened the whole capsule");
        verify(sound.shown, "a nested action dismissed the capsule");
    }

    // A shape change is a HOST decision made while the capsule is up. It must
    // not disturb what is already on screen: the reading survives it, and every
    // route -- wheel into the slot, click on the body, the keyboard -- still
    // reaches the same model afterwards. This is the case that a reparented or
    // rebuilt slot would break silently: nothing throws, the value just stops
    // answering.
    function test_orientation_and_size_changes_keep_the_reading_and_every_route() {
        const shapes = [
            { size: "md", orientation: Qt.Vertical },
            { size: "lg", orientation: Qt.Horizontal },
            { size: "sm", orientation: Qt.Horizontal },
            { size: "lg", orientation: Qt.Vertical },
            { size: "md", orientation: Qt.Vertical }
        ];

        for (let i = 0; i < shapes.length; i++) {
            const shape = shapes[i];
            const label = shape.size + "/" + (shape.orientation === Qt.Vertical ? "vertical" : "horizontal");
            sound.size = shape.size;
            sound.orientation = shape.orientation;
            tryCompare(sound, "acceptsInput", true, 500,
                label + ": the capsule stopped accepting input after the shape change");
            compare(probe.reading, 42, label + ": the shape change rewrote the host's reading");
            verify(level.enabled, label + ": the slot lost its input after the shape change");

            // The wheel, through the resized slot. The notch is one wheelUnits
            // of the host's own reading, so a slot that silently disconnected
            // shows up as a reading that did not move.
            mouseMove(level, level.width / 2, level.height / 2);
            mouseWheel(level, level.width / 2, level.height / 2, 0, 120);
            wait(60);
            compare(probe.reading, 47, label + ": the wheel stopped reaching the reading");

            mouseWheel(level, level.width / 2, level.height / 2, 0, -120);
            wait(60);
            compare(probe.reading, 42, label + ": a notch back did not return the reading");

            // The body, on its own dead padding zone: a capsule that resized
            // must not have turned its own padding into a second live region.
            mouseClick(sound, sound.padding + 2, 2);
            compare(probe.soundOpened, i + 1, label + ": the body stopped opening the capsule");
        }
    }

    // Unavailable is not passive. A disabled capsule refuses its OWN action
    // AND the slot it wraps: the nested slider must be dead too, or a host
    // that dims a whole reading still has a live control inside the dimmed
    // picture, and a person can change a value they were told is not there.
    function test_a_disabled_capsule_refuses_every_route_including_the_slot() {
        sound.enabled = false;
        compare(sound.acceptsInput, false, "a disabled capsule still claims to accept input");
        compare(level.enabled, false, "the slot stayed enabled inside a disabled capsule");

        mouseMove(level, level.width / 2, level.height / 2);
        mouseWheel(level, level.width / 2, level.height / 2, 0, 120);
        wait(60);
        compare(probe.reading, 42, "the wheel still moved the reading of a disabled capsule");

        mouseClick(level, level.width * 0.8, level.height * 0.8);
        compare(probe.reading, 42, "a press in the slot still moved the reading of a disabled capsule");

        const label = findChild(level, "sliderLabel");
        verify(label !== null, "the slider lost its label objectName");
        mouseClick(label, label.width / 2, label.height / 2);
        compare(probe.muted, 0, "the slot label still muted inside a disabled capsule");

        verify(!sound.activate(), "a disabled capsule still activated programmatically");
        mouseClick(sound, sound.padding + 2, 2);
        compare(probe.soundOpened, 0, "a disabled capsule still opened from a pointer");

        // Re-enabling restores every route: the refusals above were the state,
        // not a slot that had died with it.
        sound.enabled = true;
        tryCompare(level, "enabled", true);
        mouseWheel(level, level.width / 2, level.height / 2, 0, 120);
        wait(60);
        compare(probe.reading, 47, "the wheel did not come back with the enabled capsule");
    }

    // Report-only is the state that is NOT unavailable, and it is the one a
    // wrapper gets wrong: it is "this is a reading, not a button", so the BODY
    // stops being an action while everything inside the slot keeps being one.
    // Dimming the whole thing, or letting the body through, are both wrong and
    // neither throws.
    function test_report_only_keeps_the_body_dead_and_the_slot_alive() {
        sound.interactive = false;
        compare(sound.acceptsInput, true, "report-only took the capsule's input with it");
        verify(!sound.activate(), "a report-only capsule still activated");
        compare(sound.actions[0].enabled, false, "a report-only capsule still offers its body action");
        verify(level.enabled, "report-only disabled the slot as well");

        mouseClick(sound, sound.padding + 2, 2);
        compare(probe.soundOpened, 0, "a report-only capsule opened from a pointer on its body");

        // The slot is untouched: the wheel, and the label's own action.
        mouseMove(level, level.width / 2, level.height / 2);
        mouseWheel(level, level.width / 2, level.height / 2, 0, 120);
        wait(60);
        compare(probe.reading, 47, "report-only stopped the slot slider from answering the wheel");

        const label = findChild(level, "sliderLabel");
        mouseClick(label, label.width / 2, label.height / 2);
        compare(probe.muted, 1, "report-only stopped the slot label's own action");
        compare(probe.reading, 0, "the mute did not reach the host's reading");
        compare(probe.soundOpened, 0, "the slot action also opened the report-only capsule");

        sound.interactive = true;
        verify(sound.actions[0].enabled, "the body action did not come back with interactive");
        mouseClick(sound, sound.padding + 2, 2);
        compare(probe.soundOpened, 1, "the body did not open the capsule again");
    }

    // Hiding is the host's own withdrawal, and it is the one cancellation the
    // component owes on its own: a pending timeout that survives the hide would
    // ask the host to dismiss a capsule the host has already put away, and the
    // intent would arrive later than anything the host could still act on.
    // A real Timer and real waits, because this is the one claim a document
    // step cannot make: it needs the wall clock to pass with nothing showing.
    function test_hiding_during_a_pending_timeout_cancels_the_later_intent() {
        sound.timeout = 150;
        tryCompare(sound, "_armed", true, 500, "a timed presentation never armed");

        sound.shown = false;
        compare(sound._armed, false, "hiding left the timeout armed");
        compare(sound.acceptsInput, false, "a hidden capsule still claims to accept input");
        wait(400);
        compare(probe.soundExpired, 0,
            "a capsule the host had already hidden still asked to be dismissed later");

        // A fresh presentation is a fresh budget, and it does fire: the wait
        // above proved the intent was cancelled, not that it was never armed.
        // This host does NOT answer the request (see `sound`'s handler), so the
        // capsule must still be up: a component that withdrew its own
        // visibility would be mutating host state.
        sound.shown = true;
        tryCompare(probe, "soundExpired", 1, 1000, "the re-presented capsule never expired");
        verify(sound.shown, "the component withdrew its own visibility instead of asking");
    }

    // Hiding mid-fade and showing again must not leave two budgets running:
    // one presentation, one intent, however many times visibility was written
    // on the way there.
    function test_repeated_presentation_around_a_hide_asks_exactly_once() {
        sound.timeout = 150;
        for (let i = 0; i < 4; i++) {
            sound.shown = false;
            sound.shown = true;
        }
        tryCompare(probe, "soundExpired", 1, 1000, "the repeated presentation never expired");
        wait(300);
        compare(probe.soundExpired, 1,
            "four presentations produced " + probe.soundExpired + " dismissal intents");

        // Restarting a shown capsule refreshes the budget instead of adding one.
        sound.timeout = 0;
        sound.restart();
        compare(sound._armed, false, "restart armed a persistent capsule");
        sound.timeout = 150;
        tryCompare(sound, "_armed", true);
        sound.restart();
        wait(80);
        compare(probe.soundExpired, 1, "restart left the previous budget running");
        tryCompare(probe, "soundExpired", 2, 1000, "the restarted budget never expired");
    }

    function test_reduced_motion_fade_and_same_timeout_contract() {
        const original = Style.backend;
        try {
            Style.backend = reducedTheme;
            capsule.shown = false;
            tryCompare(capsule, "present", false);
            capsule.shown = true;
            tryCompare(capsule, "opacity", 1);
            capsule.timeout = 100;
            tryCompare(probe, "expired", 1);
            tryCompare(capsule, "present", false);
        } finally {
            Style.backend = original;
        }
    }
}
