import QtQuick
import QtTest

import qs.QsmShell.Components

// ShellBorder never names Wayland, a monitor, or a focus mode (the design's
// boundary decision) — so it cannot decide on its own which still-registered
// entry a fullscreen/focus-mode consumer has already ruled out. `entryFilter`
// is that consumer hook (11c gap): a predicate over a registry id, run before
// any of the three registries reach the shader or the mask. Absent (null)
// shows everything registered, which is the whole point of the default —
// nothing changes for a consumer that never sets it.
TestCase {
    id: probe

    name: "ShellBorderEntryFilter"

    ShellBorder {
        id: border
        width: 300
        height: 200
    }

    function init() {
        border.entryFilter = null;
        border.unregisterBulge("kept");
        border.unregisterBulge("hidden");
        border.unregisterRolloutRegion("kept");
        border.unregisterRolloutRegion("hidden");
        border.unregisterFullscreenCapsule("kept");
        border.unregisterFullscreenCapsule("hidden");
    }

    function test_null_filter_shows_everything_registered() {
        border.registerBulge("kept", Qt.rect(0, 0, 10, 10), Qt.vector4d(0, 0, 0, 0),
            1, Qt.vector4d(1, 0, 0, 1), 1, 0, 0, true, 1);
        border.registerBulge("hidden", Qt.rect(0, 0, 10, 10), Qt.vector4d(0, 0, 0, 0),
            1, Qt.vector4d(1, 0, 0, 1), 1, 0, 0, true, 1);

        compare(border.bulgeEntries.length, 2,
            "a null filter must be the pre-hook behaviour: nothing hidden");
    }

    function test_filter_hides_an_id_from_bulge_and_mask_but_not_the_raw_registry() {
        border.entryFilter = id => id !== "hidden";
        border.registerBulge("kept", Qt.rect(0, 0, 10, 10), Qt.vector4d(0, 0, 0, 0),
            1, Qt.vector4d(1, 0, 0, 1), 1, 0, 0, true, 1);
        border.registerBulge("hidden", Qt.rect(0, 0, 10, 10), Qt.vector4d(0, 0, 0, 0),
            1, Qt.vector4d(1, 0, 0, 1), 1, 0, 0, true, 1);
        border.registerRolloutRegion("kept", Qt.rect(0, 0, 10, 10));
        border.registerRolloutRegion("hidden", Qt.rect(0, 0, 10, 10));

        compare(border.bulgeEntries.length, 1, "the filtered id must not reach the shader's entries");
        compare(border.maskRects.length, 1, "the filtered id must not reach the mask rects");
        compare(Object.keys(border.bulgeRegions).length, 2,
            "the raw registry keeps the filtered-out id — only the derived views hide it");
        compare(Object.keys(border.rolloutRegions).length, 2);
    }

    function test_filter_hides_a_fullscreen_capsule_from_the_painted_set() {
        border.entryFilter = id => id !== "hidden";
        border.registerFullscreenCapsule("kept", Qt.rect(0, 0, 10, 10), 4);
        border.registerFullscreenCapsule("hidden", Qt.rect(0, 0, 10, 10), 4);

        compare(border.fullscreenCapsuleEntries.length, 1);
        compare(Object.keys(border.fullscreenCapsules).length, 2,
            "the raw capsule registry keeps the filtered-out id");
    }
}
