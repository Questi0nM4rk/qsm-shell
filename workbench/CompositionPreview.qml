import QtQuick

import qs.QsmShell.Style
import "inspect.js" as Inspect

// Preview-owned composition runtime (beads 2.1-2.4): recursive exact-size
// construction of tokenized Column/Row/Stack layouts, the seven migrated
// input leaves, and the Menu and ShellBorder/Rollout containers, with the
// same outward contract as StoryHost.qml. Unknown types fail truthfully;
// documents never resolve a source path.
Rectangle {
    id: root

    // The versioned composition document: { key, viewport:[w,h], root }.
    property var composition: null
    // Bumped by the host to destroy and reconstruct the current document.
    property int resetGeneration: 0
    property var integrationController: null
    readonly property var checkpointController: root.integrationController ? root.integrationController : ownedIntegrationController

    readonly property string storyKey: root.composition && root.composition.key !== undefined
        ? String(root.composition.key) : ""
    readonly property string storyStatus: root._status
    readonly property string storySource: root.storyKey
    readonly property string storyError: root._storyError
    // Flattened per-node observability: controls carry { nodeId, label,
    // options }; actions carry { nodeId, label, action }.
    readonly property var controls: root._flatControls
    readonly property var actions: root._flatActions

    property string _status: "loading"
    property string _storyError: ""
    property var _flatControls: []
    property var _flatActions: []
    property var _registry: ({})
    property var _expectedIds: ({})
    property int _expectedNodes: 0
    property var _failures: []

    // Deterministic event record: { sequence, kind, name, payload,
    // storyKey, nodeId }.
    property int _eventSequence: 0
    signal eventRecorded(var record)
    signal inspectionReady(var inspection)

    property int viewportWidth: Number(root.asArray(root.composition ? root.composition.viewport : null)[0]) || 960
    property int viewportHeight: Number(root.asArray(root.composition ? root.composition.viewport : null)[1]) || 640
    readonly property real contentExtentWidth: Math.max(root.viewportWidth,
        root._rootNode ? Number(root._rootNode.width) || 0 : 0)
    readonly property real contentExtentHeight: Math.max(root.viewportHeight,
        root._rootNode ? Number(root._rootNode.height) || 0 : 0)
    width: viewportWidth
    height: viewportHeight
    color: "#1c0e27"

    property string theme: "deep-night"
    property var backend: null
    property var _deepNightBackend: ({})
    function _loadTheme(): void {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("theme.json"), false);
        request.send();
        if (request.responseText.length === 0) {
            console.warn("CompositionPreview: could not read workbench/theme.json -- run through "
                + "scripts/preview-qml.mjs or scripts/capture-qml.mjs, which set "
                + "QML_XHR_ALLOW_FILE_READ");
            return;
        }
        root._deepNightBackend = JSON.parse(request.responseText);
    }
    property var _themeFixtures: ({ "deep-night": root._deepNightBackend })
    property var activeBackend: backend !== null && backend !== undefined ? backend : (_themeFixtures[theme] || null)
    Component.onCompleted: {
        root._loadTheme();
        Style.backend = root.activeBackend;
        root.rebuild();
    }
    onActiveBackendChanged: Style.backend = root.activeBackend

    onCompositionChanged: root.rebuild()
    onResetGenerationChanged: {
        root._eventSequence = 0;
        root.rebuild();
    }

    Item {
        id: treeHost
        anchors.fill: parent
    }

    Component {
        id: nodeFactory
        CompositionNode {}
    }
    IntegrationController { id: ownedIntegrationController }
    property var _rootNode: null
    property int _generation: 0

    // Arrays crossing createObject/setSource arrive as QVariantList, for
    // which Array.isArray is false. Normalize once here so every walk below
    // sees a real JS array.
    function asArray(v): var {
        if (v === null || v === undefined)
            return [];
        if (Array.isArray(v))
            return v;
        if (typeof v.length === "number") {
            const out = [];
            for (let i = 0; i < v.length; i++)
                out.push(v[i]);
            return out;
        }
        return [];
    }

    function countNodes(n): int {
        let count = 1;
        const kids = root.asArray(n ? n.children : null);
        for (let i = 0; i < kids.length; i++)
            count += root.countNodes(kids[i]);
        return count;
    }

    // Canonical descriptor event per (node type, component intent). Components report
    // their own public intent names (toggle, edited, committed, selection);
    // links are written against the stable descriptor names, so the
    // translation lives here, once, instead of in every adapter. Empty means
    // the intent is recorded but never routable. Container adapters emit
    // the canonical names directly, which pass through unchanged.
    function canonicalEvent(nodeType: string, intent: string): string {
        switch (nodeType) {
        case "text-field":
            return intent === "accepted" ? "accepted" : intent === "edited" ? "changed" : "";
        case "checkbox":
        case "switch":
            return intent === "toggle" ? "toggled" : "";
        case "radio":
            return intent === "selection" ? "selected" : "";
        case "slider":
            return intent === "committed" ? "changed" : "";
        case "segmented":
            return intent === "selected" ? "changed" : "";
        case "spin-box":
            return intent === "changed" ? "changed" : "";
        case "menu":
            return intent === "opened" || intent === "closed" || intent === "selected" ? intent : "";
        case "shell-border-rollout":
            return intent === "opened" || intent === "closed" ? intent : "";
        default:
            return "";
        }
    }

    // Fixed named-action allowlist, mirroring workbench/composition-types.json
    // and the adapters in CompositionNode.qml. Links invoke through
    // invokeNodeAction below; nothing here resolves a source path.
    function implementedActions(nodeType: string): var {
        switch (nodeType) {
        case "text-field":
            return ["clear", "focus"];
        case "checkbox":
            return ["toggle", "check", "uncheck"];
        case "switch":
            return ["toggle"];
        case "radio":
            return ["select"];
        case "slider":
            return ["reset"];
        case "segmented":
            return ["reset"];
        case "spin-box":
            return ["increment", "decrement", "reset"];
        case "menu":
            return ["open", "close", "toggle"];
        case "shell-border-rollout":
            return ["open", "close", "toggle"];
        default:
            return [];
        }
    }

    function collectIds(n, out): void {
        out.push(String(n.id));
        const kids = root.asArray(n ? n.children : null);
        for (let i = 0; i < kids.length; i++)
            root.collectIds(kids[i], out);
    }

    function findDocNode(current: var, nodeId: string): var {
        if (!current || typeof current !== "object")
            return null;
        if (current.id !== undefined && String(current.id) === nodeId)
            return current;
        const kids = root.asArray(current.children);
        for (let i = 0; i < kids.length; i++) {
            const found = root.findDocNode(kids[i], nodeId);
            if (found)
                return found;
        }
        return null;
    }

    function nodeTypeOf(nodeId: string): string {
        const reg = root._registry[nodeId];
        if (reg)
            return String(reg.type);
        const doc = root.composition;
        const node = doc && doc.root ? root.findDocNode(doc.root, nodeId) : null;
        return node && node.type !== undefined ? String(node.type) : "";
    }

    function docNumberProp(nodeId: string, field: string, fallback: real): real {
        const doc = root.composition;
        const node = doc && doc.root ? root.findDocNode(doc.root, nodeId) : null;
        const v = node && node.props ? Number(node.props[field]) : NaN;
        return isFinite(v) ? v : fallback;
    }

    // Truthful reconstruction: destroy the old tree, clear registries and
    // events, then expose loading/ready/failed for the current document
    // only. Stale async callbacks are ignored via _expectedIds.
    function rebuild(): void {
        root._generation++;
        root.checkpointController.reset();
        if (root._rootNode) {
            // Detach synchronously so the old tree leaves the visual (and
            // inspection) hierarchy at once; destroy() alone is deferred.
            root._rootNode.parent = null;
            root._rootNode.destroy();
            root._rootNode = null;
        }
        root._registry = {};
        root._expectedIds = {};
        root._failures = [];
        root._flatControls = [];
        root._flatActions = [];
        root._eventSequence = 0;
        root._expectedNodes = 0;
        root._status = "loading";
        root._storyError = "";
        const doc = root.composition;
        if (!doc || !doc.root)
            return;
        const ids = [];
        root.collectIds(doc.root, ids);
        for (let i = 0; i < ids.length; i++)
            root._expectedIds[ids[i]] = true;
        root._expectedNodes = root.countNodes(doc.root);
        const node = nodeFactory.createObject(treeHost,
            { node: doc.root, previewRoot: root, generation: root._generation,
                integrationController: root.checkpointController });
        if (!node) {
            root.failNode(String(doc.root.id ?? "<missing>"), String(doc.root.type ?? "<missing>"),
                "failed to create root node", root._generation);
            return;
        }
        root._rootNode = node;
    }

    function registerNode(nodeId: string, nodeType: string, item: var, generation: int): void {
        if (generation !== root._generation)
            return;
        if (!Object.prototype.hasOwnProperty.call(root._expectedIds, nodeId))
            return;
        root._registry[nodeId] = { type: nodeType, item: item };
        root.refreshObservability();
        root.maybeReady();
    }

    function failNode(nodeId: string, nodeType: string, reason: string, generation: int): void {
        if (generation !== root._generation)
            return;
        if (root._expectedNodes <= 0)
            return;
        if (!Object.prototype.hasOwnProperty.call(root._expectedIds, nodeId))
            return;
        const message = "node \"" + nodeId + "\" of type \"" + nodeType + "\": " + reason;
        root._failures.push({ nodeId: nodeId, type: nodeType, message: message });
        if (root._failures.length === 1)
            root._storyError = message;
        root._status = "failed";
        root.refreshObservability();
        root.maybeReady();
    }

    function registeredCount(): int {
        return Object.keys(root._registry).length;
    }

    function maybeReady(): void {
        if (root._expectedNodes <= 0)
            return;
        if (root.registeredCount() + root._failures.length < root._expectedNodes)
            return;
        root._status = root._failures.length > 0 ? "failed" : "ready";
    }

    // Depth-first in document order so control/action indexes are stable.
    // Reads each adapter's existing option model; nothing is reinterpreted.
    function refreshObservability(): void {
        const doc = root.composition;
        if (!doc || !doc.root) {
            root._flatControls = [];
            root._flatActions = [];
            return;
        }
        const ids = [];
        root.collectIds(doc.root, ids);
        const groups = [];
        const acts = [];
        for (let i = 0; i < ids.length; i++) {
            const reg = root._registry[ids[i]];
            if (!reg || !reg.item)
                continue;
            const itemControls = root.asArray(reg.item.controls);
            for (let g = 0; g < itemControls.length; g++)
                groups.push({ nodeId: ids[i], label: itemControls[g].label, options: itemControls[g].options });
            const itemActions = root.asArray(reg.item.actions);
            for (let a = 0; a < itemActions.length; a++) {
                const action = itemActions[a];
                const label = (action && action.text !== undefined) ? String(action.text) : String(a);
                acts.push({ nodeId: ids[i], label: label, action: action });
            }
        }
        root._flatControls = groups;
        root._flatActions = acts;
    }

    // Node events carry their stable node ID. Intent and container events
    // written against component-specific names are canonicalized to the
    // descriptor event before recording (the raw name survives in
    // payload.rawIntent), then matched against the document links. Stale
    // generations and unknown IDs are dropped: only the current tree
    // speaks. Routing is one hop deep: an action that itself emits a
    // routable intent records that intent but does not re-route, so a
    // cyclic document cannot recurse. Ordinary records carry origin
    // "component", route records "route", direct flow injection "injected".
    property bool _routing: false

    // Generation arrives untyped: QML coerces a missing typed int to 0,
    // which would trip the staleness check for every internal caller, so
    // the fifth argument stays var and missing means "current tree".
    // Origin is additive and defaults to "component".
    function recordNodeEvent(nodeId: string, kind: string, name: string, payload: var, generation: var, origin: var): var {
        if (generation !== undefined && generation !== root._generation)
            return null;
        if (!Object.prototype.hasOwnProperty.call(root._expectedIds, nodeId))
            return null;
        const nodeType = root.nodeTypeOf(nodeId);
        const raw = String(name);
        let eventName = raw;
        let data = payload !== undefined && payload !== null ? payload : {};
        let canonical = "";
        if (kind === "intent" || kind === "event") {
            canonical = root.canonicalEvent(nodeType, raw);
            if (canonical !== "") {
                if (canonical !== raw)
                    data.rawIntent = raw;
                eventName = canonical;
            }
        }
        root._eventSequence++;
        const record = {
            sequence: root._eventSequence,
            kind: kind,
            name: eventName,
            payload: data,
            storyKey: root.storyKey,
            nodeId: nodeId,
            origin: origin !== undefined ? String(origin) : "component"
        };
        root.eventRecorded(record);
        if (canonical !== "" && !root._routing) {
            root._routing = true;
            root.routeLinks(nodeId, canonical);
            root._routing = false;
        }
        return record;
    }

    // Safe named links: exactly {from:{node,event},to:{node,action}}. Only
    // a real event from a registered current-generation node reaches a
    // declared action on a registered current-generation target. Each hop
    // records one route event carrying both identities. No args, property
    // paths, expressions, or code cross this boundary.
    function routeLinks(sourceId: string, eventName: string): void {
        const links = root.asArray(root.composition ? root.composition.links : null);
        for (let i = 0; i < links.length; i++) {
            const link = links[i];
            const from = link ? link.from : null;
            const to = link ? link.to : null;
            if (!from || !to)
                continue;
            if (String(from.node) !== sourceId || String(from.event) !== eventName)
                continue;
            const targetId = String(to.node);
            const actionName = String(to.action);
            const reg = root._registry[targetId];
            if (!reg || !reg.item)
                continue;
            if (root.implementedActions(String(reg.type)).indexOf(actionName) < 0)
                continue;
            if (!root.invokeNodeAction(targetId, actionName))
                continue;
            root._eventSequence++;
            root.eventRecorded({
                sequence: root._eventSequence,
                kind: "route",
                name: eventName + "->" + actionName,
                payload: {
                    from: { node: sourceId, event: eventName },
                    to: { node: targetId, action: actionName }
                },
                storyKey: root.storyKey,
                nodeId: sourceId,
                targetNodeId: targetId,
                origin: "route"
            });
        }
    }

    // Named action entry point for links and tests. Returns false unless a
    // registered current-generation node implements the declared action.
    function invokeNodeAction(nodeId: string, actionName: string): bool {
        const reg = root._registry[nodeId];
        if (!reg || !reg.item)
            return false;
        const nodeType = String(reg.type);
        if (root.implementedActions(nodeType).indexOf(actionName) < 0)
            return false;
        if (!root.runNamedAction(nodeId, nodeType, reg.item, actionName))
            return false;
        root.recordNodeEvent(nodeId, "action", actionName, {});
        return true;
    }

    // Every declared descriptor action lands on a real component route:
    // public functions, honest state writes, or the container adapters'
    // own open state. Resets restore the document's initial value.
    function runNamedAction(nodeId: string, nodeType: string, item: var, actionName: string): bool {
        switch (nodeType) {
        case "text-field":
            if (actionName === "clear") {
                item.clear();
                return true;
            }
            if (actionName === "focus") {
                item.forceActiveFocus();
                return true;
            }
            return false;
        case "checkbox":
            if (actionName === "toggle") {
                item.flip();
                return true;
            }
            if (actionName === "check") {
                item.indeterminate = false;
                item.checked = true;
                return true;
            }
            if (actionName === "uncheck") {
                item.indeterminate = false;
                item.checked = false;
                return true;
            }
            return false;
        case "switch":
            if (actionName === "toggle") {
                item.flip();
                return true;
            }
            return false;
        case "radio":
            if (actionName === "select") {
                item.select();
                return true;
            }
            return false;
        case "slider":
            if (actionName === "reset") {
                const initial = root.docNumberProp(nodeId, "value", 50);
                item.compositionValue = Math.min(100, Math.max(0, initial)) / 100;
                item.hasCompositionValue = true;
                return true;
            }
            return false;
        case "segmented":
            if (actionName === "reset") {
                item.select(Math.round(root.docNumberProp(nodeId, "selected", 0)));
                return true;
            }
            return false;
        case "spin-box":
            if (actionName === "increment") {
                item.stepUp();
                return true;
            }
            if (actionName === "decrement") {
                item.stepDown();
                return true;
            }
            if (actionName === "reset") {
                item.value = root.docNumberProp(nodeId, "value", Number(item.value));
                return true;
            }
            return false;
        case "menu":
        case "shell-border-rollout":
            if (actionName === "open") {
                item.setContainerOpen(true);
                return true;
            }
            if (actionName === "close") {
                item.setContainerOpen(false);
                return true;
            }
            if (actionName === "toggle") {
                item.toggleContainer();
                return true;
            }
            return false;
        default:
            return false;
        }
    }

    // Shared flow bridge (workbench bead 1q6.2): the same direct flow*
    // method names Preview exposes; composition requires the stable node
    // ID. Reset stays the existing resetGeneration/rebuild route.
    IntegrationBridge { id: flowBridge }

    // Static descriptor event allowlist, mirroring
    // workbench/composition-types.json. Only the node type crosses from the
    // document; nothing else is derived from document text.
    function descriptorEvents(nodeType: string): var {
        switch (nodeType) {
        case "text-field":
            return ["accepted", "changed"];
        case "checkbox":
        case "switch":
            return ["toggled"];
        case "radio":
            return ["selected"];
        case "slider":
        case "segmented":
        case "spin-box":
            return ["changed"];
        case "menu":
            return ["opened", "closed", "selected"];
        case "shell-border-rollout":
            return ["opened", "closed"];
        default:
            return [];
        }
    }

    function flowNodeItem(nodeId: string): var {
        const reg = root._registry[nodeId];
        return (reg && reg.item) ? reg.item : null;
    }

    function flowNodeIntegration(nodeId: string): var {
        const item = root.flowNodeItem(nodeId);
        if (!item || item.integration === undefined || item.integration === null)
            return null;
        return item.integration;
    }

    // Layout nodes expose identity only and no fake capabilities; leaves
    // and the rollout adapter answer through their integration object.
    function flowCapabilities(nodeId): var {
        const id = String(nodeId ?? "");
        const nodeType = root.nodeTypeOf(id);
        const item = root.flowNodeItem(id);
        const integration = root.flowNodeIntegration(id);
        let observables = [];
        let textDriver = false;
        let keys = [];
        if (nodeType === "text-field" || nodeType === "checkbox"
            || nodeType === "shell-border-rollout") {
            observables = (integration && integration.observables)
                ? Object.keys(integration.observables) : [];
            textDriver = integration ? typeof integration.writeText === "function" : false;
            keys = (integration && Array.isArray(integration.keys)) ? integration.keys : [];
        }
        return {
            nodeId: id,
            type: nodeType,
            events: root.descriptorEvents(nodeType),
            actions: root.implementedActions(nodeType),
            controls: item ? flowBridge.canonicalControls(flowBridge.controlGroupsOf(item)) : [],
            observables: observables,
            textDriver: textDriver,
            keys: keys,
            checkpoints: (integration && Array.isArray(integration.checkpoints)) ? integration.checkpoints : [],
            idle: integration && typeof integration.idle === "function" ? integration.idle() : String(root.storyStatus) === "ready"
        };
    }

    // Read-only availability walk over relevant flow step shapes. Returns
    // every unavailable capability without mutating the target.
    function flowDescribeStep(step, index): string {
        if (!step || typeof step !== "object")
            return "step " + index + ": not an object";
        const type = String(step.type ?? "");
        if (type === "reset" || type === "awaitIdle" || type === "capture")
            return "";
        if (type === "armCheckpoint" || type === "awaitCheckpoint" || type === "continueCheckpoint") {
            const checkpointNode = step.node !== undefined ? String(step.node ?? "") : root.nodeForCheckpoint(String(step.name ?? ""));
            if (checkpointNode === "")
                return "step " + index + " (" + type + "): undeclared checkpoint '" + String(step.name ?? "") + "'";
            const checkpointCaps = root.flowCapabilities(checkpointNode);
            if (checkpointCaps.checkpoints.indexOf(String(step.name ?? "")) < 0)
                return "step " + index + " (" + type + "): node '" + checkpointNode + "' declares no checkpoint '" + String(step.name ?? "") + "'";
            return "";
        }
        const nodeId = String(step.node ?? "");
        if (nodeId === "")
            return "step " + index + " (" + type + "): missing node";
        const caps = root.flowCapabilities(nodeId);
        if (caps.type === "")
            return "step " + index + " (" + type + "): unknown node '" + nodeId + "'";
        switch (type) {
        case "emit": {
            const event = String(step.event ?? "");
            if (caps.events.indexOf(event) < 0)
                return "step " + index + " (emit): node '" + nodeId
                    + "' declares no event '" + event + "'";
            return "";
        }
        case "action": {
            const name = String(step.name ?? "");
            if (caps.actions.indexOf(name) < 0)
                return "step " + index + " (action): node '" + nodeId
                    + "' declares no action '" + name + "'";
            return "";
        }
        case "control": {
            const groups = flowBridge.controlGroupsOf(root.flowNodeItem(nodeId));
            const want = String(step.group ?? "");
            const gi = flowBridge.findGroupIndex(groups, want);
            if (gi < 0)
                return "step " + index + " (control): node '" + nodeId
                    + "' has no control '" + want + "'";
            if (flowBridge.findOptionIndex(groups[gi].options, String(step.option ?? "")) < 0)
                return "step " + index + " (control): node '" + nodeId + "' control '"
                    + want + "' has no option '" + String(step.option ?? "") + "'";
            return "";
        }
        case "write": {
            if (!caps.textDriver)
                return "step " + index + " (write): node '" + nodeId + "' has no text driver";
            if (typeof step.text !== "string" || step.text.length > flowBridge.maxTextLength)
                return "step " + index + " (write): text exceeds "
                    + flowBridge.maxTextLength + " characters";
            return "";
        }
        case "key": {
            if (caps.keys.indexOf(String(step.key ?? "")) < 0)
                return "step " + index + " (key): node '" + nodeId + "' supports no key '"
                    + String(step.key ?? "") + "'";
            return "";
        }
        case "expect": {
            if (caps.observables.indexOf(String(step.observable ?? "")) < 0)
                return "step " + index + " (expect): node '" + nodeId
                    + "' exposes no observable '" + String(step.observable ?? "") + "'";
            return "";
        }
        case "expectEvent": {
            if (caps.events.indexOf(String(step.event ?? "")) < 0)
                return "step " + index + " (expectEvent): node '" + nodeId
                    + "' declares no event '" + String(step.event ?? "") + "'";
            return "";
        }
        default:
            return "step " + index + " (" + (type || "<missing>") + "): unsupported in this bridge";
        }
    }

    function flowPreflight(steps): var {
        const missing = [];
        const list = flowBridge.asArray(steps);
        for (let i = 0; i < list.length; i++) {
            const problem = root.flowDescribeStep(list[i], i);
            if (problem !== "")
                missing.push(problem);
        }
        return missing;
    }

    function nodeForCheckpoint(name: string): string {
        const ids = Object.keys(root._registry);
        for (let i = 0; i < ids.length; i++) {
            const caps = root.flowCapabilities(ids[i]);
            if (caps.checkpoints.indexOf(name) >= 0)
                return ids[i];
        }
        return "";
    }

    function checkpointNode(step): string {
        if (step && step.node !== undefined)
            return String(step.node ?? "");
        return root.nodeForCheckpoint(String(step ? step.name ?? "" : ""));
    }

    function flowArmCheckpoint(step): var {
        const nodeId = root.checkpointNode(step);
        if (nodeId === "")
            return flowBridge.failResult("undeclared checkpoint '" + String(step.name ?? "") + "'");
        const caps = root.flowCapabilities(nodeId);
        const name = String(step.name ?? "");
        if (caps.checkpoints.indexOf(name) < 0)
            return flowBridge.failResult("node '" + nodeId + "' declares no checkpoint '" + name + "'");
        return root.checkpointController.arm(name);
    }

    function flowCheckpointReached(step): bool {
        return root.checkpointController.hasReached(String(step.name ?? ""));
    }

    function flowContinueCheckpoint(step): var {
        return root.checkpointController.continueCheckpoint(String(step.name ?? ""));
    }

    function flowIdle(step): bool {
        if (String(root.storyStatus) !== "ready")
            return false;
        const nodeId = step && step.node !== undefined ? String(step.node ?? "") : "";
        if (nodeId !== "") {
            const integration = root.flowNodeIntegration(nodeId);
            return integration && typeof integration.idle === "function" ? integration.idle() === true : true;
        }
        const ids = Object.keys(root._registry);
        for (let i = 0; i < ids.length; i++) {
            const integration = root.flowNodeIntegration(ids[i]);
            if (integration && typeof integration.idle === "function" && integration.idle() !== true)
                return false;
        }
        return true;
    }

    // Direct declared-event injection: verifies the descriptor/runtime
    // declaration for that node, then records through recordNodeEvent --
    // the existing one-hop link and route evidence path -- with origin
    // "injected", exactly as a real canonical event would route.
    function flowEmit(nodeId, event, payload): var {
        const id = String(nodeId ?? "");
        const name = String(event ?? "");
        if (root.descriptorEvents(root.nodeTypeOf(id)).indexOf(name) < 0)
            return null;
        return root.recordNodeEvent(id, "event", name,
            (payload !== undefined && payload !== null) ? payload : {}, undefined, "injected");
    }

    function flowInvokeAction(nodeId, actionName): bool {
        return root.invokeNodeAction(String(nodeId ?? ""), String(actionName ?? ""));
    }

    // Canonicalized labelled-control execution on exactly the addressed
    // node instance, through the same set/call option shape the
    // flattened index path applies.
    function flowApplyControl(nodeId, control, option): bool {
        const id = String(nodeId ?? "");
        const item = root.flowNodeItem(id);
        if (!item)
            return false;
        const groups = flowBridge.controlGroupsOf(item);
        const wantControl = flowBridge.canonicalName(String(control ?? ""));
        const wantOption = flowBridge.canonicalName(String(option ?? ""));
        const gi = flowBridge.findGroupIndex(groups, String(control ?? ""));
        if (gi < 0)
            return false;
        const options = groups[gi].options;
        const oi = flowBridge.findOptionIndex(options, String(option ?? ""));
        if (oi < 0)
            return false;
        const chosen = options[oi];
        if (chosen.call !== undefined)
            item[chosen.call]();
        else
            for (const key in chosen.set)
                item[key] = chosen.set[key];
        root.recordNodeEvent(id, "control", wantControl + "/" + wantOption,
            { control: wantControl, option: wantOption });
        return true;
    }

    function flowWrite(nodeId, text): bool {
        const id = String(nodeId ?? "");
        if (root.nodeTypeOf(id) !== "text-field")
            return false;
        const integration = root.flowNodeIntegration(id);
        if (!integration || typeof integration.writeText !== "function")
            return false;
        if (typeof text !== "string" || text.length > flowBridge.maxTextLength)
            return false;
        return integration.writeText(text) === true;
    }

    function flowPressKey(nodeId, key): bool {
        const id = String(nodeId ?? "");
        if (root.nodeTypeOf(id) !== "text-field")
            return false;
        const integration = root.flowNodeIntegration(id);
        const want = String(key ?? "");
        const keys = (integration && Array.isArray(integration.keys)) ? integration.keys : [];
        if (keys.indexOf(want) < 0)
            return false;
        if (!integration || typeof integration.pressKey !== "function")
            return false;
        return integration.pressKey(want) === true;
    }

    function flowRead(nodeId, name): var {
        const id = String(nodeId ?? "");
        const want = String(name ?? "");
        const integration = root.flowNodeIntegration(id);
        if (!integration || !integration.observables
            || typeof integration.observables[want] !== "function")
            return flowBridge.failResult("node '" + id + "' exposes no observable '" + want + "'");
        try {
            return flowBridge.okResult(integration.observables[want]());
        } catch (e) {
            return flowBridge.failResult("observable '" + want + "' on node '" + id + "' failed: " + e);
        }
    }

    // Routes a flattened control index to exactly its node instance.
    function applyControl(groupIndex: int, optionIndex: int): bool {
        const groups = root._flatControls;
        if (groupIndex < 0 || groupIndex >= groups.length)
            return false;
        const entry = groups[groupIndex];
        const options = entry.options;
        if (!options || optionIndex < 0 || optionIndex >= options.length)
            return false;
        const reg = root._registry[entry.nodeId];
        if (!reg || !reg.item)
            return false;
        const option = options[optionIndex];
        if (option.call !== undefined)
            reg.item[option.call]();
        else
            for (const key in option.set)
                reg.item[key] = option.set[key];
        root.recordNodeEvent(entry.nodeId, "control", entry.label + "/" + option.label,
            { group: groupIndex, option: optionIndex });
        return true;
    }

    function triggerAction(index: int): bool {
        const list = root._flatActions;
        if (index < 0 || index >= list.length)
            return false;
        const entry = list[index];
        const reg = root._registry[entry.nodeId];
        if (!reg || !reg.item)
            return false;
        const action = entry.action;
        if (action && typeof action.trigger === "function")
            action.trigger();
        else if (action && typeof action.triggered === "function")
            action.triggered();
        root.recordNodeEvent(entry.nodeId, "action", entry.label, { index: index });
        return true;
    }

    function inspect(visibleOnly: bool): var {
        return {
            "scene": "composition/" + root.storyKey,
            "width": root.width,
            "height": root.height,
            "tree": Inspect.describe(treeHost, visibleOnly)
        };
    }

    function dumpTree(): void {
        const data = root.inspect(true);
        root.inspectionReady(data);
        console.info("QSM_INSPECT " + JSON.stringify(data));
    }
}
