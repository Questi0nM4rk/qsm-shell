import QtQuick
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style

// One keep-open rule for every rollout. A rollout stays open while the
// pointer sits inside its hover area, plus a grace period after it leaves.
// Every case below drives a REAL pointer event and a REAL Timer -- qmllint
// cannot see any of this.
TestCase {
    id: probe

    name: "Rollout"
    width: 400
    height: 600
    visible: true
    when: windowShown

    // Reduced motion shortens reveal/retract so each row's Rollout settles
    // `visible` fast. `closeDelay` is set explicitly per-row below instead of
    // relying on Motion's token, so the delay assertions run fast and stay
    // independent of Motion.hoverGrace's actual value.
    QtObject {
        id: fastBackend
        property bool reducedMotion: true
    }

    Component.onCompleted: Style.backend = fastBackend

    // ── row A: one hover area — the close-delay half of the rule ────────
    Item {
        id: sceneA
        x: 0; y: 0; width: 200; height: 200

        ScenePointer { id: pointerA }

        QtObject {
            id: hostA
            property bool fullscreen: false
            property var pointer: pointerA
            function registerBulge() {}
            function unregisterBulge() {}
            function registerRolloutRegion() {}
            function unregisterRolloutRegion() {}
            function registerFullscreenCapsule() {}
            function unregisterFullscreenCapsule() {}
        }

        Rollout {
            id: rolloutA
            host: hostA
            rolloutId: "row-a"
            edges: ["top"]
            tier: "small"
            shouldBeActive: true
            closeDelay: 60
            hoverAreas: [Qt.rect(20, 20, 60, 60)]

            Rectangle { width: 100; height: 60 }
        }
    }

    // ── row B: two hover areas with a gap — the dead-zone ────────────────
    Item {
        id: sceneB
        x: 200; y: 0; width: 200; height: 200

        ScenePointer { id: pointerB }

        QtObject {
            id: hostB
            property bool fullscreen: false
            property var pointer: pointerB
            function registerBulge() {}
            function unregisterBulge() {}
            function registerRolloutRegion() {}
            function unregisterRolloutRegion() {}
            function registerFullscreenCapsule() {}
            function unregisterFullscreenCapsule() {}
        }

        Rollout {
            id: rolloutB
            host: hostB
            rolloutId: "row-b"
            edges: ["top"]
            tier: "small"
            shouldBeActive: true
            closeDelay: 60
            hoverAreas: [Qt.rect(10, 10, 40, 40), Qt.rect(150, 10, 40, 40)]

            Rectangle { width: 60; height: 60 }
        }
    }

    // ── row C: no pointer assigned to the host ──────────────────────────
    Item {
        id: sceneC
        x: 0; y: 200; width: 200; height: 200

        // A real pointer exists in the scene -- it is simply never handed
        // to the host, which is exactly the "nothing assigned" case.
        ScenePointer { id: pointerC }

        QtObject {
            id: hostC
            property bool fullscreen: false
            property var pointer: null
            function registerBulge() {}
            function unregisterBulge() {}
            function registerRolloutRegion() {}
            function unregisterRolloutRegion() {}
            function registerFullscreenCapsule() {}
            function unregisterFullscreenCapsule() {}
        }

        Rollout {
            id: rolloutC
            host: hostC
            rolloutId: "row-c"
            edges: ["top"]
            tier: "small"
            shouldBeActive: true
            closeDelay: 60

            Rectangle { width: 100; height: 60 }
        }
    }

    // ── row D: empty hoverAreas — the rollout's own silhouette ──────────
    Item {
        id: sceneD
        x: 200; y: 200; width: 200; height: 200

        ScenePointer { id: pointerD }

        QtObject {
            id: hostD
            property bool fullscreen: false
            property var pointer: pointerD
            function registerBulge() {}
            function unregisterBulge() {}
            function registerRolloutRegion() {}
            function unregisterRolloutRegion() {}
            function registerFullscreenCapsule() {}
            function unregisterFullscreenCapsule() {}
        }

        Rollout {
            id: rolloutD
            host: hostD
            rolloutId: "row-d"
            edges: ["top"]
            tier: "small"
            shouldBeActive: true
            closeDelay: 60
            // hoverAreas left at its [] default deliberately.

            Rectangle { width: 100; height: 60 }
        }
    }

    function test_pointer_inside_hover_area_reports_hovered_and_keepOpen() {
        tryVerify(() => rolloutA.offsetScale <= 0.001, 1000, "rolloutA never settled open");

        mouseMove(sceneA, 50, 50);
        compare(rolloutA.hovered, true, "hovered did not become true with the pointer inside its hover area");
        compare(rolloutA.keepOpen, true, "keepOpen did not become true with the pointer inside its hover area");
    }

    // The entire reason for the hovered/keepOpen split: `hovered` must drop
    // the INSTANT the pointer leaves (no delay of any kind), while
    // `keepOpen` stays true until the close delay elapses. A `hovered` that
    // lingered would be a name that lies about what it reports.
    function test_pointer_leaving_drops_hovered_immediately_but_keepOpen_waits_for_the_delay() {
        tryVerify(() => rolloutA.offsetScale <= 0.001, 1000, "rolloutA never settled open");

        mouseMove(sceneA, 50, 50);
        compare(rolloutA.hovered, true, "hovered did not become true with the pointer inside its hover area");

        mouseMove(sceneA, 190, 190);
        compare(rolloutA.hovered, false, "hovered did not drop the instant the pointer left the hover area");
        // The half a component with NO delay would already fail: keepOpen
        // must still read true the instant the pointer leaves.
        compare(rolloutA.keepOpen, true, "keepOpen dropped the instant the pointer left -- there is no close delay at all");

        tryVerify(() => rolloutA.keepOpen === false, 1000,
            "keepOpen never went false once rolloutA's close delay elapsed");
    }

    function test_moving_between_two_hover_areas_never_drops_keepOpen() {
        tryVerify(() => rolloutB.offsetScale <= 0.001, 1000, "rolloutB never settled open");

        mouseMove(sceneB, 30, 30);
        compare(rolloutB.keepOpen, true, "keepOpen did not become true inside the first hover area");

        // Straight to the second area -- the pointer is never observed
        // outside either rect, which is the dead-zone this mechanism exists
        // to close.
        mouseMove(sceneB, 170, 30);
        compare(rolloutB.keepOpen, true, "keepOpen dropped moving from one hover area straight into the other");
    }

    function test_no_pointer_on_the_host_reports_keepOpen_false() {
        tryVerify(() => rolloutC.offsetScale <= 0.001, 1000, "rolloutC never settled open");

        mouseMove(sceneC, 50, 30);
        compare(rolloutC.hovered, false, "hovered was true with no pointer assigned to the host");
        compare(rolloutC.keepOpen, false, "keepOpen was true with no pointer assigned to the host");
    }

    function test_empty_hover_areas_falls_back_to_the_rollouts_own_silhouette() {
        tryVerify(() => rolloutD.offsetScale <= 0.001, 1000, "rolloutD never settled open");

        // (50, 30) sits inside rolloutD's own rect (100x60 at its default
        // 0,0) and nowhere the consumer named explicitly.
        mouseMove(sceneD, 50, 30);
        compare(rolloutD.keepOpen, true, "keepOpen was false inside the rollout's own silhouette with no hoverAreas set");
    }

    // ── row E: trigger area separate from the hover area -- the nub, then
    // the body ──────────────────────────────────────────────────────────
    Item {
        id: sceneE
        x: 0; y: 400; width: 200; height: 200

        ScenePointer { id: pointerE }

        QtObject {
            id: hostE
            property bool fullscreen: false
            property var pointer: pointerE
            function registerBulge() {}
            function unregisterBulge() {}
            function registerRolloutRegion() {}
            function unregisterRolloutRegion() {}
            function registerFullscreenCapsule() {}
            function unregisterFullscreenCapsule() {}
        }

        Rollout {
            id: rolloutE
            host: hostE
            rolloutId: "row-e"
            edges: ["top"]
            tier: "small"
            // Starts CLOSED -- the trigger must be reachable before anything
            // is showing, unlike a hover area.
            shouldBeActive: false
            closeDelay: 60
            triggerAreas: [Qt.rect(10, 10, 30, 30)]
            hoverAreas: [Qt.rect(150, 150, 40, 40)]

            Rectangle { width: 100; height: 60 }
        }
    }

    function test_pointer_in_trigger_area_reports_triggered_and_wantsOpen() {
        // rolloutE starts closed: the trigger must fire before the body
        // ever shows.
        compare(rolloutE.visible, false, "rolloutE was already visible before any trigger");

        mouseMove(sceneE, 20, 20);
        compare(rolloutE.triggered, true, "triggered did not become true with the pointer inside triggerAreas");
        compare(rolloutE.wantsOpen, true, "wantsOpen did not become true with the pointer inside triggerAreas");
    }

    // The OSD's whole journey: pointer finds the nub (triggerAreas), the
    // surface opens the rollout, the pointer sweeps on into the revealed
    // body (hoverAreas). wantsOpen must never drop across that whole trip,
    // even though `triggered` and `keepOpen` individually hand off the job.
    function test_pointer_moving_from_trigger_area_into_hover_area_never_drops_wantsOpen() {
        mouseMove(sceneE, 20, 20);
        compare(rolloutE.triggered, true, "triggered did not become true over the trigger area");
        compare(rolloutE.wantsOpen, true, "wantsOpen did not become true over the trigger area");

        // The surface reacts to the trigger by opening the rollout -- this
        // component never does that itself.
        rolloutE.shouldBeActive = true;
        tryVerify(() => rolloutE.offsetScale <= 0.001, 1000, "rolloutE never settled open");

        mouseMove(sceneE, 170, 170);
        compare(rolloutE.triggered, false, "triggered stayed true once the pointer left triggerAreas");
        compare(rolloutE.hovered, true, "hovered did not become true over hoverAreas");
        compare(rolloutE.wantsOpen, true, "wantsOpen dropped moving from the trigger area into the hover area");

        rolloutE.shouldBeActive = false;
    }

    function test_pointer_leaving_everything_drops_triggered_at_once_wantsOpen_after_the_delay() {
        rolloutE.shouldBeActive = true;
        tryVerify(() => rolloutE.offsetScale <= 0.001, 1000, "rolloutE never settled open");

        mouseMove(sceneE, 20, 20);
        compare(rolloutE.triggered, true, "triggered did not become true over the trigger area");

        mouseMove(sceneE, 100, 100);
        compare(rolloutE.triggered, false, "triggered did not drop the instant the pointer left every area");
        // The half a component with no delay would already fail here:
        // wantsOpen must still read true the instant the pointer leaves.
        compare(rolloutE.wantsOpen, true, "wantsOpen dropped the instant the pointer left -- there is no close delay at all");

        tryVerify(() => rolloutE.wantsOpen === false, 1000,
            "wantsOpen never went false once rolloutE's close delay elapsed");

        rolloutE.shouldBeActive = false;
    }

    function test_empty_trigger_areas_leaves_triggered_false_and_wantsOpen_following_keepOpen() {
        // rolloutD has no triggerAreas set (left at its [] default) and is
        // already open with hoverAreas falling back to its own silhouette.
        tryVerify(() => rolloutD.offsetScale <= 0.001, 1000, "rolloutD never settled open");

        mouseMove(sceneD, 50, 30);
        compare(rolloutD.triggered, false, "triggered was true with an empty triggerAreas");
        compare(rolloutD.wantsOpen, rolloutD.keepOpen,
            "wantsOpen diverged from keepOpen with an empty triggerAreas -- existing behaviour must be unchanged");
        compare(rolloutD.wantsOpen, true, "wantsOpen did not follow keepOpen being true");

        mouseMove(sceneD, 190, 190);
        tryVerify(() => rolloutD.keepOpen === false, 1000, "rolloutD's keepOpen never settled false");
        compare(rolloutD.wantsOpen, rolloutD.keepOpen,
            "wantsOpen diverged from keepOpen with an empty triggerAreas -- existing behaviour must be unchanged");
    }

    // The decision this task asks for: a triggerAreas rect ALSO counts as a
    // hoverAreas rect once the rollout is open, so a consumer never has to
    // repeat the nub rect in both lists to keep the OSD open while the
    // pointer rests back on the nub.
    function test_trigger_area_counts_as_hover_area_once_open() {
        rolloutE.shouldBeActive = true;
        tryVerify(() => rolloutE.offsetScale <= 0.001, 1000, "rolloutE never settled open");

        mouseMove(sceneE, 20, 20);
        compare(rolloutE.hovered, true, "hovered was false over triggerAreas once open -- the nub rect must count as a hover area too");
        compare(rolloutE.keepOpen, true, "keepOpen was false over triggerAreas once open");

        rolloutE.shouldBeActive = false;
    }
}
