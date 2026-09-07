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
    height: 400
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
}
