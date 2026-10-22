import QtQuick
import QtQuick.Window
import QtTest

import qs.QsmShell.Style

TestCase {
    id: testCase

    name: "InlineValueEditor"
    width: 800
    height: 760
    visible: true
    when: windowShown

    property int savedDecreaseKey
    property int savedIncreaseKey

    function initTestCase() {
        savedDecreaseKey = Interaction.sliderDecreaseKey
        savedIncreaseKey = Interaction.sliderIncreaseKey
        testCase.Window.window.width = testCase.width
        testCase.Window.window.height = testCase.height
    }

    Loader {
        id: unitLoader
        source: Qt.resolvedUrl("../../workbench/compositions/MenuInteractions.qml")
        onLoaded: {
            item.width = testCase.width
            item.height = testCase.height
        }
    }

    function unit() { return unitLoader.item }
    function target(name) { return unit().integration.targets[name]() }
    function focusTarget(name) { target(name).forceActiveFocus() }

    function init() {
        tryCompare(unitLoader, "status", Loader.Ready)
        Interaction.sliderDecreaseKey = savedDecreaseKey
        Interaction.sliderIncreaseKey = savedIncreaseKey
        unit().reset()
        focusTarget("row")
    }

    function cleanup() {
        Interaction.sliderDecreaseKey = savedDecreaseKey
        Interaction.sliderIncreaseKey = savedIncreaseKey
        unit().bindingOverride = false
        unit().reset()
        target("editor").decreaseKey = Qt.binding(function() {
            return unit().bindingOverride ? Qt.Key_H : Interaction.sliderDecreaseKey
        })
        target("editor").increaseKey = Qt.binding(function() {
            return unit().bindingOverride ? Qt.Key_L : Interaction.sliderIncreaseKey
        })
    }

    function test_repeated_activation_keeps_mute_identity_and_volume() {
        const initialVolume = unit().volume
        keyClick(Qt.Key_Down)
        compare(target("mute").activeFocus, true)
        keyClick(Qt.Key_Enter)
        compare(unit().muted, true)
        compare(unit().selectedId, "mute-output")
        compare(target("mute").activeFocus, true)
        compare(unit().volume, initialVolume)
        keyClick(Qt.Key_Enter)
        compare(unit().muted, false)
        compare(unit().selectedId, "mute-output")
        compare(target("mute").activeFocus, true)
        compare(unit().volume, initialVolume)
    }

    function test_enter_nudges_and_escape_reopen_preserves_value_and_identity() {
        focusTarget("row")
        keyClick(Qt.Key_Enter)
        tryCompare(unit(), "editorOpen", true)
        const slider = target("editor")
        tryVerify(() => unit().integration.observables["editor-focus"]())
        const start = unit().volume
        const commitCount = unit().commits
        keyClick(Qt.Key_N)
        keyClick(Qt.Key_O)
        fuzzyCompare(unit().volume, start, 0.0001)
        verify(unit().commits >= commitCount + 2)
        keyClick(Qt.Key_Escape)
        tryCompare(unit(), "editorOpen", false)
        fuzzyCompare(unit().volume, start, 0.0001)
        compare(unit().selectedId, "output-volume")
        compare(target("row").activeFocus, true)
        keyClick(Qt.Key_Enter)
        tryCompare(unit(), "editorOpen", true)
        tryVerify(() => unit().integration.observables["editor-focus"]())
        keyClick(Qt.Key_Return)
        tryCompare(unit(), "editorOpen", false)
        fuzzyCompare(unit().volume, start, 0.0001)
        compare(unit().selectedId, "output-volume")
        compare(target("row").activeFocus, true)
    }

    function test_instance_bindings_global_bindings_and_shortcut_guards() {
        focusTarget("row")
        Interaction.sliderDecreaseKey = Qt.Key_H
        Interaction.sliderIncreaseKey = Qt.Key_L
        unit().openEditor("output-volume")
        focusTarget("editor")
        const slider = target("editor")
        const start = unit().volume
        keyClick(Qt.Key_H)
        fuzzyCompare(unit().volume, start - Style.sliderKeyboardUnits * slider.stepSize, 0.0001)
        keyClick(Qt.Key_L)
        fuzzyCompare(unit().volume, start, 0.0001)

        unit().bindingOverride = true
        unit().closeEditor()
        focusTarget("row")
        keyClick(Qt.Key_Enter)
        tryVerify(() => unit().integration.observables["editor-focus"]())
        const overrideStart = unit().volume
        keyClick(Qt.Key_H)
        fuzzyCompare(unit().volume, overrideStart - Style.sliderKeyboardUnits * slider.stepSize, 0.0001)
        keyClick(Qt.Key_L)
        fuzzyCompare(unit().volume, overrideStart, 0.0001)

        slider.decreaseKey = Qt.Key_J
        slider.increaseKey = Qt.Key_K
        keyClick(Qt.Key_H)
        fuzzyCompare(unit().volume, overrideStart, 0.0001)
        keyClick(Qt.Key_J)
        fuzzyCompare(unit().volume, overrideStart - Style.sliderKeyboardUnits * slider.stepSize, 0.0001)
        keyClick(Qt.Key_K)
        fuzzyCompare(unit().volume, overrideStart, 0.0001)
        keyClick(Qt.Key_J, Qt.ControlModifier)
        keyClick(Qt.Key_J, Qt.AltModifier)
        keyClick(Qt.Key_J, Qt.MetaModifier)
        fuzzyCompare(unit().volume, overrideStart, 0.0001)

        slider.increaseKey = Qt.Key_J
        keyClick(Qt.Key_J)
        fuzzyCompare(unit().volume, overrideStart, 0.0001)
        slider.decreaseKey = 0
        slider.increaseKey = Qt.Key_K
        keyClick(Qt.Key_J)
        fuzzyCompare(unit().volume, overrideStart, 0.0001)
        keyClick(Qt.Key_K)
        fuzzyCompare(unit().volume, overrideStart + Style.sliderKeyboardUnits * slider.stepSize, 0.0001)
    }

    function test_tab_and_backtab_leave_the_editor_and_reach_real_targets() {
        focusTarget("row")
        keyClick(Qt.Key_Enter)
        tryVerify(() => unit().integration.observables["editor-focus"]())
        keyClick(Qt.Key_Tab)
        tryCompare(unit(), "editorOpen", false)
        compare(target("mute").activeFocus, true)
        compare(unit().selectedId, "mute-output")

        keyClick(Qt.Key_Up)
        keyClick(Qt.Key_Enter)
        tryVerify(() => unit().integration.observables["editor-focus"]())
        keyClick(Qt.Key_Backtab)
        tryCompare(unit(), "editorOpen", false)
        compare(unit().selectedId, "rescan")
        compare(target("row").activeFocus, true)
    }

    function test_search_types_binding_letters_without_opening_or_changing_level() {
        const input = target("search-input")
        const initialVolume = unit().volume
        const initialActivations = unit().activations
        input.forceActiveFocus()
        keyClick(Qt.Key_N)
        keyClick(Qt.Key_O)
        compare(unit().query.toLowerCase(), "no")
        compare(unit().volume, initialVolume)
        compare(unit().editorOpen, false)
        keyClick(Qt.Key_Enter)
        compare(unit().volume, initialVolume)
        compare(unit().editorOpen, false)
        compare(unit().activations, initialActivations)
        verify(unit().integration.observables["search-focus"]())
        keyClick(Qt.Key_Backspace)
        keyClick(Qt.Key_Backspace)
        compare(unit().query, "")
        keyClick(Qt.Key_Down)
        compare(unit().selectedId, "output-volume")
        compare(target("row").activeFocus, true)
    }

    function test_bounds_disabled_closed_input_and_truthful_actions() {
        unit().volume = 0
        focusTarget("row")
        keyClick(Qt.Key_Enter)
        tryVerify(() => unit().integration.observables["editor-focus"]())
        const slider = target("editor")
        keyClick(Qt.Key_N)
        compare(unit().volume, 0)
        keyClick(Qt.Key_Escape)
        unit().volume = 1
        focusTarget("row")
        keyClick(Qt.Key_Enter)
        tryVerify(() => unit().integration.observables["editor-focus"]())
        keyClick(Qt.Key_O)
        compare(unit().volume, 1)
        keyClick(Qt.Key_Escape)

        unit().disabled = true
        focusTarget("browse")
        const unchanged = unit().volume
        keyClick(Qt.Key_Enter)
        keyClick(Qt.Key_N)
        compare(unit().editorOpen, false)
        compare(unit().volume, unchanged)
        compare(unit().integration.runAction("activate"), false)
        compare(unit().integration.runAction("increase"), false)
        compare(unit().integration.runAction("toggle-mute"), false)
        compare(unit().volume, unchanged)

        unit().disabled = false
        target("row").interactive = false
        compare(unit().integration.runAction("activate"), false)
        compare(unit().editorOpen, false)
        target("row").interactive = true
    }

    function test_pointer_changes_the_inline_value_without_activating_the_row() {
        focusTarget("row")
        keyClick(Qt.Key_Enter)
        tryVerify(() => unit().integration.observables["editor-focus"]())
        const slider = target("editor")
        const viewport = target("editor-viewport")
        tryVerify(() => viewport.height > 0 && viewport.height >= viewport.implicitHeight)
        const initialVolume = unit().volume
        const initialActivations = unit().activations
        const initialMovements = unit().movements
        const initialCommits = unit().commits
        mouseClick(slider, slider.width * 0.8, slider.height / 2)
        verify(unit().volume !== initialVolume)
        compare(unit().movements, initialMovements + 1)
        compare(unit().commits, initialCommits + 1)
        compare(unit().activations, initialActivations)
        compare(unit().selectedId, "output-volume")
        compare(unit().editorOpen, true)
    }

    function test_programmatic_mute_keeps_the_current_selection_and_focus() {
        focusTarget("row")
        const selected = unit().selectedId
        const focused = target("row")
        compare(unit().integration.runAction("toggle-mute"), true)
        compare(unit().selectedId, selected)
        compare(focused.activeFocus, true)
        compare(unit().muted, true)
    }

    // A nudge whose release never arrives still ends: the slider commits the
    // value it moved once, at the loss, and the stale release adds nothing.
    function test_held_nudge_does_not_commit_after_focus_or_availability_loss() {
        keyClick(Qt.Key_Enter)
        tryVerify(() => unit().integration.observables["editor-focus"]())
        const start = unit().volume
        const commits = unit().commits
        keyPress(Qt.Key_N)
        verify(unit().volume < start)
        compare(unit().commits, commits)
        focusTarget("search-input")
        compare(unit().commits, commits + 1)
        keyRelease(Qt.Key_N)
        compare(unit().commits, commits + 1)

        focusTarget("editor")
        const beforeDisable = unit().volume
        keyPress(Qt.Key_O)
        verify(unit().volume > beforeDisable)
        unit().disabled = true
        compare(unit().commits, commits + 2)
        keyRelease(Qt.Key_O)
        compare(unit().commits, commits + 2)
        const disabledValue = unit().volume
        keyClick(Qt.Key_N)
        compare(unit().volume, disabledValue)
        compare(unit().commits, commits + 2)
    }

    function test_up_down_navigates_the_menu_from_the_open_slider() {
        keyClick(Qt.Key_Enter)
        tryVerify(() => unit().integration.observables["editor-focus"]())
        const value = unit().volume
        keyClick(Qt.Key_Down)
        compare(unit().selectedId, "mute-output")
        compare(unit().editorOpen, false)
        compare(unit().volume, value)
        keyClick(Qt.Key_Down)
        compare(unit().selectedId, "wifi-radio")
        keyClick(Qt.Key_Up)
        compare(unit().selectedId, "mute-output")
    }

    function test_wifi_password_typing_navigation_failure_and_retry() {
        unit().select("wifi-secure")
        keyClick(Qt.Key_Enter)
        tryCompare(target("password-input"), "activeFocus", true)
        keyClick(Qt.Key_N)
        keyClick(Qt.Key_O)
        compare(unit().password.toLowerCase(), "no")
        compare(unit().volume, 0.5)
        keyClick(Qt.Key_Down)
        compare(unit().selectedId, "wifi-open")
        compare(unit().expandedId, "")
        compare(unit().password.toLowerCase(), "no")

        keyClick(Qt.Key_Up)
        keyClick(Qt.Key_Enter)
        tryCompare(target("password-input"), "activeFocus", true)
        keyClick(Qt.Key_Enter)
        verify(unit().wifiError.length > 0)
        compare(unit().wifiPhase, "idle")
        keyClick(Qt.Key_S)
        keyClick(Qt.Key_T)
        keyClick(Qt.Key_A)
        keyClick(Qt.Key_L)
        keyClick(Qt.Key_G)
        keyClick(Qt.Key_I)
        keyClick(Qt.Key_A)
        const draft = unit().password
        unit().simulatedLatency = 20
        unit().failReply = true
        keyClick(Qt.Key_Enter)
        compare(unit().wifiPhase, "connecting")
        tryCompare(unit(), "wifiPhase", "failed")
        compare(unit().password, draft)
        compare(unit().selectedId, "wifi-secure")
        unit().failReply = false
        target("password-input").forceActiveFocus()
        keyClick(Qt.Key_Enter)
        tryCompare(unit(), "wifiPhase", "connected")
        compare(unit().connectedNetwork, "Studio Wi-Fi")
        compare(unit().password, "")
        compare(unit().selectedId, "wifi-secure")
    }

    function test_radio_pointer_and_keyboard_share_toggle_and_skip_dependencies() {
        unit().select("wifi-radio")
        keyClick(Qt.Key_Enter)
        compare(unit().wifiEnabled, false)
        compare(unit().selectedId, "wifi-radio")
        keyClick(Qt.Key_Down)
        compare(unit().selectedId, "bluetooth-radio")
        unit().select("wifi-radio")
        const toggle = target("wifi-switch")
        const activations = unit().activations
        mouseClick(toggle, toggle.width / 2, toggle.height / 2)
        compare(unit().wifiEnabled, true)
        compare(unit().selectedId, "wifi-radio")
        compare(unit().activations, activations)
        keyClick(Qt.Key_Down)
        compare(unit().selectedId, "wifi-secure")
    }

    function test_ble_pair_reset_cancels_a_pending_reply() {
        unit().select("ble-device")
        keyClick(Qt.Key_Enter)
        compare(unit().expandedId, "ble-device")
        unit().simulatedLatency = 20
        compare(unit().integration.runAction("connect-ble"), true)
        compare(unit().blePhase, "connecting")
        unit().reset()
        wait(50)
        compare(unit().blePhase, "idle")
        compare(unit().selectedId, "output-volume")

        unit().select("ble-device")
        keyClick(Qt.Key_Enter)
        compare(unit().integration.runAction("connect-ble"), true)
        tryCompare(unit(), "blePhase", "connected")
        compare(unit().selectedId, "ble-device")
        compare(unit().integration.runAction("connect-ble"), true)
        compare(unit().blePhase, "idle")
    }
}
