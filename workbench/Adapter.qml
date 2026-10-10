import QtQuick

// The provider's whole contribution to the storybook: host ONE unit, the one
// its catalog names, or ONE composition scene, the document it was handed, and
// forward that contract. No window, no view, no catalog of its own.
Item {
    id: root

    property string mode: "story"
    property var story: ({})
    property var composition: null
    property string component: ""
    property string variant: ""
    property string storyKey: ""
    property int viewportWidth: 0
    property int viewportHeight: 0
    property int resetGeneration: 0
    property bool interactive: false
    property var previewEnvironment: null

    // Optional native-input seam: the harness supplies its window-local Qt
    // input driver here when the unit names real targets. Without it the
    // adapter keeps its semantic API, which is what older adapters speak.
    property var inputDriver: null

    // A document is a composition whatever the caller called the mode: the
    // live canvas hands over a composition and nothing else.
    readonly property bool _isComposition: composition !== null && composition !== undefined

    // Read from the unit. A story with no harness, or a harness that has not
    // reported its states, says so here rather than pretending to be ready.
    readonly property bool _loaded: !_isComposition && unitLoader.status === Loader.Ready && !!unitLoader.item
    readonly property var _unit: _loaded ? unitLoader.item : null
    readonly property bool _sceneLoaded: sceneLoader.status === Loader.Ready && !!sceneLoader.item
    readonly property var _scene: _sceneLoaded ? sceneLoader.item : null

    readonly property string storyStatus: _isComposition
        ? (sceneLoader.status === Loader.Error ? "error" : _scene ? _scene.storyStatus : "loading")
        : _loaded ? "ready" : unitLoader.status === Loader.Error ? "failed" : "loading"
    readonly property string storySource: _isComposition
        ? (_scene ? _scene.storyKey : "")
        : _loaded ? String(_unit.objectName ?? storyKey) : ""
    readonly property string storyError: _isComposition
        ? (sceneLoader.status === Loader.Error
            ? "could not load the composition scene"
            : _scene ? _scene.storyError : "")
        : unitLoader.status === Loader.Error
            ? "could not load the unit for story '" + storyKey + "'" : ""
    readonly property var controls: _isComposition
        ? (_scene ? asArray(_scene.controls) : [])
        : _loaded ? asArray(_unit.controls) : []
    // The unit's own action names, unchanged: the flow addresses an action by
    // the name the unit gave it, and a second label list here would be a second
    // rule for what an action is called.
    readonly property var actions: _isComposition
        ? (_scene ? asArray(_scene.actions) : [])
        : _loaded ? asArray(integration?.actions) : []
    readonly property real contentExtentWidth: _isComposition
        ? (_scene ? Number(_scene.contentExtentWidth) : width)
        : _loaded && _unit.contentExtentWidth !== undefined
            ? Number(_unit.contentExtentWidth) : width
    readonly property real contentExtentHeight: _isComposition
        ? (_scene ? Number(_scene.contentExtentHeight) : height)
        : _loaded && _unit.contentExtentHeight !== undefined
            ? Number(_unit.contentExtentHeight) : height

    // A composition's root answers with aggregate idleness only: every node
    // owns its own capabilities, and a global control list would be a second
    // place claiming to know which node a control meant.
    readonly property var integration: _isComposition
        ? (_scene ? _scene.integration : null)
        : _loaded ? (_unit.integration ?? null) : null
    readonly property var events: asArray(integration?.events)
    readonly property var observables: integration?.observables ?? null
    readonly property bool _drivable: integration !== null
    readonly property var previewEnvironmentSnapshot: previewEnvironment
        ? ({
            supported: true,
            fullscreen: previewEnvironment.fullscreen === true,
            screenRect: {
                x: previewEnvironment.screenRect.x,
                y: previewEnvironment.screenRect.y,
                width: previewEnvironment.screenRect.width,
                height: previewEnvironment.screenRect.height
            },
            source: String(previewEnvironment.source)
        })
        : ({
            supported: false,
            fullscreen: false,
            screenRect: { x: 0, y: 0, width: root.width, height: root.height },
            source: "desktop-simulation"
        })

    signal eventRecorded(var record)
    signal inspectionReady(var inspection)

    readonly property int _documentWidth: _isComposition
        ? Number(asArray(composition?.viewport)[0]) || 0 : 0
    readonly property int _documentHeight: _isComposition
        ? Number(asArray(composition?.viewport)[1]) || 0 : 0

    width: viewportWidth > 0 ? viewportWidth : _documentWidth > 0 ? _documentWidth : 1
    height: viewportHeight > 0 ? viewportHeight : _documentHeight > 0 ? _documentHeight : 1

    // The catalog's `unit` arrives as an absolute URL from the launcher.
    readonly property url _unitSource: story && typeof story.unit === "string" && story.unit.length > 0
        ? String(story.unit)
        : ""

    function asArray(value) {
        if (value === null || value === undefined)
            return []
        if (Array.isArray(value))
            return value
        if (typeof value.length === "number") {
            const out = []
            for (let i = 0; i < value.length; i++)
                out.push(value[i])
            return out
        }
        return []
    }

    function integrationForNode(nodeId: string): var {
        return _isComposition && _scene ? _scene.integrationForNode(nodeId) : null
    }

    function controlsForNode(nodeId: string): var {
        return _isComposition && _scene ? _scene.controlsForNode(nodeId) : []
    }

    function actionsForNode(nodeId: string): var {
        return _isComposition && _scene ? _scene.actionsForNode(nodeId) : []
    }

    function applyNodeControl(nodeId: string, groupIndex: int, optionIndex: int): bool {
        return _isComposition && _scene
            ? _scene.applyNodeControl(nodeId, groupIndex, optionIndex) : false
    }

    function triggerNodeAction(nodeId: string, actionIndex: int): bool {
        return _isComposition && _scene ? _scene.triggerNodeAction(nodeId, actionIndex) : false
    }

    // Declared semantic injection, and the injection hook the nodes are given:
    // both arrive as an injected event, never as a component one.
    function emitNodeEvent(nodeId: string, event: string, payload: var): bool {
        return _isComposition && _scene ? _scene.emitNodeEvent(nodeId, event, payload) : false
    }

    // A control applies to the UNIT, never to a list this file holds, so a
    // state the pointer cannot reach is reached the same way for every type.
    function applyControl(groupIndex: int, optionIndex: int): bool {
        if (_isComposition)
            return _scene ? _scene.applyControl(groupIndex, optionIndex) : false
        if (!_loaded)
            return false
        const groups = controls
        if (groupIndex < 0 || groupIndex >= groups.length)
            return false
        const options = asArray(groups[groupIndex].options)
        if (optionIndex < 0 || optionIndex >= options.length)
            return false
        const option = options[optionIndex]
        if (!option)
            return false
        if (option.call !== undefined) {
            if (typeof _unit[option.call] !== "function")
                return false
            _unit[option.call]()
        } else if (option.set !== undefined) {
            for (const key in option.set)
                _unit[key] = option.set[key]
        } else {
            return false
        }
        return true
    }

    // An action is a name the unit listed in `integration.actions`, reached
    // through the unit's own `runAction`. Pointer, keyboard and the harness all
    // arrive at that one door.
    function triggerAction(index: int): bool {
        if (_isComposition)
            return _scene ? _scene.triggerAction(index) : false
        if (!_loaded || typeof integration?.runAction !== "function")
            return false
        const list = actions
        if (index < 0 || index >= list.length)
            return false
        const name = String(list[index] ?? "")
        if (name === "")
            return false
        if (integration.runAction(name) !== true)
            return false
        eventRecorded({ "origin": "action", "name": name })
        return true
    }

    // The dump is the unit's item tree plus what the harness cannot see: the
    // states it declared and whether it can be driven at all.
    function dumpTree(): void {
        inspectionReady({
            story: _isComposition ? storySource : storyKey,
            component: component,
            variant: variant,
            status: storyStatus,
            error: storyError,
            drivable: _drivable,
            events: events,
            controlGroups: controls.length,
            actionCount: actions.length,
            nodeCount: _isComposition && _scene ? _scene.nodeCount : 0,
            previewEnvironment: previewEnvironmentSnapshot
        })
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    Loader {
        id: unitLoader
        active: !root._isComposition && String(root._unitSource) !== ""
        source: root._unitSource
        anchors.fill: parent
        visible: root._loaded
        onLoaded: {
            const item = unitLoader.item
            if (!item)
                return
            if ("componentKey" in item)
                item.componentKey = Qt.binding(() => root.component)
            if ("variant" in item)
                item.variant = Qt.binding(() => root.variant)
            if ("eventRecorder" in item)
                item.eventRecorder = (kind, name, payload) => root.eventRecorded({ "origin": "component", "kind": kind, "name": name, "payload": payload ?? {} })
            if ("previewEnvironment" in item)
                item.previewEnvironment = Qt.binding(() => root.previewEnvironment)
        }
    }

    Loader {
        id: sceneLoader
        active: root._isComposition
        source: "CompositionScene.qml"
        anchors.fill: parent
        onLoaded: {
            root._scene.composition = Qt.binding(() => root.composition)
            root._scene.resetGeneration = Qt.binding(() => root.resetGeneration)
            root._scene.previewEnvironment = Qt.binding(() => root.previewEnvironment)
        }
    }

    // Reset is a reconstruction, not a message nothing has to implement.
    onResetGenerationChanged: {
        if (_isComposition || _unitSource === "")
            return
        unitLoader.active = false
        unitLoader.active = true
    }

    Connections {
        target: unitLoader.item
        function onEventRecorded(record) { root.eventRecorded(record) }
        function onInspectionReady(inspection) { root.inspectionReady(inspection) }
    }

    Connections {
        target: sceneLoader.item
        function onEventRecorded(record) { root.eventRecorded(record) }
    }
}
