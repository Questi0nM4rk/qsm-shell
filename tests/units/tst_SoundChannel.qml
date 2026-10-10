import QtQuick
import QtTest

import "../../workbench"

TestCase {
    id: probe

    name: "SoundChannel"
    width: 640
    height: 480
    visible: true
    when: windowShown

    property var document: ({
        root: {
            id: "screen",
            type: "mock-screen",
            children: [{
                id: "capsule",
                type: "data-capsule",
                props: {
                    open: true,
                    interactive: true,
                    timeout: 0,
                    edge: "right",
                    inset: "sm",
                    orientation: "vertical",
                    size: "lg",
                    length: "long"
                },
                children: [{
                    id: "output",
                    type: "sound-channel",
                    props: { level: 42, muted: false, icon: "volume" }
                }]
            }]
        },
        links: [
            { from: { node: "output", event: "changed" }, to: { node: "capsule", action: "open" } },
            { from: { node: "output", event: "mute-changed" }, to: { node: "capsule", action: "open" } }
        ]
    })

    CompositionScene {
        id: scene
        anchors.fill: parent
        composition: probe.document
        previewEnvironment: ({ fullscreen: false, screenRect: Qt.rect(0, 0, probe.width, probe.height), source: "simulated" })
    }

    SignalSpy { id: eventSpy; target: scene; signalName: "eventRecorded" }

    function init() {
        scene.resetGeneration++
        scene.composition = probe.document
        eventSpy.clear()
        tryCompare(scene, "storyStatus", "ready")
    }

    function fitsIn(item: var, parent: var): bool {
        const origin = item.mapToItem(parent, 0, 0)
        return origin.x >= 0 && origin.y >= 0
            && origin.x + item.width <= parent.width
            && origin.y + item.height <= parent.height
    }

    function test_native_targets_are_the_slider_and_mute_label() {
        const channel = scene.nodeAt("output")
        const capsule = scene.nodeAt("capsule").target()
        const targets = channel.integration.targets
        const slider = targets.slider()
        const label = targets["mute-label"]()
        const slot = capsule.contentItem
        tryVerify(() => slot.width > 0 && slot.height > 0 && label.visible)
        verify(fitsIn(slider, slot))
        verify(fitsIn(label, slot))
        verify(slider)
        verify(label)
        compare(slider.objectName, "soundChannelSlider")
        compare(label.objectName, "sliderLabel")
        compare(slider, channel.nativeTarget())
        compare(label, channel.nativeTarget("mute-label"))
        verify(typeof targets["unknown-target"] !== "function")
        verify(channel.nativeTarget("unknown-target") === null)
        verify(!scene.triggerNodeAction("output", 99))
        verify(!scene.applyNodeControl("output", 99, 0))
        verify(!scene.triggerNodeAction("missing", 0))
    }

    function test_setup_and_control_writes_are_not_component_events() {
        const channel = scene.nodeAt("output")
        compare(channel.integration.observables.level(), 42)
        verify(scene.applyNodeControl("output", 0, 2))
        verify(scene.applyNodeControl("output", 1, 1))
        compare(channel.integration.observables.level(), 100)
        compare(channel.integration.observables.muted(), true)
        compare(eventSpy.count, 0)
        verify(!scene.triggerNodeAction("output", 3))
        compare(eventSpy.count, 0)
    }

    function test_label_mute_retains_level_and_routes_component_intent() {
        const channel = scene.nodeAt("output")
        const capsule = scene.nodeAt("capsule")
        const label = channel.integration.targets["mute-label"]()
        const slot = capsule.target().contentItem
        tryVerify(() => slot.width > 0 && slot.height > 0 && label.visible)
        verify(fitsIn(label, slot))
        mouseMove(label, label.width / 2, label.height / 2)
        mouseClick(label)
        compare(channel.integration.observables.level(), 42)
        compare(channel.integration.observables.muted(), true)
        compare(capsule.capsuleOpen, true)
        compare(eventSpy.count, 2)
        compare(eventSpy.signalArguments[0][0].name, "mute-changed")
        compare(eventSpy.signalArguments[0][0].origin, "component")
        compare(eventSpy.signalArguments[1][0].origin, "route")

        mouseClick(label)
        compare(channel.integration.observables.level(), 42)
        compare(channel.integration.observables.muted(), false)
        compare(eventSpy.count, 4)
        compare(eventSpy.signalArguments[2][0].name, "mute-changed")
    }

    function test_named_mute_action_uses_label_and_refuses_disabled_channel() {
        const channel = scene.nodeAt("output")
        compare(channel.integration.observables.level(), 42)
        verify(channel.integration.runAction("toggle-mute"))
        compare(channel.integration.observables.muted(), true)
        compare(channel.integration.observables.level(), 42)
        verify(channel.integration.runAction("toggle-mute"))
        compare(channel.integration.observables.muted(), false)
        compare(channel.integration.observables.level(), 42)
        compare(eventSpy.count, 4)
        compare(eventSpy.signalArguments[0][0].origin, "component")
        compare(eventSpy.signalArguments[1][0].origin, "route")
        compare(eventSpy.signalArguments[2][0].origin, "component")
        compare(eventSpy.signalArguments[3][0].origin, "route")

        verify(scene.applyNodeControl("output", 2, 1))
        verify(!channel.integration.runAction("toggle-mute"))
        compare(channel.integration.observables.muted(), false)
        compare(eventSpy.count, 4)
    }

    function test_label_keyboard_activation_preserves_level() {
        const channel = scene.nodeAt("output")
        const label = channel.integration.targets["mute-label"]()
        const slider = channel.integration.targets.slider()
        slider.forceActiveFocus()
        for (let step = 0; step < 8 && !label.activeFocus; step++)
            keyClick(Qt.Key_Tab)
        verify(label.activeFocus, "Tab traversal did not reach the actual Slider label")
        keyClick(Qt.Key_Space)
        compare(channel.integration.observables.muted(), true)
        compare(channel.integration.observables.level(), 42)
        compare(eventSpy.signalArguments[0][0].name, "mute-changed")
        keyClick(Qt.Key_Return)
        compare(channel.integration.observables.muted(), false)
        compare(channel.integration.observables.level(), 42)
        keyClick(Qt.Key_Backtab)
        verify(!label.activeFocus, "Backtab could not leave the Slider label")
    }

    function test_keyboard_pointer_and_wheel_write_level_and_unmute() {
        const channel = scene.nodeAt("output")
        const slider = channel.integration.targets.slider()
        const capsule = scene.nodeAt("capsule")
        const slot = capsule.target().contentItem
        const track = slider.contentItem
        tryVerify(() => slot.width > 0 && slot.height > 0 && track.width > 0 && track.height > 0)
        verify(fitsIn(slider, slot))
        verify(fitsIn(track, slot))

        verify(scene.applyNodeControl("output", 1, 1))
        slider.forceActiveFocus()
        keyClick(Qt.Key_Up)
        tryVerify(() => channel.integration.observables.level() > 42)
        compare(channel.integration.observables.muted(), false)
        compare(eventSpy.signalArguments[0][0].name, "changed")
        compare(eventSpy.signalArguments[0][0].origin, "component")
        compare(eventSpy.signalArguments[1][0].origin, "route")
        verify(capsule.capsuleOpen)

        const afterKey = channel.integration.observables.level()
        mouseMove(track, track.width / 2, track.height / 2)
        mouseWheel(track, track.width / 2, track.height / 2, 0, 120)
        tryVerify(() => channel.integration.observables.level() === afterKey + slider.wheelUnits)

        const beforePointer = channel.integration.observables.level()
        mouseClick(track, track.width / 2, track.height / 2)
        tryVerify(() => channel.integration.observables.level() < beforePointer)
    }
}
