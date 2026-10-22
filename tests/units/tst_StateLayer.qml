import QtQuick
import QtQuick.Templates as T
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style

TestCase {
    id: probe

    name: "StateLayer"
    width: 360
    height: 260
    visible: true
    when: windowShown

    function cleanup() {
        Interaction.pointerSelects = true;
        activeHost.focus = false;
        hostButton.focus = false;
    }

    Item {
        id: activeHost
        x: 20; y: 20; width: 280; height: 64
        focus: false

        Rectangle { anchors.fill: parent; color: Style.overlay }

        StateLayer {
            id: activeLayer
            anchors.fill: parent
        }
    }
    SignalSpy { id: activeClicked; target: activeLayer; signalName: "clicked" }
    SignalSpy { id: activeHovered; target: activeLayer; signalName: "hoveredEntered" }

    Item {
        id: inactiveHost
        x: 20; y: 120; width: 280; height: 64

        StateLayer {
            id: inactiveLayer
            anchors.fill: parent
            interactive: false
        }
    }
    SignalSpy { id: inactiveClicked; target: inactiveLayer; signalName: "clicked" }

    Item {
        id: hoverOnlyHost
        x: 160; y: 200; width: 120; height: 32

        StateLayer {
            id: hoverOnlyLayer
            anchors.fill: parent
            clickable: false
        }
    }
    SignalSpy { id: hoverOnlyClicked; target: hoverOnlyLayer; signalName: "clicked" }

    function test_active_layer_reports_real_hover_press_and_click() {
        mouseMove(probe, 340, 220);
        activeClicked.clear();
        activeHovered.clear();

        mouseMove(activeHost, 80, 32);
        compare(activeLayer.hovered, true, "active layer did not report real pointer hover");
        compare(activeHovered.count, 1, "active layer did not report its hover-enter response");
        tryCompare(activeLayer, "response", activeLayer.hoverScale, 500);

        mousePress(activeHost, 80, 32);
        tryCompare(activeLayer, "pressed", true, 500);
        tryCompare(activeLayer, "response", activeLayer.pressScale, 500);
        mouseRelease(activeHost, 80, 32);
        tryCompare(activeLayer, "pressed", false, 500);
        tryCompare(activeLayer, "response", activeLayer.hoverScale, 500);
        compare(activeClicked.count, 1, "active layer did not report a real click");

        mouseMove(probe, 340, 220);
        tryCompare(activeLayer, "hovered", false, 500);
        tryCompare(activeLayer, "response", 1, 500);
    }

    function test_programmatic_activation_uses_the_real_intent_guard() {
        activeClicked.clear()
        verify(activeLayer.activate())
        compare(activeClicked.count, 1)
        activeLayer.clickable = false
        verify(!activeLayer.activate())
        compare(activeClicked.count, 1)
        activeLayer.clickable = true
        activeHost.enabled = false
        activeLayer.manualHoverOverride = true
        activeLayer.manualPressOverride = true
        verify(!activeLayer.hovered)
        verify(!activeLayer.pressed)
        verify(!activeLayer.activate())
        compare(activeClicked.count, 1)
        activeLayer.manualHoverOverride = false
        activeLayer.manualPressOverride = false
        activeHost.enabled = true
        verify(!inactiveLayer.activate())
        verify(!hostedLayer.activate())
    }

    function test_inactive_layer_ignores_real_pointer_interaction() {
        mouseMove(probe, 340, 220);
        inactiveClicked.clear();

        mouseMove(inactiveHost, 80, 32);
        compare(inactiveLayer.hovered, false, "inactive layer claimed hover under a real pointer move");
        mousePress(inactiveHost, 80, 32);
        compare(inactiveLayer.pressed, false, "inactive layer claimed a real press");
        mouseRelease(inactiveHost, 80, 32);
        compare(inactiveClicked.count, 0, "inactive layer fired clicked from a real pointer click");
    }

    function test_pointer_selection_gate_suppresses_only_hover_claim() {
        mouseMove(probe, 340, 220);
        activeHovered.clear();
        Interaction.pointerSelects = false;

        mouseMove(activeHost, 80, 32);
        compare(activeLayer.hovered, true, "pointer selection gate hid the raw hover fact");
        compare(activeHovered.count, 0, "pointer selection gate did not suppress hover claim");
    }

    function test_visual_overrides_never_fabricate_intent_and_real_entry_still_reports() {
        mouseMove(probe, 340, 220)
        activeClicked.clear()
        activeHovered.clear()
        activeLayer.manualHoverOverride = true
        activeLayer.manualPressOverride = true
        compare(activeLayer.hovered, true)
        compare(activeLayer.pressed, true)
        compare(activeClicked.count, 0)
        compare(activeHovered.count, 0)
        mouseMove(activeHost, 80, 32)
        compare(activeHovered.count, 1)
        mousePress(activeHost, 80, 32)
        compare(activeClicked.count, 0)
        mouseRelease(activeHost, 80, 32)
        activeLayer.interactive = false
        compare(activeLayer.hovered, false)
        compare(activeLayer.pressed, false)
        activeLayer.interactive = true
        activeLayer.manualHoverOverride = false
        activeLayer.manualPressOverride = false
    }

    function test_hover_only_layer_reports_hover_without_a_tap_action() {
        mouseMove(probe, 340, 220);
        hoverOnlyClicked.clear();

        mouseMove(hoverOnlyHost, 60, 16);
        compare(hoverOnlyLayer.hovered, true, "hover-only layer did not report hover");
        mousePress(hoverOnlyHost, 60, 16);
        compare(hoverOnlyLayer.pressed, false, "hover-only layer reported a press");
        mouseRelease(hoverOnlyHost, 60, 16);
        compare(hoverOnlyClicked.count, 0, "hover-only layer emitted clicked");
    }

    function test_host_focus_is_exposed_as_focused() {
        activeHost.forceActiveFocus();
        compare(activeLayer.focused, true, "host focus did not propagate to StateLayer.focused");
    }

    T.AbstractButton {
        id: hostButton
        x: 20; y: 200; width: 120; height: 32
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus

        StateLayer {
            id: hostedLayer
            anchors.fill: parent
            host: hostButton
        }
    }

    function test_host_mode_reads_the_template_states() {
        mouseMove(probe, 340, 220);
        tryCompare(hostedLayer, "hovered", false, 500);

        mouseMove(hostButton, 60, 16);
        tryCompare(hostedLayer, "hovered", true, 500);
        mousePress(hostButton, 60, 16);
        tryCompare(hostedLayer, "pressed", true, 500);
        mouseRelease(hostButton, 60, 16);
        tryCompare(hostedLayer, "pressed", false, 500);

        hostButton.enabled = false;
        compare(hostedLayer.interactive, false, "a disabled host still had an answering layer");
        hostButton.enabled = true;

        // The press above gave hostButton active focus (StrongFocus includes
        // ClickFocus) and no ring: the ring is for keyboard focus only.
        compare(hostedLayer.focused, false);
        probe.forceActiveFocus();
        hostButton.forceActiveFocus(Qt.TabFocusReason);
        tryCompare(hostedLayer, "focused", true, 500);
        probe.forceActiveFocus();
        tryCompare(hostedLayer, "focused", false, 500);
    }
}
