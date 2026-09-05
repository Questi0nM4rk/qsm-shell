import QtQuick
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style

// The two surfaces whose contracts are invisible until something drives them.
//
// Every assertion here is a bug that shipped. `Popover` had no size at all
// (its content host filled the popover and the popover sized from the host,
// which is zero forever) and did not follow an anchor whose ANCESTOR moved.
// `Dialog` focused its own card rather than the first control inside it, so
// the keyboard landed on a plain surface and the first Tab went somewhere
// arbitrary. A linter sees none of these.
TestCase {
    id: probe

    name: "Surfaces"
    width: 500
    height: 400
    visible: true
    when: windowShown

    // ── popover ─────────────────────────────────────────────────────────
    Item {
        id: stage

        width: 300
        height: 200

        // The anchor lives inside a mover, so its own x never changes while
        // its position on screen does — the exact case a binding on
        // `anchorItem.x` cannot see.
        Item {
            id: mover
            x: 0
            y: 60

            Rectangle { id: anchor; x: 15; width: 40; height: 20 }
        }

        Popover {
            id: popover
            anchorItem: anchor
            placement: "bottom"
            alignment: "start"
            open: true

            Card { width: 120; height: 80 }
        }

        Rectangle { id: topAnchor; x: 20; y: 4; width: 40; height: 20 }

        // A viewport too short for the panel on either side of the anchor.
        Item {
            id: cramped
            y: 120
            width: 200
            height: 70

            Rectangle { id: midAnchor; x: 10; y: 25; width: 30; height: 20 }

            Popover {
                id: boxed
                anchorItem: midAnchor
                bounds: cramped
                placement: "top"

                Card { width: 60; height: 50 }
            }
        }

        Popover {
            id: asker
            anchorItem: topAnchor
            trigger: "hover"

            Card { width: 40; height: 30 }
        }

        Popover {
            id: squeezed
            anchorItem: topAnchor
            placement: "top"

            Card { width: 80; height: 60 }
        }
    }

    // ── dialog ──────────────────────────────────────────────────────────
    property int confirmed: 0

    Item {
        id: dialogStage

        width: 400
        height: 300

        Capsule { id: opener; label: "Open"; icon: "sparkle" }

        Dialog {
            id: dialog
            title: "Discard changes?"
            body: "The draft has not been saved."
            tone: "danger"
            returnFocusTo: opener

            Capsule {
                id: confirm
                objectName: "confirm"
                label: "Discard"
                variant: "destructive"
                activeFocusOnTab: true
                onClicked: probe.confirmed++
            }
            Capsule {
                id: cancel
                objectName: "cancel"
                label: "Keep"
                activeFocusOnTab: true
            }
        }
    }

    // A popover with no size is a popover that renders nothing, and nothing
    // about the code says so — it just quietly is not there.
    function test_popover_takes_its_size_from_its_content() {
        verify(popover.width > 0 && popover.height > 0, "the popover had no size");
        compare(popover.width, 120, "the popover did not take its content's width");
        compare(popover.height, 80, "the popover did not take its content's height");
    }

    // An item's scene position changes whenever an ANCESTOR moves, and Qt
    // Quick emits no signal for it. A popover bound to `anchorItem.x` stays
    // where the row used to be.
    function test_popover_follows_an_anchor_whose_ancestor_moved() {
        mover.x = 0;
        popover.resample();
        const before = popover.x;
        mover.x = 100;
        popover.resample();
        compare(popover.x, before + 100, "the popover did not follow its anchor's ancestor");
        mover.x = 0;
        popover.resample();
    }

    // An anchored panel that is right in the middle of a surface and wrong at
    // its edge is wrong.
    function test_popover_flips_when_it_does_not_fit() {
        squeezed.resampleBounds();
        squeezed.resample();
        compare(squeezed.side, "bottom", "a popover with no room above did not flip below");
    }

    // Flipping BLIND is how a panel with too little room on both sides lands
    // off the far edge instead of the near one. With no room either way it has
    // to pick the larger side and then clamp into the bounds.
    function test_popover_with_no_room_either_way_stays_inside() {
        boxed.resampleBounds();
        boxed.resample();
        verify(boxed.y >= 0, "a popover with no room either way went off the top");
        verify(boxed.y + boxed.height <= cramped.height + 0.01,
            "a popover with no room either way went off the bottom");
    }

    // The popover REQUESTS; the surface decides. A component that opens itself
    // has to be told about every surface it might sit in.
    function test_popover_asks_rather_than_opening_itself() {
        compare(asker.open, false, "the popover opened without being told to");
        asker.openRequested();
        compare(asker.open, false, "the popover opened itself on its own request");
    }

    // The modal contract, and half of it is worse than none because a
    // half-modal looks finished: focus goes IN on open, and back OUT to
    // whatever opened it on close.
    function test_dialog_focus_enters_a_control_and_returns() {
        opener.forceActiveFocus();
        dialog.open = true;
        // Focus entry is deferred one turn on purpose (the visibility binding
        // has to land first), so the check waits for it rather than racing it.
        tryVerify(() => confirm.activeFocus || cancel.activeFocus, 500);
        verify(confirm.activeFocus || cancel.activeFocus,
            "focus did not land on a control inside the dialog");

        dialog.open = false;
        tryVerify(() => opener.activeFocus, 500);
        verify(opener.activeFocus, "focus did not return to the opener");
    }

    // A closed dialog must not be reachable at all — a modal that is invisible
    // but still in the tab order is a set of controls nobody can see.
    function test_a_closed_dialog_is_not_reachable() {
        dialog.open = false;
        wait(1);
        verify(!dialog.enabled, "a closed dialog stayed enabled");
    }
}
