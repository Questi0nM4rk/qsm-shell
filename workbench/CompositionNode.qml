pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

// One node of a composition document. Leaves load their real component adapter
// through the fixed allowlist below; layouts place child nodes through
// Repeaters of child Loaders. The menu container hosts the real qsm-shell
// Menu with composed children in document order, and shell-border-rollout
// owns the real ScenePointer, ShellBorder host, and Rollout relationship
// with composed children inside the Rollout. Children resolve through the
// fixed literal "CompositionNode.qml" (never document text), because the
// engine rejects any static instantiation cycle, even mutual between files.
// Unknown types fail truthfully via the preview instead of being
// approximated.
Item {
    id: nodeRoot

    property var node: null
    property var previewRoot: null
    property var integrationController: null
    // Build generation; stale async callbacks from a detached tree carry
    // the old one and are ignored by the preview.
    property int generation: 0

    readonly property string nodeId: nodeRoot.node && nodeRoot.node.id !== undefined
        ? String(nodeRoot.node.id) : ""
    readonly property string nodeType: nodeRoot.node && nodeRoot.node.type !== undefined
        ? String(nodeRoot.node.type) : ""
    readonly property var nodeProps: nodeRoot.node && nodeRoot.node.props !== undefined
        ? nodeRoot.node.props : ({})
    readonly property var childNodes: nodeRoot.asArray(
        nodeRoot.node ? nodeRoot.node.children : null)

    readonly property bool isColumn: nodeRoot.nodeType === "column"
    readonly property bool isRow: nodeRoot.nodeType === "row"
    readonly property bool isStack: nodeRoot.nodeType === "stack"
    readonly property bool isLayout: nodeRoot.isColumn || nodeRoot.isRow || nodeRoot.isStack
    readonly property bool isMenu: nodeRoot.nodeType === "menu"
    readonly property bool isShellBorderRollout: nodeRoot.nodeType === "shell-border-rollout"
    readonly property bool isContainer: nodeRoot.isMenu || nodeRoot.isShellBorderRollout
    readonly property bool isLeaf: ["text-field", "checkbox", "switch", "radio", "slider", "segmented", "spin-box"].includes(nodeRoot.nodeType)

    // Layout and container identity for inspection; leaves name the loaded
    // component instead.
    objectName: nodeRoot.isLayout || nodeRoot.isContainer ? nodeRoot.nodeId : ""

    // Tokenized spacing: only existing Style values, never literals.
    function spacingToken(token: string): int {
        switch (token) {
        case "none": return 0;
        case "xs": return Style.space1;
        case "sm": return Style.space2;
        case "md": return Style.space4;
        case "lg": return Style.space6;
        default: return Style.space2;
        }
    }

    readonly property int pad: nodeRoot.spacingToken(String(nodeRoot.nodeProps.padding ?? "none"))
    readonly property int gap: nodeRoot.spacingToken(String(nodeRoot.nodeProps.spacing ?? "sm"))
    readonly property real explicitWidth: nodeRoot.nodeProps.width !== undefined
        ? Number(nodeRoot.nodeProps.width) : -1
    readonly property real explicitHeight: nodeRoot.nodeProps.height !== undefined
        ? Number(nodeRoot.nodeProps.height) : -1

    // Container state. Initial values come from the document props; the
    // declared open/close/toggle actions and the open/side control groups
    // write these, never the production components.
    property bool menuOpen: nodeRoot.nodeProps.open === true
    property bool rolloutOpen: nodeRoot.nodeProps.open === true
    property string rolloutSide: {
        const s = String(nodeRoot.nodeProps.side ?? "right");
        return s === "left" || s === "right" || s === "top" || s === "bottom" ? s : "right";
    }
    readonly property string menuTitle: String(nodeRoot.nodeProps.title ?? "")
    property real rolloutPreviewContentScale: 1
    property bool rolloutInstrumentedOpening: false

    // Per-node observability for containers. Layouts expose nothing; leaves
    // expose their adapter's own model. Options use the same {set,call} shape
    // the preview applies, so controls stay honest instance writes.
    readonly property var controls: nodeRoot.isMenu ? [
        { label: "open", options: [
            { label: "open", set: { menuOpen: true } },
            { label: "closed", set: { menuOpen: false } }
        ] },
        { label: "row", options: [
            { label: "previous", call: "stepPrevious" },
            { label: "next", call: "stepNext" },
            { label: "activate", call: "activateCurrentRow" }
        ] }
    ] : nodeRoot.isShellBorderRollout ? [
        { label: "open", options: [
            { label: "open", set: { rolloutOpen: true } },
            { label: "closed", set: { rolloutOpen: false } }
        ] },
        { label: "side", options: [
            { label: "left", set: { rolloutSide: "left" } },
            { label: "right", set: { rolloutSide: "right" } },
            { label: "top", set: { rolloutSide: "top" } },
            { label: "bottom", set: { rolloutSide: "bottom" } }
        ] }
    ] : []

    readonly property var actions: nodeRoot.isContainer ? [
        { text: "Open", trigger: function() { nodeRoot.setContainerOpen(true); } },
        { text: "Close", trigger: function() { nodeRoot.setContainerOpen(false); } },
        { text: "Toggle", trigger: function() { nodeRoot.toggleContainer(); } }
    ] : []

    // Flow integration contract (workbench bead 1q6.2) for the rollout
    // adapter only: declared events, stable named actions, and semantic
    // observable getters over the adapter's own open state. Layouts and
    // leaves expose nothing here -- layouts carry identity only, leaves
    // answer through their loaded adapter's integration object.
    readonly property var integration: nodeRoot.isShellBorderRollout ? ({
        events: ["opened", "closed"],
        actions: ["open", "close", "toggle"],
            observables: {
                open: () => nodeRoot.rolloutOpen,
                side: () => nodeRoot.rolloutSide,
                contentScale: () => nodeRoot.rolloutPreviewContentScale
            },
            checkpoints: ["rollout.shell-revealed"],
            idle: () => !rolloutCheckpointSequence.running
                && (nodeRoot.rolloutOpen ? rolloutHost.offsetScale <= 0 : !rolloutHost.visible)
        }) : null

    // Inspection and contract-test hooks: the hosted component and border,
    // null for other node types.
    readonly property var containerHost: nodeRoot.isMenu ? menuHost
        : nodeRoot.isShellBorderRollout ? rolloutHost : null
    readonly property var hostBorder: nodeRoot.isShellBorderRollout ? borderHost : null
    readonly property var checkpointAnimation: nodeRoot.isShellBorderRollout ? rolloutCheckpointSequence : null

    function setContainerOpen(value: bool): void {
        if (nodeRoot.isMenu)
            nodeRoot.menuOpen = value;
        else if (nodeRoot.isShellBorderRollout) {
            if (value && !nodeRoot.rolloutOpen && nodeRoot.integrationController
                && nodeRoot.integrationController.isArmed("rollout.shell-revealed")) {
                nodeRoot.startInstrumentedRolloutOpen();
                return;
            }
            if (!value) {
                rolloutCheckpointTimer.stop();
                rolloutCheckpointSequence.stop();
                nodeRoot.rolloutPreviewContentScale = 1;
                nodeRoot.rolloutInstrumentedOpening = false;
            }
            nodeRoot.rolloutOpen = value;
        }
    }

    function toggleContainer(): void {
        if (nodeRoot.isMenu)
            nodeRoot.menuOpen = !nodeRoot.menuOpen;
        else if (nodeRoot.isShellBorderRollout)
            nodeRoot.rolloutOpen = !nodeRoot.rolloutOpen;
    }

    // Real Menu keyboard row semantics, exposed as control calls. They step
    // and activate only genuine ListRows; anything else stays layout
    // content and is skipped by the component itself.
    function stepNext(): void {
        if (nodeRoot.containerHost)
            nodeRoot.containerHost.step(1);
    }

    function stepPrevious(): void {
        if (nodeRoot.containerHost)
            nodeRoot.containerHost.step(-1);
    }

    function activateCurrentRow(): void {
        if (nodeRoot.containerHost)
            nodeRoot.containerHost.activateCurrent();
    }

    function startInstrumentedRolloutOpen(): void {
        rolloutCheckpointTimer.stop();
        rolloutCheckpointSequence.stop();
        nodeRoot.rolloutPreviewContentScale = Motion.microPopScale;
        nodeRoot.rolloutInstrumentedOpening = true;
        rolloutCheckpointSequence.start();
    }

    width: nodeRoot.explicitWidth >= 0 ? nodeRoot.explicitWidth : nodeRoot.implicitWidth
    height: nodeRoot.explicitHeight >= 0 ? nodeRoot.explicitHeight : nodeRoot.implicitHeight
    implicitWidth: nodeRoot.isLeaf ? leafLoader.implicitWidth
        : nodeRoot.isColumn ? columnBox.implicitWidth + nodeRoot.pad * 2
        : nodeRoot.isRow ? rowBox.implicitWidth + nodeRoot.pad * 2
        : nodeRoot.isStack ? stackBox.width + nodeRoot.pad * 2
        : nodeRoot.isMenu ? menuBox.implicitWidth
        : nodeRoot.isShellBorderRollout ? rolloutBox.width : 0
    implicitHeight: nodeRoot.isLeaf ? leafLoader.implicitHeight
        : nodeRoot.isColumn ? columnBox.implicitHeight + nodeRoot.pad * 2
        : nodeRoot.isRow ? rowBox.implicitHeight + nodeRoot.pad * 2
        : nodeRoot.isStack ? stackBox.height + nodeRoot.pad * 2
        : nodeRoot.isMenu ? menuBox.implicitHeight
        : nodeRoot.isShellBorderRollout ? rolloutBox.height : 0

    // Fixed execution allowlist. Only known leaf types return a non-empty
    // marker; layouts and containers return "" so they take the register
    // branch instead of the leaf Loader. Empty means unsupported here.
    function leafSource(): string {
        switch (nodeRoot.nodeType) {
        case "text-field":
        case "checkbox":
        case "switch":
        case "radio":
        case "slider":
        case "segmented":
        case "spin-box":
            return nodeRoot.nodeType;
        default:
            return "";
        }
    }

    function leafComponent(): var {
        switch (nodeRoot.nodeType) {
        case "text-field": return textFieldLeaf;
        case "checkbox": return checkboxLeaf;
        case "switch": return switchLeaf;
        case "radio": return radioLeaf;
        case "slider": return sliderLeaf;
        case "segmented": return segmentedLeaf;
        case "spin-box": return spinBoxLeaf;
        default: return null;
        }
    }

    // Honest initial properties for the fixed adapters above. Width/height
    // apply when the descriptor bounds them; every leaf keeps its story
    // defaults unless the document says otherwise.
    function leafProps(): var {
        const p = nodeRoot.nodeProps;
        const out = { objectName: nodeRoot.nodeId };
        if (p.width !== undefined && isFinite(Number(p.width)))
            out.width = Number(p.width);
        if (p.height !== undefined && isFinite(Number(p.height)))
            out.height = Number(p.height);
        switch (nodeRoot.nodeType) {
        case "text-field": {
            const state = String(p.state ?? "default");
            out.compositionSize = String(p.size ?? "md");
            out.compositionState = state;
            out.compositionLabel = String(p.label ?? "");
            out.compositionText = String(p.text ?? "");
            out.hasCompositionText = true;
            out.enabled = state !== "disabled";
            break;
        }
        case "checkbox":
        case "radio":
        case "switch":
            out.hasCompositionChecked = true;
            out.compositionChecked = p.checked === true;
            out.labelText = String(p.label ?? "");
            break;
        case "slider": {
            const v = Number(p.value ?? 50);
            const clamped = Math.min(100, Math.max(0, isFinite(v) ? v : 50));
            out.hasCompositionValue = true;
            out.compositionValue = clamped / 100;
            out.compositionOrientation = String(p.orientation ?? "horizontal") === "vertical"
                ? Qt.Vertical : Qt.Horizontal;
            out.labelText = String(p.label ?? "");
            break;
        }
        case "segmented": {
            const s = Number(p.selected ?? 0);
            out.compositionIndex = isFinite(s) ? Math.round(s) : 0;
            out.labelText = String(p.label ?? "");
            break;
        }
        case "spin-box": {
            const v = Number(p.value ?? 0);
            const vv = isFinite(v) ? v : 0;
            out.value = vv;
            out.from = Math.min(0, vv);
            out.to = Math.max(12, vv);
            break;
        }
        }
        return out;
    }

    Loader {
        id: leafLoader
        visible: nodeRoot.isLeaf
        active: nodeRoot.isLeaf
        onLoaded: {
            const props = nodeRoot.leafProps();
            for (const key in props)
                item[key] = props[key];
            if (item && "eventRecorder" in item)
                item.eventRecorder = (kind, name, payload) => nodeRoot.previewRoot.recordNodeEvent(
                    nodeRoot.nodeId, kind, name, payload, nodeRoot.generation);
            nodeRoot.previewRoot.registerNode(nodeRoot.nodeId, nodeRoot.nodeType, item,
                nodeRoot.generation);
        }
        onStatusChanged: {
            if (status === Loader.Error)
                nodeRoot.previewRoot.failNode(nodeRoot.nodeId, nodeRoot.nodeType,
                    "failed to load " + nodeRoot.leafSource(), nodeRoot.generation);
        }
    }

    component TextFieldLeaf: TextField {
        id: textLeaf
        property string compositionSize: ""
        property string compositionState: ""
        property string compositionLabel: ""
        property string compositionText: ""
        property bool hasCompositionText: false
        property var eventRecorder: null
        size: compositionSize !== "" ? compositionSize : "md"
        enabled: compositionState !== "disabled"
        failed: compositionState === "error"
        placeholder: compositionLabel
        text: hasCompositionText ? compositionText : ""
        onAccepted: if (eventRecorder) eventRecorder("intent", "accepted", { text: text })
        onEdited: text => { if (eventRecorder) eventRecorder("intent", "edited", { text }) }
        readonly property var integration: ({ events: ["accepted", "changed"], actions: ["clear", "focus"], observables: { text: () => textLeaf.text, enabled: () => textLeaf.enabled, focused: () => textLeaf.focused, failed: () => textLeaf.failed, readonly: () => textLeaf.readOnly }, keys: ["Enter", "Escape"], writeText: value => { if (typeof value !== "string" || value.length > 200 || !textLeaf.enabled || textLeaf.readOnly) return false; textLeaf.text = value; return true; }, pressKey: key => { if (key === "Enter") return textLeaf.accept(); if (key === "Escape") { textLeaf.escaped(); return true; } return false; }, runAction: name => { if (name === "clear") { textLeaf.clear(); return true; } if (name === "focus") { textLeaf.forceActiveFocus(); return true; } return false; } })
        readonly property var controls: [
            { label: "size", options: [{ label: "sm", set: { size: "sm" } }, { label: "md", set: { size: "md" } }, { label: "lg", set: { size: "lg" } }] },
            { label: "state", options: [{ label: "enabled", set: { enabled: true } }, { label: "disabled", set: { enabled: false } }] }
        ]
    }
    component CheckboxLeaf: Checkbox {
        id: checkboxLeafRoot
        property bool hasCompositionChecked: false
        property bool compositionChecked: false
        property string labelText: ""
        property var eventRecorder: null
        checked: hasCompositionChecked ? compositionChecked : false
        onToggleRequested: nextChecked => {
            checked = nextChecked;
            if (eventRecorder)
                eventRecorder("intent", "toggle", { checked });
        }
        readonly property var controls: [{ label: "checked", options: [{ label: "checked", set: { checked: true } }, { label: "unchecked", set: { checked: false } }] }]
        readonly property var actions: [{ text: "Toggle", trigger: function() { checkboxLeafRoot.flip(); } }]
    }
    component SwitchLeaf: Switch { property bool hasCompositionChecked: false; property bool compositionChecked: false; property string labelText: ""; checked: hasCompositionChecked ? compositionChecked : false }
    component RadioLeaf: Radio {
        property bool hasCompositionChecked: false
        property bool compositionChecked: false
        property string labelText: ""
        property var eventRecorder: null
        checked: hasCompositionChecked ? compositionChecked : false
        onSelectionRequested: {
            checked = true;
            if (eventRecorder)
                eventRecorder("intent", "selection", {});
        }
    }
    component SliderLeaf: Slider { property bool hasCompositionValue: false; property real compositionValue: 0; property int compositionOrientation: Qt.Horizontal; property string labelText: ""; value: hasCompositionValue ? compositionValue : 0; orientation: compositionOrientation; Layout.preferredWidth: orientation === Qt.Vertical ? implicitWidth : 240; Layout.preferredHeight: orientation === Qt.Vertical ? 240 : implicitHeight }
    component SegmentedLeaf: Segmented {
        property int compositionIndex: 0
        property string labelText: ""
        property var eventRecorder: null
        currentIndex: compositionIndex
        options: ["One", "Two", "Three"]
        onSelected: index => { if (eventRecorder) eventRecorder("intent", "selected", { index }); }
    }
    component SpinBoxLeaf: SpinBox { property bool hasCompositionValue: false; property real compositionValue: 0; value: hasCompositionValue ? compositionValue : 0 }

    // Inline component types are not Component objects. These fixed wrappers
    // are the only values assigned to Loader.sourceComponent.
    Component { id: textFieldLeaf; TextFieldLeaf {} }
    Component { id: checkboxLeaf; CheckboxLeaf {} }
    Component { id: switchLeaf; SwitchLeaf {} }
    Component { id: radioLeaf; RadioLeaf {} }
    Component { id: sliderLeaf; SliderLeaf {} }
    Component { id: segmentedLeaf; SegmentedLeaf {} }
    Component { id: spinBoxLeaf; SpinBoxLeaf {} }

    Column {
        id: columnBox
        visible: nodeRoot.isColumn
        x: nodeRoot.pad
        y: nodeRoot.pad
        spacing: nodeRoot.gap
        Repeater {
            model: nodeRoot.isColumn ? nodeRoot.childNodes : []
            delegate: Loader {
                required property var modelData
                property var childNode: modelData
                active: true
                Component.onCompleted: nodeRoot.loadChild(this, childNode)
                onStatusChanged: nodeRoot.checkChild(this, childNode)
            }
        }
    }

    Row {
        id: rowBox
        visible: nodeRoot.isRow
        x: nodeRoot.pad
        y: nodeRoot.pad
        spacing: nodeRoot.gap
        Repeater {
            model: nodeRoot.isRow ? nodeRoot.childNodes : []
            delegate: Loader {
                required property var modelData
                property var childNode: modelData
                active: true
                Component.onCompleted: nodeRoot.loadChild(this, childNode)
                onStatusChanged: nodeRoot.checkChild(this, childNode)
            }
        }
    }

    // A stack overlaps its children at the padding origin.
    Item {
        id: stackBox
        visible: nodeRoot.isStack
        x: nodeRoot.pad
        y: nodeRoot.pad
        width: childrenRect.width
        height: childrenRect.height
        Repeater {
            model: nodeRoot.isStack ? nodeRoot.childNodes : []
            delegate: Loader {
                required property var modelData
                x: 0
                y: 0
                property var childNode: modelData
                active: true
                Component.onCompleted: nodeRoot.loadChild(this, childNode)
                onStatusChanged: nodeRoot.checkChild(this, childNode)
            }
        }
    }

    // The menu container: the real qsm-shell Menu as content host.
    // Arbitrary valid composition children load in document order through
    // the same fixed child source as layouts. Non-ListRow children are
    // honest layout content: Menu's own keyboard row registry only ever
    // picks up real ListRows, and nothing here fakes it. Title renders as
    // a plain header; open owns visibility and the opened/closed events.
    Column {
        id: menuBox
        visible: nodeRoot.isMenu
        spacing: nodeRoot.gap
        Prose {
            visible: nodeRoot.menuTitle !== ""
            role: "label"
            text: nodeRoot.menuTitle
        }
        Menu {
            id: menuHost
            objectName: nodeRoot.nodeId + "-host"
            visible: nodeRoot.menuOpen
            width: nodeRoot.explicitWidth >= 0 ? nodeRoot.explicitWidth
                : Math.max(0, nodeRoot.menuContentWidth())
            height: nodeRoot.explicitHeight >= 0 ? nodeRoot.explicitHeight
                : Math.max(0, nodeRoot.menuContentHeight())
            Accessible.name: nodeRoot.menuTitle
            onActivated: index => nodeRoot.previewRoot.recordNodeEvent(nodeRoot.nodeId,
                "intent", "selected", { index: index }, nodeRoot.generation)
            Repeater {
                id: menuRepeater
                model: nodeRoot.isMenu ? nodeRoot.childNodes : []
                delegate: Loader {
                    required property var modelData
                    property var childNode: modelData
                    active: true
                    Component.onCompleted: nodeRoot.loadChild(this, childNode)
                    onStatusChanged: nodeRoot.checkChild(this, childNode)
                }
            }
        }
    }

    // The specialized shell integration: one preview-owned ScenePointer on
    // the ancestor, the real ShellBorder host, and the real Rollout
    // relationship, with arbitrary valid composition children inside the
    // Rollout in document order. Side maps to the Rollout edge, open to
    // shouldBeActive, explicit width/height to the adapter, and the content
    // column uses the shell spacing token scale. A closed rollout is
    // honestly empty: the Rollout reports zero size until it reveals.
    Item {
        id: rolloutBox
        visible: nodeRoot.isShellBorderRollout
        width: nodeRoot.explicitWidth >= 0 ? nodeRoot.explicitWidth : rolloutHost.implicitWidth
        height: nodeRoot.explicitHeight >= 0 ? nodeRoot.explicitHeight : rolloutHost.implicitHeight

        ScenePointer {
            id: scenePointer
        }

        ShellBorder {
            id: borderHost
            anchors.fill: parent
            pointer: scenePointer
        }

        Rollout {
            id: rolloutHost
            host: borderHost
            rolloutId: nodeRoot.nodeId
            edges: [nodeRoot.rolloutSide]
            tier: "small"
            shouldBeActive: nodeRoot.rolloutOpen
            settleContent: !nodeRoot.rolloutInstrumentedOpening
            x: !rolloutHost.revealHorizontal ? 0
                : nodeRoot.rolloutSide === "right" ? rolloutBox.width - rolloutHost.width : 0
            y: rolloutHost.revealHorizontal ? 0
                : nodeRoot.rolloutSide === "bottom" ? rolloutBox.height - rolloutHost.height : 0

            Column {
                spacing: Style.space2
                scale: nodeRoot.rolloutPreviewContentScale
                transformOrigin: Item.Center
                Repeater {
                    id: rolloutRepeater
                    model: nodeRoot.isShellBorderRollout ? nodeRoot.childNodes : []
                    delegate: Loader {
                        required property var modelData
                        property var childNode: modelData
                        active: true
                        Component.onCompleted: nodeRoot.loadChild(this, childNode)
                        onStatusChanged: nodeRoot.checkChild(this, childNode)
                    }
                }
            }
        }
        SequentialAnimation {
            id: rolloutCheckpointSequence
            PropertyAction { target: nodeRoot; property: "rolloutOpen"; value: true }
            PauseAnimation { duration: Motion.revealSmall }
            ScriptAction { script: rolloutCheckpointTimer.restart() }
            // Qt applies pause() on the next animation scheduler turn. This
            // non-visual guard keeps that turn outside the content settle.
            PauseAnimation { duration: 50 }
            NumberAnimation {
                target: nodeRoot
                property: "rolloutPreviewContentScale"
                to: 1
                duration: Motion.microPopDuration
                easing.type: Motion.emphasizedEasing
            }
            onFinished: nodeRoot.rolloutInstrumentedOpening = false
        }
        Timer {
            id: rolloutCheckpointTimer
            interval: 0
            repeat: false
            onTriggered: {
                if (nodeRoot.integrationController)
                    nodeRoot.integrationController.checkpoint("rollout.shell-revealed", rolloutCheckpointSequence);
            }
        }
    }

    // Menu content measures its real children: the widest child sets the
    // host width, stacked heights plus the host spacing set its height.
    // Loaders cross as QQuickItem, so they pass through a var parameter
    // before reading their loaded child.
    function menuChildItem(loader: var): var {
        return loader ? loader.item : null;
    }

    function menuContentWidth(): real {
        let w = 0;
        for (let i = 0; i < menuRepeater.count; i++) {
            const child = nodeRoot.menuChildItem(menuRepeater.itemAt(i));
            if (child)
                w = Math.max(w, Number(child.width) || 0);
        }
        return w;
    }

    function menuContentHeight(): real {
        let h = 0;
        for (let i = 0; i < menuRepeater.count; i++) {
            const child = nodeRoot.menuChildItem(menuRepeater.itemAt(i));
            if (child)
                h += Number(child.height) || 0;
        }
        if (menuRepeater.count > 1)
            h += menuHost.spacing * (menuRepeater.count - 1);
        return h;
    }

    // Child lists crossing createObject/setSource arrive as QVariantList,
    // for which Array.isArray is false. Normalize before use.
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

    // Fixed child source: the literal below is checked in, never derived
    // from document text; only the initial properties come from the node.
    function loadChild(loader: var, child: var): void {
        loader.setSource("CompositionNode.qml",
            { node: child, previewRoot: nodeRoot.previewRoot, generation: nodeRoot.generation,
                integrationController: nodeRoot.integrationController });
    }

    function checkChild(loader: var, child: var): void {
        if (loader.status === Loader.Error)
            nodeRoot.previewRoot.failNode(String(child.id ?? "<missing>"),
                String(child.type ?? "<missing>"), "failed to construct child node",
                nodeRoot.generation);
    }

    Component.onCompleted: {
        if (nodeRoot.isLeaf) {
            leafLoader.sourceComponent = nodeRoot.leafComponent();
        } else if (nodeRoot.isLayout || nodeRoot.isContainer) {
            nodeRoot.previewRoot.registerNode(nodeRoot.nodeId, nodeRoot.nodeType, nodeRoot,
                nodeRoot.generation);
        } else {
            nodeRoot.previewRoot.failNode(nodeRoot.nodeId || "<missing>", nodeRoot.nodeType || "<missing>",
                "unsupported node \"" + (nodeRoot.nodeId || "<missing>")
                + "\" of type \"" + (nodeRoot.nodeType || "<missing>") + "\"", nodeRoot.generation);
        }
    }

    onMenuOpenChanged: {
        if (nodeRoot.previewRoot && nodeRoot.isMenu)
            nodeRoot.previewRoot.recordNodeEvent(nodeRoot.nodeId, "event",
                nodeRoot.menuOpen ? "opened" : "closed", {}, nodeRoot.generation);
    }

    onRolloutOpenChanged: {
        if (nodeRoot.previewRoot && nodeRoot.isShellBorderRollout)
            nodeRoot.previewRoot.recordNodeEvent(nodeRoot.nodeId, "event",
                nodeRoot.rolloutOpen ? "opened" : "closed", {}, nodeRoot.generation);
    }
}
