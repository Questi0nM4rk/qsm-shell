import QtQuick
import QtTest

TestCase {
    id: testCase
    name: "PreviewEnvironmentBoundary"
    width: 800
    height: 600
    when: windowShown

    QtObject {
        id: environment
        property bool fullscreen: false
        property rect screenRect: Qt.rect(0, 0, 800, 600)
        property string source: "simulated"
    }

    property var adapterComponent: null
    property var adapter: null

    function initTestCase() {
        adapterComponent = Qt.createComponent(Qt.resolvedUrl("../../workbench/Adapter.qml"))
        compare(adapterComponent.status, Component.Ready, adapterComponent.errorString())
    }

    function cleanup() {
        if (adapter)
            adapter.destroy()
        adapter = null
    }

    function test_standaloneSnapshotDeclaresDesktopSimulation() {
        adapter = adapterComponent.createObject(testCase, {
            "viewportWidth": 800,
            "viewportHeight": 600
        })
        verify(adapter)
        compare(adapter.previewEnvironmentSnapshot.supported, false)
        compare(adapter.previewEnvironmentSnapshot.fullscreen, false)
        compare(adapter.previewEnvironmentSnapshot.source, "desktop-simulation")
        compare(adapter.previewEnvironmentSnapshot.screenRect.width, 800)
        let inspection = null
        adapter.inspectionReady.connect(value => inspection = value)
        adapter.dumpTree()
        compare(inspection.previewEnvironment.supported, false)
        compare(inspection.previewEnvironment.source, "desktop-simulation")
    }

    function test_compositionNodesShareLiveEnvironmentWithoutRebuild() {
        const composition = {
            key: "environment-test",
            viewport: [800, 600],
            root: {
                id: "root",
                type: "row",
                children: [{ id: "level", type: "slider", props: { value: 42 } }]
            }
        }
        adapter = adapterComponent.createObject(testCase, {
            "mode": "composition",
            "composition": composition,
            "previewEnvironment": environment,
            "viewportWidth": 800,
            "viewportHeight": 600
        })
        verify(adapter)
        tryCompare(adapter, "storyStatus", "ready")
        const scene = adapter._scene
        const rootNode = scene.nodeAt("root")
        const childNode = scene.nodeAt("level")
        verify(rootNode)
        verify(childNode)
        verify(adapter.previewEnvironmentSnapshot.supported)
        compare(adapter.previewEnvironmentSnapshot.source, "simulated")
        compare(scene.previewEnvironment, environment)
        compare(rootNode.previewEnvironment, environment)
        compare(childNode.previewEnvironment, environment)
        environment.fullscreen = true
        compare(adapter.previewEnvironmentSnapshot.fullscreen, true)
        compare(scene.nodeAt("root"), rootNode)
        compare(scene.nodeAt("level"), childNode)
        compare(childNode.previewEnvironment.fullscreen, true)
    }
}
