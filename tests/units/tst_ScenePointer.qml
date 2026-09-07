import QtQuick
import QtTest

import qs.QsmShell.Components

// The bug this encodes shipped once already: a rail popout stayed open with a
// `HoverHandler` reader declared as a SIBLING underneath the interactive
// surfaces it was meant to watch. Handlers on stacked sibling items shadow
// each other -- only the one nearest the pointer is told about it -- so the
// reader was blind at every pointer position and the popout never closed.
// Every case below drives a REAL pointer event; qmllint cannot see any of this.
TestCase {
    id: probe

    name: "ScenePointer"
    width: 400
    height: 400
    visible: true
    when: windowShown

    // ── row 1: declared on the ANCESTOR ─────────────────────────────────
    // The correct placement: the reader and a descendant handler at any depth
    // are told about the pointer independently, because neither shadows the
    // other.
    Item {
        id: ancestorScene
        x: 0; y: 0; width: 200; height: 200

        ScenePointer { id: ancestorPointer }

        MouseArea {
            id: childArea
            x: 50; y: 50; width: 100; height: 100
            hoverEnabled: true

            // A handler on a DESCENDANT of the ancestor, not a sibling of the
            // reader -- this is the case row 1 of the table actually claims.
            HoverHandler { id: childHover }
        }
    }

    // ── row 2: declared as a SIBLING below an interactive surface ───────
    // This is the exact shape of the shipped bug. Kept here so nobody
    // reintroduces the placement by accident: this test FAILS the moment
    // `blindScene`'s pointer stops being blind, which is the signal that the
    // shadowing this type exists to avoid has silently gone away.
    Item {
        id: blindScene
        x: 200; y: 0; width: 200; height: 200

        Item {
            id: blindReaderHost
            anchors.fill: parent
            ScenePointer { id: blindPointer }
        }

        MouseArea {
            id: blindSurface
            anchors.fill: parent
            hoverEnabled: true
        }
    }

    // ── row 3: the pointer leaving the scene ────────────────────────────
    Item {
        id: leaveScene
        x: 0; y: 200; width: 200; height: 100

        ScenePointer { id: leavePointer }

        readonly property rect target: Qt.rect(50, 20, 60, 60)
    }

    function test_ancestor_placement_reports_position_and_keeps_descendant_hover() {
        mouseMove(childArea, 50, 50);

        compare(ancestorPointer.inside, true, "ScenePointer on the ancestor did not see the pointer");
        compare(childHover.hovered, true, "a descendant HoverHandler under the pointer lost its own hover");
        compare(childArea.containsMouse, true, "a MouseArea under the pointer lost containsMouse");
        compare(Math.round(ancestorPointer.position.x), 100, "position.x was not reported in the ancestor's own coordinates");
        compare(Math.round(ancestorPointer.position.y), 100, "position.y was not reported in the ancestor's own coordinates");
    }

    function test_sibling_below_a_surface_is_blind() {
        mouseMove(blindSurface, 100, 100);

        // This is the assertion that IS the bug report: a reader declared as
        // a sibling underneath the surface it watches never sees the pointer,
        // no matter where the pointer goes.
        compare(blindPointer.inside, false, "a ScenePointer declared as a sibling below a surface saw the pointer -- it should be shadowed");
    }

    function test_contains_forgets_a_stale_position_once_the_pointer_leaves() {
        mouseMove(leaveScene, 80, 50);
        compare(leavePointer.contains(leaveScene.target), true, "ScenePointer did not report the pointer inside the target rect");

        // Move well clear of leaveScene's bounds without leaving the window,
        // so `position` is left holding its last real value -- exactly the
        // ghost this method exists to guard against.
        mouseMove(probe, 350, 350);
        compare(leavePointer.inside, false, "ScenePointer still reports inside after the pointer left its scene");
        compare(leavePointer.contains(leaveScene.target), false, "contains() used the stale ghost position instead of noticing the pointer left");
    }
}
