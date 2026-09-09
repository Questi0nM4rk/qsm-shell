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

        Rectangle { anchors.fill: parent; color: Style.surfaceRaised }

        StateLayer {
            id: activeLayer
            anchors.fill: parent
            target: activeHost
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
            target: inactiveHost
            interactive: false
        }
    }
    SignalSpy { id: inactiveClicked; target: inactiveLayer; signalName: "clicked" }

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
            target: hostButton
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

        // visualFocus is keyboard focus only; a click never sets it. The
        // press/release above already gave hostButton active focus with
        // MouseFocusReason (StrongFocus includes ClickFocus), and Qt does
        // not re-fire a focus-in event for an item that already holds
        // active focus, so the reason would never update without first
        // moving focus away.
        probe.forceActiveFocus();
        hostButton.forceActiveFocus(Qt.TabFocusReason);
        tryCompare(hostedLayer, "focused", true, 500);
    }
}
