import QtQuick

import qs.QsmShell.Style

Rectangle {
    id: root

    property var composition: null
    property int resetGeneration: 0
    property var previewEnvironment: null

    readonly property string storyKey: root.composition && root.composition.key !== undefined
        ? String(root.composition.key) : ""
    readonly property string storyStatus: root._status
    readonly property string storyError: root._storyError
    readonly property var controls: root._flatControls
    readonly property var actions: root._flatActions
    readonly property int nodeCount: root._ids.length
    readonly property real contentExtentWidth: Math.max(root.width,
        root._rootNode ? Number(root._rootNode.width) : 0)
    readonly property real contentExtentHeight: Math.max(root.height,
        root._rootNode ? Number(root._rootNode.height) : 0)
    readonly property var integration: ({ "idle": () => root.idle() })

    signal eventRecorded(var record)

    property string _status: "loading"
    property string _storyError: ""
    property var _ids: []
    property var _registry: ({})
    property int _sequence: 0
    property var _routeChain: []
    property var _flatControls: []
    property var _flatActions: []
    property var _rootNode: null
    property int _generation: 0

    color: Style.background

    function list(value: var): var {
        if (value === null || value === undefined)
            return []
        if (Array.isArray(value))
            return value
        const out = []
        for (let i = 0; i < value.length; i++)
            out.push(value[i])
        return out
    }

    function nodeAt(nodeId: var): var {
        const id = String(nodeId ?? "")
        if (!Object.prototype.hasOwnProperty.call(root._registry, id))
            return null
        return root._registry[id]
    }

    function integrationForNode(nodeId: var): var {
        const node = root.nodeAt(nodeId)
        return node ? (node.integration ?? null) : null
    }

    function controlsForNode(nodeId: var): var {
        const node = root.nodeAt(nodeId)
        return node ? root.list(node.controls) : []
    }

    function actionsForNode(nodeId: var): var {
        const node = root.nodeAt(nodeId)
        if (!node)
            return []
        return root.list(node.actions).map(entry => ({
            "nodeId": String(nodeId), "label": String(entry.text), "text": String(entry.text)
        }))
    }

    function applyNodeControl(nodeId: var, groupIndex: int, optionIndex: int): bool {
        const node = root.nodeAt(nodeId)
        return node ? node.applyControl(groupIndex, optionIndex) : false
    }

    function triggerNodeAction(nodeId: var, actionIndex: int): bool {
        const node = root.nodeAt(nodeId)
        return node ? node.triggerAction(actionIndex) : false
    }

    function emitNodeEvent(nodeId: var, event: var, payload: var): bool {
        const node = root.nodeAt(nodeId)
        if (!node)
            return false
        if (root.list(node.events).indexOf(String(event)) < 0)
            return false
        return root.recordNodeEvent(String(nodeId), String(event), payload, "injected") !== null
    }

    function applyControl(groupIndex: int, optionIndex: int): bool {
        if (groupIndex < 0 || groupIndex >= root._flatControls.length)
            return false
        const entry = root._flatControls[groupIndex]
        return root.applyNodeControl(entry.nodeId, entry.index, optionIndex)
    }

    function triggerAction(index: int): bool {
        if (index < 0 || index >= root._flatActions.length)
            return false
        const entry = root._flatActions[index]
        return root.triggerNodeAction(entry.nodeId, entry.index)
    }

    function idle(): bool {
        if (root.storyStatus !== "ready")
            return false
        for (const nodeId of root._ids) {
            const integration = root.integrationForNode(nodeId)
            if (integration && typeof integration.idle === "function" && integration.idle() !== true)
                return false
        }
        return true
    }

    // Only a declared event of a node in the current tree speaks, and only as
    // the origin it arrived with: a real component intent is a component
    // event, an injected one is not.
    function recordNodeEvent(nodeId: var, name: var, payload: var, origin: var): var {
        const node = root.nodeAt(nodeId)
        if (!node)
            return null
        const event = String(name)
        if (root.list(node.events).indexOf(event) < 0)
            return null
        root._sequence++
        const record = {
            "sequence": root._sequence,
            "origin": origin !== undefined && origin !== null ? String(origin) : "component",
            "name": event,
            "nodeId": String(nodeId),
            "payload": payload !== undefined && payload !== null ? payload : ({})
        }
        root.eventRecorded(record)
        try {
            root.routeLinks(String(nodeId), event)
        } catch (error) {
            root._status = "error"
            root._storyError = String(error.message ?? error)
            root._refresh()
        }
        return root._status === "error" ? null : record
    }

    // A link is a named event on a named node reaching a named action on a
    // named node. A hop already on the chain is refused rather than followed,
    // so a document whose links form a cycle stops instead of recursing.
    function routeLinks(sourceId: string, event: string): void {
        const key = sourceId + "/" + event
        if (root._routeChain.indexOf(key) >= 0) {
            throw new Error("composition route cycle at " + key)
        }
        root._routeChain.push(key)
        try {
            for (const link of root.list(root.composition ? root.composition.links : null)) {
                const from = link ? link.from : null
                const to = link ? link.to : null
                if (!from || !to || String(from.node) !== sourceId || String(from.event) !== event)
                    continue
                const targetId = String(to.node)
                const action = String(to.action)
                const target = root.nodeAt(targetId)
                if (!target)
                    throw new Error("composition route " + key + " target node '" + targetId + "' is missing for action '" + action + "'")
                if (!target.runAction(action))
                    throw new Error("composition route " + key + " target node '" + targetId + "' refused action '" + action + "'")
                if (root._status === "error")
                    throw new Error(root._storyError)
                root._sequence++
                root.eventRecorded({
                    "sequence": root._sequence,
                    "origin": "route",
                    "name": action,
                    "nodeId": sourceId,
                    "payload": {
                        "from": { "node": sourceId, "event": event },
                        "to": { "node": targetId, "action": action }
                    }
                })
            }
        } finally {
            root._routeChain.pop()
        }
    }

    function registerNode(nodeId: var, node: var, generation: var): void {
        if (generation !== undefined && generation !== root._generation)
            return
        const id = String(nodeId ?? "")
        if (root._ids.indexOf(id) < 0)
            return
        root._registry = Object.assign({}, root._registry, { [id]: node })
        root._refresh()
        root._settle()
    }

    function failNode(nodeId: var, nodeType: var, reason: var, generation: var): void {
        if (generation !== undefined && generation !== root._generation)
            return
        const id = String(nodeId ?? "")
        if (root._ids.indexOf(id) < 0)
            return
        root._status = "error"
        root._storyError = "node \"" + id + "\" of type \"" + String(nodeType ?? "")
            + "\": " + String(reason ?? "could not be composed")
        root._refresh()
        root._settle()
    }

    function rebuild(): void {
        root._generation++
        if (root._rootNode) {
            root._rootNode.parent = null
            root._rootNode.destroy()
            root._rootNode = null
        }
        root._registry = ({})
        root._ids = []
        root._flatControls = []
        root._flatActions = []
        root._routeChain = []
        root._sequence = 0
        root._status = "loading"
        root._storyError = ""
        const doc = root.composition
        if (!doc || !doc.root) {
            root._status = "error"
            root._storyError = "the composition has no root node"
            return
        }
        root._collectIds(doc.root)
        if (root._ids.length === 0) {
            root._status = "error"
            root._storyError = "the composition has no nodes"
            return
        }
        const node = nodeFactory.createObject(root, {
            "node": doc.root, "scene": root, "generation": root._generation,
            "previewEnvironment": Qt.binding(() => root.previewEnvironment)
        })
        if (!node) {
            root._status = "error"
            root._storyError = "the root node could not be composed"
            return
        }
        root._rootNode = node
    }

    function _collectIds(node: var): void {
        const id = String(node ? node.id ?? "" : "")
        if (id !== "" && root._ids.indexOf(id) < 0)
            root._ids.push(id)
        for (const child of root.list(node ? node.children : null))
            root._collectIds(child)
    }

    // Document order, so a flattened index names the same node every time.
    function _refresh(): void {
        const groups = []
        const acts = []
        for (const nodeId of root._ids) {
            const node = root.nodeAt(nodeId)
            if (!node)
                continue
            root.list(node.controls).forEach((group, index) => groups.push({
                "nodeId": nodeId, "index": index,
                "label": String(group.label ?? ""), "options": group.options ?? []
            }))
            root.list(node.actions).forEach((entry, index) => acts.push({
                "nodeId": nodeId, "index": index, "label": String(entry.text ?? ""),
                "text": String(entry.text ?? "")
            }))
        }
        root._flatControls = groups
        root._flatActions = acts
    }

    function _settle(): void {
        if (root._status === "error" || root._ids.length === 0)
            return
        if (Object.keys(root._registry).length >= root._ids.length)
            root._status = "ready"
    }

    Component {
        id: nodeFactory
        CompositionNode {}
    }

    onCompositionChanged: root.rebuild()
    onResetGenerationChanged: root.rebuild()
    Component.onCompleted: root.rebuild()
}
