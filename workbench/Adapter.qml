import QtQuick

Item {
    id: root

    property string mode: "story"
    property var story: ({})
    property string component: ""
    property string variant: ""
    property string storyKey: ""
    property int viewportWidth: 0
    property int viewportHeight: 0
    property int resetGeneration: 0
    property bool interactive: false
    property var composition: null

    readonly property string storyStatus: delegate.item && delegate.item.storyStatus !== undefined
        ? String(delegate.item.storyStatus)
        : delegate.status === Loader.Ready ? "ready"
        : delegate.status === Loader.Error ? "failed" : "loading"
    readonly property string storySource: delegate.item && delegate.item.storySource !== undefined
        ? String(delegate.item.storySource) : String(delegate.source)
    readonly property string storyError: delegate.item && delegate.item.storyError !== undefined
        ? String(delegate.item.storyError)
        : delegate.status === Loader.Error ? "failed to load " + delegate.source : ""
    readonly property var controls: delegate.item && delegate.item.controls !== undefined ? delegate.item.controls : []
    readonly property var actions: delegate.item && delegate.item.actions !== undefined ? delegate.item.actions : []
    readonly property real contentExtentWidth: delegate.item && delegate.item.contentExtentWidth !== undefined
        ? Number(delegate.item.contentExtentWidth) : width
    readonly property real contentExtentHeight: delegate.item && delegate.item.contentExtentHeight !== undefined
        ? Number(delegate.item.contentExtentHeight) : height

    signal eventRecorded(var record)
    signal inspectionReady(var inspection)

    function applyControl(groupIndex, optionIndex) {
        return delegate.item && typeof delegate.item.applyControl === "function"
            ? delegate.item.applyControl(groupIndex, optionIndex) : false
    }

    function triggerAction(index) {
        return delegate.item && typeof delegate.item.triggerAction === "function"
            ? delegate.item.triggerAction(index) : false
    }

    function dumpTree() {
        if (delegate.item && typeof delegate.item.dumpTree === "function")
            delegate.item.dumpTree()
    }

    Loader {
        id: delegate
        anchors.fill: parent
        source: root.mode === "composition"
            ? Qt.resolvedUrl("CompositionPreview.qml")
            : Qt.resolvedUrl("StoryHost.qml")
        onLoaded: {
            if (root.mode === "composition") {
                item.composition = root.composition
                item.resetGeneration = root.resetGeneration
            } else {
                item.component = root.component
                item.variant = root.variant
                item.storyKey = root.storyKey
                item.resetGeneration = root.resetGeneration
                item.viewportWidth = root.viewportWidth
                item.viewportHeight = root.viewportHeight
                item.interactive = root.interactive
                item.story = root.story
            }
        }
    }

    Connections {
        target: delegate.item
        function onEventRecorded(record) { root.eventRecorded(record) }
        function onInspectionReady(inspection) { root.inspectionReady(inspection) }
    }

    onResetGenerationChanged: {
        if (delegate.item)
            delegate.item.resetGeneration = root.resetGeneration
    }
}
