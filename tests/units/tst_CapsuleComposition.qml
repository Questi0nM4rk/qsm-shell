import QtQuick
import QtTest

import "../../workbench"

TestCase {
    id: probe

    name: "CapsuleComposition"
    width: 640
    height: 400
    visible: true
    when: windowShown

    property var document: ({
        key: "capsule-composition-test",
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
                    edge: "bottom",
                    alignment: "center",
                    inset: "sm"
                },
                children: [{
                    id: "level",
                    type: "slider",
                    props: { value: 50, label: "Level" }
                }]
            }]
        },
        links: [{ from: { node: "level", event: "changed" }, to: { node: "capsule", action: "open" } }]
    })

    CompositionScene {
        id: scene
        anchors.fill: parent
        composition: probe.document
        previewEnvironment: ({ fullscreen: false, screenRect: Qt.rect(0, 0, probe.width, probe.height), source: "simulated" })
    }

    SignalSpy { id: eventSpy; target: scene; signalName: "eventRecorded" }

    function init() {
        scene.previewEnvironment = ({ fullscreen: false, screenRect: Qt.rect(0, 0, probe.width, probe.height), source: "simulated" })
        scene.resetGeneration++
        scene.composition = probe.document
        eventSpy.clear()
        tryCompare(scene, "storyStatus", "ready")
    }

    function test_real_child_input_routes_to_parent_and_retains_identity() {
        const capsule = scene.nodeAt("capsule")
        const level = scene.nodeAt("level")
        verify(capsule)
        verify(level)
        compare(capsule.target(), capsule.nativeTarget())
        const slider = level.nativeTarget()
        verify(slider)
        verify(slider.enabled)
        slider.forceActiveFocus()
        keyClick(Qt.Key_Right)
        tryVerify(() => level.nativeTarget().value > 50)
        tryVerify(() => capsule.target().shown)
        compare(eventSpy.count, 2)
        compare(eventSpy.signalArguments[0][0].origin, "component")
        compare(eventSpy.signalArguments[0][0].nodeId, "level")
        compare(eventSpy.signalArguments[1][0].origin, "route")
        compare(eventSpy.signalArguments[1][0].payload.to.node, "capsule")

        const childBefore = scene.nodeAt("level")
        scene.previewEnvironment = ({ fullscreen: true, screenRect: Qt.rect(0, 0, probe.width, probe.height), source: "simulated" })
        compare(scene.nodeAt("level"), childBefore)
        compare(level.nativeTarget().value > 50, true)
        compare(capsule.integration.observables.fullscreen(), true)
    }

    function test_nested_pointer_activation_does_not_activate_capsule() {
        scene.composition = ({
            root: { id: "screen", type: "mock-screen", children: [{
                id: "capsule", type: "data-capsule",
                props: { open: true, interactive: true, timeout: 0 },
                children: [{ id: "toggle", type: "checkbox", props: { label: "Keep" } }]
            }] },
            links: []
        })
        tryCompare(scene, "storyStatus", "ready")
        const capsule = scene.nodeAt("capsule")
        const toggle = scene.nodeAt("toggle")
        const activated = scene.integrationForNode("capsule").events
        verify(capsule && toggle && activated.indexOf("activated") >= 0)
        const capsuleBody = capsule.target()
        const slot = capsuleBody.contentItem
        const target = toggle.nativeTarget()
        tryVerify(() => slot.width > 0 && slot.height > 0, 5000)
        verify(slot.width > 0 && slot.height > 0)
        const targetCenter = target.mapToItem(slot, target.width / 2, target.height / 2)
        verify(targetCenter.x >= 0 && targetCenter.x < slot.width)
        verify(targetCenter.y >= 0 && targetCenter.y < slot.height)
        mouseClick(target)
        compare(toggle.integration.observables.checked(), true)
        compare(eventSpy.count, 1)
        compare(eventSpy.signalArguments[0][0].nodeId, "toggle")
        compare(capsule.target().shown, true)
    }

    function test_parent_actions_and_unknown_nodes_are_truthful() {
        const capsule = scene.nodeAt("capsule")
        verify(capsule)
        verify(scene.triggerNodeAction("capsule", 0))
        compare(capsule.capsuleOpen, true)
        compare(capsule.target().shown, true)
        verify(scene.triggerNodeAction("capsule", 1))
        compare(capsule.capsuleOpen, false)
        compare(capsule.target().shown, false)
        verify(scene.applyNodeControl("capsule", 0, 0))
        compare(capsule.capsuleOpen, true)
        compare(capsule.target().shown, true)
        verify(scene.triggerNodeAction("capsule", 2))
        verify(scene.triggerNodeAction("capsule", 3))
        verify(!scene.triggerNodeAction("missing", 0))
        verify(!scene.applyNodeControl("missing", 0, 0))
        verify(!scene.emitNodeEvent("missing", "activated", {}))
    }

    function test_timeout_closes_once_and_cancelled_work_stays_cancelled() {
        scene.composition = ({
            root: { id: "screen", type: "mock-screen", children: [{
                id: "capsule", type: "data-capsule",
                props: { open: true, timeout: 80, "hover-stay": false }, children: []
            }] },
            links: []
        })
        tryCompare(scene, "storyStatus", "ready")
        const capsule = scene.nodeAt("capsule")
        verify(capsule)
        tryVerify(() => !capsule.target().shown, 1000)
        compare(capsule.capsuleOpen, false)
        compare(eventSpy.count, 1)
        compare(eventSpy.signalArguments[0][0].name, "timeout-requested")
        compare(eventSpy.signalArguments[0][0].origin, "component")

        verify(scene.triggerNodeAction("capsule", 0))
        verify(scene.triggerNodeAction("capsule", 3))
        wait(120)
        compare(capsule.target().shown, true)
        compare(eventSpy.count, 1)
    }

    function test_multiple_capsules_use_independent_shared_screen_placement() {
        scene.composition = ({
            root: { id: "screen", type: "mock-screen", children: [
                { id: "left", type: "data-capsule", props: {
                    open: true, edge: "left", alignment: "start", inset: "sm", size: "sm", length: "short"
                }, children: [{ id: "left-child", type: "checkbox", props: { label: "Left" } }] },
                { id: "right", type: "data-capsule", props: {
                    open: true, edge: "right", alignment: "end", inset: "lg", size: "lg", length: "long"
                }, children: [{ id: "right-child", type: "checkbox", props: { label: "Right" } }] }
            ] },
            links: []
        })
        tryCompare(scene, "storyStatus", "ready")
        const screen = scene.nodeAt("screen")
        const left = scene.nodeAt("left")
        const right = scene.nodeAt("right")
        const leftChild = scene.nodeAt("left-child")
        const rightChild = scene.nodeAt("right-child")
        verify(left && right && leftChild && rightChild)
        verify(left.nativeTarget() !== right.nativeTarget())
        verify(leftChild.nativeTarget() !== rightChild.nativeTarget())
        compare(left.x, left.capsuleInset)
        compare(right.x + right.width, probe.width - right.capsuleInset)
        compare(left.placementConstrained, false)
        compare(right.placementConstrained, true)

        scene.previewEnvironment = ({ fullscreen: true, screenRect: Qt.rect(0, 0, 800, 600), source: "simulated" })
        tryCompare(screen, "width", 800)
        compare(scene.nodeAt("left"), left)
        compare(scene.nodeAt("right"), right)
        compare(scene.nodeAt("left-child"), leftChild)
        compare(scene.nodeAt("right-child"), rightChild)
        compare(right.x + right.width, 800 - right.capsuleInset)

        scene.previewEnvironment = ({ fullscreen: true, screenRect: Qt.rect(0, 0, 40, 24), source: "simulated" })
        tryCompare(screen, "width", 40)
        compare(right.placementConstrained, true)
        verify(right.screenPlacement.empty)
        compare(right.nativeTarget(), null)
    }
}
