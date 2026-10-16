import QtQuick
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style

// The ladder, measured: a body's answers to its states are rungs above its
// own base, selection is the accent's identity, and disabled stays opaque.
TestCase {
    id: probe

    name: "Surface"
    width: 200
    height: 100
    visible: true
    when: windowShown

    Surface { id: body; width: 100; height: 40 }

    function step(a, b) {
        return Style.contrast(a, Style.band) - Style.contrast(b, Style.band);
    }

    // The colour animates (Motion.micro), so every read waits for it to land.
    function settles(expected, message) {
        tryVerify(() => Qt.colorEqual(body.color, expected), 500, message);
    }

    function test_states_are_rungs_above_the_base() {
        settles(Style.surface, "a resting body is not its base");

        body.hovered = true;
        tryVerify(() => Math.abs(step(body.color, Style.surface) - 0.4) < 0.02, 500,
            "hover is not one step above the base");
        body.pressed = true;
        tryVerify(() => Math.abs(step(body.color, Style.surface) - 0.8) < 0.02, 500,
            "press is not two steps above the base");
        body.hovered = false;
        body.pressed = false;

        body.selected = true;
        settles(Style.selected(Style.surface, Style.accent), "selected is not the accent's identity over the base");
        compare(String(body.contentColor), String(Style.accent), "selected content is not accent");

        body.enabled = false;
        settles(Style.disabled(Style.selected(Style.surface, Style.accent)),
            "disabled did not dim the selected tone by colour");
        compare(body.color.a, 1, "a disabled body went translucent");
    }
}
