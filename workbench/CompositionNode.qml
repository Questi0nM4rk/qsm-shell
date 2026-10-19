pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style
import "fixtures"
import "compositions" as Compositions

Item {
    id: root

    property var node: null
    property var scene: null
    property int generation: 0
    property var previewEnvironment: null
    property var ownerNode: null
    property string contentSize: "lg"

    readonly property string nodeId: root.node ? String(root.node.id ?? "") : ""
    readonly property string nodeType: root.node ? String(root.node.type ?? "") : ""
    readonly property var props: root.resolve(root.nodeType, root.node ? root.node.props : null)
    readonly property var childNodes: root.list(root.node ? root.node.children : null)

    readonly property bool isStack: root.nodeType === "stack"
    readonly property bool isLayout: root.nodeType === "column" || root.nodeType === "row" || root.isStack
    readonly property bool isMenu: root.nodeType === "menu"
    readonly property bool isRollout: root.nodeType === "shell-border-rollout"
    readonly property bool isMockScreen: root.nodeType === "mock-screen"
    readonly property bool isDataCapsule: root.nodeType === "data-capsule"
    readonly property bool isContainer: root.isMenu || root.isRollout || root.isDataCapsule
    readonly property bool isLeaf: !root.isLayout && !root.isContainer && !root.isMockScreen
    readonly property bool known: root.isLayout || root.isContainer || root.isMockScreen
        || root.leafFor(root.nodeType) !== null

    readonly property int gap: root.token(root.stringProp("spacing", "sm"))
    readonly property int pad: root.token(root.stringProp("padding", "none"))
    readonly property real declaredWidth: root.numberProp("width", -1)
    readonly property real declaredHeight: root.numberProp("height", -1)
    readonly property bool placementConstrained: root.isMockScreen ? mockScreen.constrained
        : root.isDataCapsule && root.screenPlacement ? root.screenPlacement.constrained : false
    readonly property var screenPlacement: root.isDataCapsule && root.ownerNode
        ? root.ownerNode.placeCapsule(root) : null

    property bool containerOpen: root.props.open === true
    property string side: root.sideName()
    property bool capsuleOpen: root.props.open === true
    property bool capsuleHoverStay: root.props["hover-stay"] === true
    property bool capsuleInteractive: root.props.interactive === true
    property bool capsuleElevated: root.props.elevated !== false
    property int capsuleTimeout: Math.max(0, Math.round(root.numberProp("timeout", 0)))
    property string capsuleEdge: root.enumProp("edge", ["left", "right", "top", "bottom"], "bottom")
    property string capsuleAlignment: root.enumProp("alignment", ["start", "center", "end"], "center")
    property string capsuleOrientation: root.enumProp("orientation", ["horizontal", "vertical"], "horizontal")
    property string capsuleSize: root.enumProp("size", ["sm", "md", "lg"], "md")
    property string capsuleLength: root.enumProp("length", ["short", "default", "long", "content"], "default")
    property real capsuleInset: root.token(root.stringProp("inset", "md"))

    readonly property real bodyWidth: root.isLeaf ? leafLoader.implicitWidth
        : root.nodeType === "column" ? columnBox.implicitWidth
        : root.isStack ? root.extentWidth(stackRows)
        : root.isMenu ? menuBox.implicitWidth
        : root.isRollout ? rolloutBox.width
        : root.isDataCapsule ? capsuleHost.implicitWidth
        : root.isMockScreen ? root.width
        : rowBox.implicitWidth
    readonly property real bodyHeight: root.isLeaf ? leafLoader.implicitHeight
        : root.nodeType === "column" ? columnBox.implicitHeight
        : root.isStack ? root.extentHeight(stackRows, 0)
        : root.isMenu ? menuBox.implicitHeight
        : root.isRollout ? rolloutBox.height
        : root.isDataCapsule ? capsuleHost.implicitHeight
        : root.isMockScreen ? root.height
        : rowBox.implicitHeight

    readonly property var events: root.isLeaf
        ? (leafLoader.item ? root.list(leafLoader.item.events) : [])
        : root.isMenu ? ["opened", "closed", "selected"]
        : root.isRollout ? ["opened", "closed"]
        : root.isDataCapsule ? ["activated", "timeout-requested"] : []
    readonly property var controls: root.isLeaf
        ? (leafLoader.item ? root.list(leafLoader.item.controls) : [])
        : root.isContainer ? root.containerControls : []
    readonly property var actions: root.isLeaf
        ? (leafLoader.item ? root.list(leafLoader.item.actions) : [])
        : root.isContainer ? root.containerActions : []
    readonly property var integration: root.isLeaf
        ? (leafLoader.item ? leafLoader.item.integration : null)
        : root.isContainer ? root.containerIntegration : null

    objectName: root.nodeId
    implicitWidth: root.bodyWidth + (root.isLayout ? root.pad * 2 : 0)
    implicitHeight: root.bodyHeight + (root.isLayout ? root.pad * 2 : 0)
    width: root.declaredWidth >= 0 ? root.declaredWidth
        : root.screenPlacement ? root.screenPlacement.rect.width
        : root.isMockScreen ? (root.previewEnvironment ? root.previewEnvironment.screenRect.width : parent.width)
        : root.implicitWidth
    height: root.declaredHeight >= 0 ? root.declaredHeight
        : root.screenPlacement ? root.screenPlacement.rect.height
        : root.isMockScreen ? (root.previewEnvironment ? root.previewEnvironment.screenRect.height : parent.height)
        : root.implicitHeight
    visible: !root.isDataCapsule || !root.screenPlacement || !root.screenPlacement.empty
    enabled: !root.isDataCapsule || !root.screenPlacement || !root.screenPlacement.empty

    Binding {
        target: root
        property: "x"
        value: root.screenPlacement ? root.screenPlacement.rect.x : 0
        when: !!root.screenPlacement
    }

    Binding {
        target: root
        property: "y"
        value: root.screenPlacement ? root.screenPlacement.rect.y : 0
        when: !!root.screenPlacement
    }

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

    function stringProp(name: string, fallback: string): string {
        const value = root.props[name]
        return value === undefined || value === null ? fallback : String(value)
    }

    function numberProp(name: string, fallback: real): real {
        const value = Number(root.props[name])
        return isFinite(value) && root.props[name] !== undefined && root.props[name] !== null
            ? value : fallback
    }

    function enumProp(name: string, values: var, fallback: string): string {
        const value = root.stringProp(name, fallback)
        return values.indexOf(value) >= 0 ? value : fallback
    }

    // The descriptor's declared defaults, filled in under the document's own
    // values. One table per type, so an omitted prop and an absent one read
    // the same and no node invents a number of its own.
    function resolve(type: string, declared: var): var {
        const out = {}
        const defaults = {
            "column": { "spacing": "sm", "padding": "none" },
            "row": { "spacing": "sm", "padding": "none" },
            "stack": { "spacing": "sm", "padding": "none" },
            "text-field": { "size": "md", "state": "default", "label": "", "text": "" },
            "checkbox": { "checked": false, "label": "" },
            "switch": { "checked": false, "label": "" },
            "radio": { "checked": false, "label": "" },
            "slider": { "value": 50, "orientation": "horizontal", "label": "" },
            "sound-channel": { "level": 50, "muted": false, "icon": "volume" },
            "menu-items": { "size": "md" },
            "segmented": { "selected": 0, "label": "" },
            "spin-box": { "value": 0, "label": "" },
            "menu": { "title": "", "open": false, "selected": 0 },
            "shell-border-rollout": { "side": "right", "open": false },
            "mock-screen": {},
            "data-capsule": {
                "open": true, "hover-stay": true, "interactive": false, "elevated": true,
                "timeout": 0, "edge": "bottom", "alignment": "center", "inset": "md",
                "orientation": "horizontal", "size": "md", "length": "default"
            }
        }
        for (const key in (defaults[type] ?? {}))
            out[key] = defaults[type][key]
        for (const key in (declared ?? {}))
            out[key] = declared[key]
        return out
    }

    function token(name: string): int {
        switch (name) {
        case "xs": return Style.space1
        case "sm": return Style.space2
        case "md": return Style.space4
        case "lg": return Style.space6
        default: return 0
        }
    }

    function sideName(): string {
        const wanted = root.stringProp("side", "right")
        return ["left", "right", "top", "bottom"].indexOf(wanted) >= 0 ? wanted : "right"
    }

    function leafFor(type: string): var {
        switch (type) {
        case "text-field": return textFieldLeaf
        case "checkbox": return checkboxLeaf
        case "switch": return switchLeaf
        case "radio": return radioLeaf
        case "slider": return sliderLeaf
        case "sound-channel": return soundChannelLeaf
        case "menu-items": return menuItemsLeaf
        case "segmented": return segmentedLeaf
        case "spin-box": return spinBoxLeaf
        default: return null
        }
    }

    function target(): var {
        return root.isLeaf ? leafLoader.item : root.isDataCapsule ? capsuleHost : root
    }

    function nativeTarget(name: var): var {
        if (root.screenPlacement && root.screenPlacement.empty)
            return null
        const component = root.target()
        if (name !== undefined && name !== "")
            return component && typeof component.nativeTargetFor === "function"
                ? component.nativeTargetFor(name) : null
        return component && component.nativeTarget ? component.nativeTarget : component
    }

    function applyControl(groupIndex: int, optionIndex: int): bool {
        const target = root.isDataCapsule ? root : root.target()
        if (!target)
            return false
        const groups = root.list(target.controls)
        if (groupIndex < 0 || groupIndex >= groups.length)
            return false
        const options = root.list(groups[groupIndex].options)
        if (optionIndex < 0 || optionIndex >= options.length)
            return false
        const option = options[optionIndex]
        if (!option)
            return false
        if (option.call !== undefined) {
            if (typeof target[option.call] !== "function")
                return false
            target[option.call]()
        } else if (option.set !== undefined) {
            for (const key in option.set)
                target[key] = option.set[key]
        } else {
            return false
        }
        return true
    }

    function runAction(name: string): bool {
        const target = root.isLeaf ? leafLoader.item : root
        if (!target || target.nodeEnabled === false || target.fieldState === "disabled")
            return false
        const list = root.actions
        for (let i = 0; i < list.length; i++) {
            if (String(list[i].text) === name)
                return typeof list[i].trigger === "function" && list[i].trigger() === true
        }
        return false
    }

    function triggerAction(index: int): bool {
        const list = root.actions
        if (index < 0 || index >= list.length)
            return false
        return root.runAction(String(list[index].text))
    }

    function reportEvent(name: string, payload: var, origin: var): void {
        if (root.scene)
            root.scene.recordNodeEvent(root.nodeId, name, payload, origin)
    }

    readonly property var capsuleControls: [
        { "label": "open", "options": [
            { "label": "open", "set": { "capsuleOpen": true } },
            { "label": "closed", "set": { "capsuleOpen": false } }
        ] },
        { "label": "edge", "options": ["left", "right", "top", "bottom"].map(value => ({ "label": value, "set": { "capsuleEdge": value } })) },
        { "label": "alignment", "options": ["start", "center", "end"].map(value => ({ "label": value, "set": { "capsuleAlignment": value } })) },
        { "label": "inset", "options": ["none", "xs", "sm", "md", "lg"].map(value => ({ "label": value, "set": { "capsuleInset": root.token(value) } })) },
        { "label": "orientation", "options": ["horizontal", "vertical"].map(value => ({ "label": value, "set": { "capsuleOrientation": value } })) },
        { "label": "size", "options": ["sm", "md", "lg"].map(value => ({ "label": value, "set": { "capsuleSize": value } })) },
        { "label": "length", "options": ["short", "default", "long", "content"].map(value => ({ "label": value, "set": { "capsuleLength": value } })) },
        { "label": "lifetime", "options": [
            { "label": "persistent", "set": { "capsuleTimeout": 0 } },
            { "label": "timed", "set": { "capsuleTimeout": 5000 } }
        ] },
        { "label": "retention", "options": [
            { "label": "hold on hover", "set": { "capsuleHoverStay": true } },
            { "label": "expire while hovered", "set": { "capsuleHoverStay": false } }
        ] },
        { "label": "elevation", "options": [
            { "label": "elevated", "set": { "capsuleElevated": true } },
            { "label": "flat", "set": { "capsuleElevated": false } }
        ] },
        { "label": "availability", "options": [
            { "label": "interactive", "set": { "capsuleInteractive": true } },
            { "label": "report-only", "set": { "capsuleInteractive": false } }
        ] }
    ]

    readonly property var containerControls: root.isDataCapsule ? root.capsuleControls : [
        { "label": "open", "options": [
            { "label": "open", "set": { "containerOpen": true } },
            { "label": "closed", "set": { "containerOpen": false } }
        ] }
    ].concat(root.isRollout ? [
        { "label": "side", "options": [
            { "label": "left", "set": { "side": "left" } },
            { "label": "right", "set": { "side": "right" } },
            { "label": "top", "set": { "side": "top" } },
            { "label": "bottom", "set": { "side": "bottom" } }
        ] }
    ] : [])

    readonly property var containerActions: root.isDataCapsule ? [
        { "text": "open", "trigger": () => root.openCapsule() },
        { "text": "close", "trigger": () => root.closeCapsule() },
        { "text": "restart", "trigger": () => root.restartCapsule() },
        { "text": "cancel-timeout", "trigger": () => root.cancelCapsuleTimeout() },
        { "text": "activate", "trigger": () => capsuleHost.activate() }
    ] : [
        { "text": "open", "trigger": () => { root.containerOpen = true; return true } },
        { "text": "close", "trigger": () => { root.containerOpen = false; return true } },
        { "text": "toggle", "trigger": () => { root.containerOpen = !root.containerOpen; return true } }
    ]

    readonly property var containerIntegration: root.isDataCapsule ? ({
        events: root.events,
        observables: {
            "open": () => capsuleHost.shown,
            "present": () => capsuleHost.present,
            "keep-open": () => capsuleHost.keepOpen,
            "accepts-input": () => capsuleHost.acceptsInput,
            "fullscreen": () => root.previewEnvironment ? root.previewEnvironment.fullscreen === true : false,
            "edge": () => root.capsuleEdge,
            "alignment": () => root.capsuleAlignment,
            "constrained": () => root.placementConstrained,
            "remaining-time": () => capsuleHost.remainingTime()
        },
        idle: () => true
    }) : ({
        events: root.events,
        observables: root.isMenu
        ? { "open": () => root.containerOpen, "current-index": () => menuHost.currentIndex }
            : { "open": () => root.containerOpen, "side": () => root.side,
                "revealed": () => rolloutHost.offsetScale },
        keys: root.isMenu ? { "Enter": () => {
            if (!menuHost._isSelectable(menuHost.currentIndex))
                return false
            menuHost.activateCurrent()
            return true
        } } : ({}),
        idle: () => !root.isRollout
            || rolloutHost.offsetScale === (rolloutHost.shouldBeActive ? 0 : 1)
    })

    function openCapsule(): bool {
        root.capsuleOpen = true
        capsuleHost.restart()
        return true
    }

    function closeCapsule(): bool {
        root.capsuleOpen = false
        return true
    }

    function restartCapsule(): bool {
        capsuleHost.restart()
        return true
    }

    function cancelCapsuleTimeout(): bool {
        capsuleHost.reset()
        return true
    }

    onContainerOpenChanged: {
        if (root.isMenu || root.isRollout)
            root.reportEvent(root.containerOpen ? "opened" : "closed", {})
    }

    Component {
        id: childNode
        Loader {
            required property var modelData
            active: true
            width: root.isDataCapsule ? parent.width : undefined
            height: root.isDataCapsule ? parent.height : undefined
            Component.onCompleted: setSource("CompositionNode.qml", {
                "node": modelData, "scene": root.scene, "generation": root.generation,
                "previewEnvironment": Qt.binding(() => root.previewEnvironment),
                "contentSize": Qt.binding(() => root.isDataCapsule ? root.capsuleSize : root.contentSize),
                "ownerNode": root.isMockScreen ? root : root.ownerNode
            })
            onStatusChanged: {
                if (status === Loader.Error)
                    root.scene.failNode(String(modelData.id ?? ""), String(modelData.type ?? ""),
                        "failed to construct its component", root.generation)
            }
        }
    }

    Loader {
        id: leafLoader
        visible: root.isLeaf
        active: root.isLeaf
        anchors.fill: parent
        sourceComponent: root.leafFor(root.nodeType)
        onLoaded: root.scene.registerNode(root.nodeId, root, root.generation)
        onStatusChanged: {
            if (status === Loader.Error)
                root.scene.failNode(root.nodeId, root.nodeType,
                    "failed to load its component", root.generation)
        }
    }

    Column {
        id: columnBox
        visible: root.nodeType === "column"
        x: root.pad
        y: root.pad
        spacing: root.gap
        Repeater {
            model: root.nodeType === "column" ? root.childNodes : []
            delegate: childNode
        }
    }

    Row {
        id: rowBox
        visible: root.nodeType === "row"
        x: root.pad
        y: root.pad
        spacing: root.gap
        Repeater {
            model: root.nodeType === "row" ? root.childNodes : []
            delegate: childNode
        }
    }

    Item {
        id: stack
        visible: root.isStack
        Repeater {
            id: stackRows
            model: root.isStack ? root.childNodes : []
            delegate: childNode
        }
    }

    Column {
        id: menuBox
        visible: root.isMenu
        spacing: root.gap

        ControlLabel {
            text: root.stringProp("title", "")
        }

        Menu {
            id: menuHost
            objectName: root.nodeId + "-menu"
            visible: root.containerOpen
            model: root.isMenu ? root.childNodes : []
            delegate: menuRow
            currentIndex: root.isMenu ? Math.round(root.numberProp("selected", 0)) : -1
            width: root.extentWidth(menuRows)
            height: root.extentHeight(menuRows, menuHost.spacing)
            onActivated: index => root.reportEvent("selected", { "index": index })
        }
    }

    Component {
        id: menuRow
        ListRow {
            required property var modelData
            primary: String(modelData.props && modelData.props.label !== undefined
                ? modelData.props.label : modelData.id)
            selected: menuHost.currentIndex === index
            onActivated: menuHost.activated(index)
        }
    }

    Item {
        visible: false
        Repeater {
            id: menuRows
            model: root.isMenu ? root.childNodes : []
            delegate: childNode
        }
    }

    Item {
        id: rolloutBox
        visible: root.isRollout
        width: root.declaredWidth >= 0 ? root.declaredWidth : rolloutHost.implicitWidth
        height: root.declaredHeight >= 0 ? root.declaredHeight : rolloutHost.implicitHeight

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
            rolloutId: root.nodeId
            edges: [root.side]
            tier: "small"
            shouldBeActive: root.containerOpen
            bodyWidth: contentColumn.implicitWidth
            bodyHeight: contentColumn.implicitHeight
            x: !revealHorizontal ? 0
                : root.side === "right" ? rolloutBox.width - rolloutHost.width : 0
            y: revealHorizontal ? 0
                : root.side === "bottom" ? rolloutBox.height - rolloutHost.height : 0

            Column {
                id: contentColumn
                spacing: root.gap
                Repeater {
                    model: root.isRollout ? root.childNodes : []
                    delegate: childNode
                }
            }
        }
    }

    MockScreen {
        id: mockScreen
        visible: root.isMockScreen
        width: root.width
        height: root.height
        previewEnvironment: root.previewEnvironment
        preferredWidth: screenRect.width
        preferredHeight: screenRect.height
        edge: "top"
        alignment: "start"
        inset: 0

        Repeater {
            anchors.fill: parent
            model: root.isMockScreen ? root.childNodes : []
            delegate: childNode
        }
    }

    DataCapsule {
        id: capsuleHost
        visible: root.isDataCapsule
        anchors.fill: parent
        shown: root.capsuleOpen
        timeout: root.capsuleTimeout
        hoverStay: root.capsuleHoverStay
        interactive: root.capsuleInteractive
        elevated: root.capsuleElevated
        orientation: root.capsuleOrientation === "vertical" ? Qt.Vertical : Qt.Horizontal
        size: root.capsuleSize
        preferredLength: root.capsuleLength === "content"
            ? Style.rhythm(root.contentMainExtent() + padding * 2)
            : Style.rhythm(Style.controlWidth * sizeScale
                * (root.capsuleLength === "short" ? 0.7 : root.capsuleLength === "long" ? 1.5 : 1))
        bodySize: Style.size("DataCapsule", root.capsuleSize)
        onActivated: root.reportEvent("activated", {}, "component")
        onTimeoutRequested: {
            root.reportEvent("timeout-requested", {}, "component")
            if (capsuleHost.shown)
                root.capsuleOpen = false
        }

        Repeater {
            id: capsuleRows
            parent: capsuleHost.contentItem
            anchors.fill: parent
            model: root.isDataCapsule ? root.childNodes : []
            delegate: childNode
        }
    }

    function contentMainExtent(): real {
        let extent = 0
        for (let index = 0; index < capsuleRows.count; index++) {
            const item = capsuleRows.itemAt(index)?.item
            if (item)
                extent = Math.max(extent, root.capsuleOrientation === "vertical"
                    ? item.implicitHeight : item.implicitWidth)
        }
        return extent
    }

    // What a box of children measures, from the children themselves: a
    // Repeater's delegates are loaders, and a loader reports no size of its
    // own for the item inside it.
    function extentWidth(rows: var): real {
        let widest = 0
        for (let i = 0; i < rows.count; i++) {
            const loader = rows.itemAt(i)
            if (loader && loader.item)
                widest = Math.max(widest, loader.item.width)
        }
        return widest
    }

    function extentHeight(rows: var, gap: real): real {
        let total = 0
        for (let i = 0; i < rows.count; i++) {
            const loader = rows.itemAt(i)
            if (loader && loader.item)
                total += loader.item.height
        }
        return total + Math.max(0, rows.count - 1) * gap
    }

    function placeCapsule(capsule: var): var {
        if (!root.isMockScreen || !capsule)
            return null
        const bounds = mockScreen.screenRect
        const placed = mockScreen.place(bounds, capsule.bodyWidth, capsule.bodyHeight,
            capsule.capsuleEdge, capsule.capsuleAlignment, capsule.capsuleInset)
        return {
            rect: Qt.rect(placed.rect.x - bounds.x, placed.rect.y - bounds.y,
                placed.rect.width, placed.rect.height),
            constrained: placed.constrained,
            empty: placed.empty
        }
    }

    component TextFieldLeaf: Item {
        id: leaf

        property bool nodeEnabled: true
        property string fieldState: root.stringProp("state", "default")
        property string hostText: root.stringProp("text", "")

        readonly property var events: ["accepted", "changed"]
        readonly property var actions: [
            { "text": "clear", "trigger": () => { field.clear(); return true } },
            { "text": "focus", "trigger": () => { field.forceActiveFocus(); return field.focused } }
        ]
        readonly property var controls: [
            { "label": "state", "options": [
                { "label": "default", "set": { "fieldState": "default" } },
                { "label": "filled", "set": { "fieldState": "filled" } },
                { "label": "error", "set": { "fieldState": "error" } },
                { "label": "disabled", "set": { "fieldState": "disabled" } }
            ] },
            { "label": "size", "options": [
                { "label": "sm", "set": { "size": "sm" } },
                { "label": "md", "set": { "size": "md" } },
                { "label": "lg", "set": { "size": "lg" } }
            ] },
            { "label": "availability", "options": [
                { "label": "enabled", "set": { "nodeEnabled": true } },
                { "label": "disabled", "set": { "nodeEnabled": false } }
            ] }
        ]
        readonly property var integration: ({
            events: leaf.events,
            observables: {
                "text": () => leaf.hostText,
                "enabled": () => field.enabled,
                "focused": () => field.focused,
                "failed": () => field.failed,
                "state": () => leaf.fieldState,
                "size": () => field.size
            },
            keys: { "Enter": () => field.accept() },
            textDriver: value => {
                if (typeof value !== "string" || !field.enabled)
                    return false
                leaf.hostText = value
                return true
            },
            idle: () => true
        })

        implicitWidth: Math.max(frame.implicitWidth, field.implicitWidth)
        implicitHeight: frame.implicitHeight

        Field {
            id: frame
            width: root.width
            label: root.stringProp("label", "")
            sizeScale: field.sizeScale

            TextField {
                id: field
                width: Math.max(implicitWidth, parent.width)
                size: root.stringProp("size", "md")
                enabled: leaf.nodeEnabled && leaf.fieldState !== "disabled"
                failed: leaf.fieldState === "error"
                text: leaf.hostText
                onAccepted: root.reportEvent("accepted", { "text": field.text })
                onEdited: next => {
                    leaf.hostText = next
                    root.reportEvent("changed", { "text": next })
                }
            }
        }
    }

    component CheckboxLeaf: Item {
        id: leaf

        readonly property Item nativeTarget: box
        property bool nodeEnabled: true
        property bool hostChecked: root.props.checked === true
        property bool hostIndeterminate: false

        readonly property var events: ["toggled"]
        readonly property var actions: [
            { "text": "toggle", "trigger": () => { box.flip(); return true } },
            { "text": "check", "trigger": () => {
                leaf.hostIndeterminate = false
                leaf.hostChecked = true
                return true } },
            { "text": "uncheck", "trigger": () => {
                leaf.hostIndeterminate = false
                leaf.hostChecked = false
                return true } }
        ]
        readonly property var controls: [
            { "label": "checked", "options": [
                { "label": "unchecked", "set": { "hostChecked": false, "hostIndeterminate": false } },
                { "label": "checked", "set": { "hostChecked": true, "hostIndeterminate": false } },
                { "label": "some", "set": { "hostChecked": false, "hostIndeterminate": true } }
            ] },
            { "label": "availability", "options": [
                { "label": "enabled", "set": { "nodeEnabled": true } },
                { "label": "disabled", "set": { "nodeEnabled": false } }
            ] }
        ]
        readonly property var integration: ({
            events: leaf.events,
            observables: {
                "checked": () => leaf.hostChecked,
                "indeterminate": () => leaf.hostIndeterminate,
                "enabled": () => box.enabled
            },
            keys: {
                "Space": () => { box.flip(); return true },
                "Enter": () => { box.flip(); return true }
            },
            idle: () => true
        })

        implicitWidth: Math.max(frame.implicitWidth, box.implicitWidth)
        implicitHeight: frame.implicitHeight

        Field {
            id: frame
            width: root.width
            label: root.stringProp("label", "")
            sizeScale: box.sizeScale

            Checkbox {
                id: box
                width: Math.max(implicitWidth, parent.width)
                enabled: leaf.nodeEnabled
                accessibleName: root.stringProp("label", "")
                checked: leaf.hostChecked
                indeterminate: leaf.hostIndeterminate
                onToggleRequested: next => {
                    leaf.hostChecked = next
                    root.reportEvent("toggled", { "checked": next })
                }
            }
        }
    }

    component SwitchLeaf: Item {
        id: leaf

        property bool nodeEnabled: true
        property bool hostChecked: root.props.checked === true

        readonly property var events: ["toggled"]
        readonly property var actions: [
            { "text": "toggle", "trigger": () => { box.flip(); return true } }
        ]
        readonly property var controls: [
            { "label": "checked", "options": [
                { "label": "off", "set": { "hostChecked": false } },
                { "label": "on", "set": { "hostChecked": true } }
            ] },
            { "label": "availability", "options": [
                { "label": "enabled", "set": { "nodeEnabled": true } },
                { "label": "disabled", "set": { "nodeEnabled": false } }
            ] }
        ]
        readonly property var integration: ({
            events: leaf.events,
            observables: { "checked": () => leaf.hostChecked, "enabled": () => box.enabled },
            keys: {
                "Space": () => { box.flip(); return true },
                "Enter": () => { box.flip(); return true }
            },
            idle: () => true
        })

        implicitWidth: Math.max(frame.implicitWidth, box.implicitWidth)
        implicitHeight: frame.implicitHeight

        Field {
            id: frame
            width: root.width
            label: root.stringProp("label", "")
            sizeScale: box.sizeScale

            Switch {
                id: box
                width: Math.max(implicitWidth, parent.width)
                enabled: leaf.nodeEnabled
                checked: leaf.hostChecked
                onToggleRequested: next => {
                    leaf.hostChecked = next
                    root.reportEvent("toggled", { "checked": next })
                }
            }
        }
    }

    component RadioLeaf: Item {
        id: leaf

        property bool nodeEnabled: true
        property bool hostChecked: root.props.checked === true

        readonly property var events: ["selected"]
        readonly property var actions: [
            { "text": "select", "trigger": () => { box.select(); return true } }
        ]
        readonly property var controls: [
            { "label": "checked", "options": [
                { "label": "off", "set": { "hostChecked": false } },
                { "label": "on", "set": { "hostChecked": true } }
            ] },
            { "label": "availability", "options": [
                { "label": "enabled", "set": { "nodeEnabled": true } },
                { "label": "disabled", "set": { "nodeEnabled": false } }
            ] }
        ]
        readonly property var integration: ({
            events: leaf.events,
            observables: { "checked": () => leaf.hostChecked, "enabled": () => box.enabled },
            keys: {
                "Space": () => { box.select(); return true },
                "Enter": () => { box.select(); return true }
            },
            idle: () => true
        })

        implicitWidth: Math.max(frame.implicitWidth, box.implicitWidth)
        implicitHeight: frame.implicitHeight

        Field {
            id: frame
            width: root.width
            label: root.stringProp("label", "")
            sizeScale: box.sizeScale

            Radio {
                id: box
                width: Math.max(implicitWidth, parent.width)
                enabled: leaf.nodeEnabled
                accessibleName: root.stringProp("label", "")
                checked: leaf.hostChecked
                onSelectionRequested: {
                    leaf.hostChecked = true
                    root.reportEvent("selected", {})
                }
            }
        }
    }

    component SliderLeaf: Item {
        id: leaf

        readonly property Item nativeTarget: slider
        property bool nodeEnabled: true
        property string orientationName: root.stringProp("orientation", "horizontal")
        property real hostValue: root.numberProp("value", 50)

        readonly property var events: ["changed"]
        readonly property var actions: [
            { "text": "reset", "trigger": () => {
                leaf.hostValue = root.numberProp("value", 50)
                return true } }
        ]
        readonly property var controls: [
            { "label": "orientation", "options": [
                { "label": "horizontal", "set": { "orientationName": "horizontal" } },
                { "label": "vertical", "set": { "orientationName": "vertical" } }
            ] },
            { "label": "value", "options": [
                { "label": "min", "set": { "hostValue": 0 } },
                { "label": "mid", "set": { "hostValue": 50 } },
                { "label": "high", "set": { "hostValue": 80 } }
            ] },
            { "label": "availability", "options": [
                { "label": "enabled", "set": { "nodeEnabled": true } },
                { "label": "disabled", "set": { "nodeEnabled": false } }
            ] }
        ]
        readonly property var integration: ({
            events: leaf.events,
            observables: {
                "value": () => slider.value,
                "orientation": () => slider.vertical ? "vertical" : "horizontal",
                "enabled": () => slider.enabled
            },
            idle: () => true
        })

        implicitWidth: Math.max(frame.implicitWidth, slider.implicitWidth)
        implicitHeight: frame.implicitHeight

        Field {
            id: frame
            width: root.width
            label: root.stringProp("label", "")
            sizeScale: slider.sizeScale

            Slider {
                id: slider
                width: Math.max(implicitWidth, parent.width)
                height: root.declaredHeight >= 0
                    ? Math.max(implicitHeight, root.declaredHeight) : implicitHeight
                enabled: leaf.nodeEnabled
                from: 0
                to: 100
                stepSize: 1
                orientation: leaf.orientationName === "vertical" ? Qt.Vertical : Qt.Horizontal
                value: leaf.hostValue
                onMoved: {
                    leaf.hostValue = slider.value
                    root.reportEvent("changed", { "value": slider.value })
                }
            }
        }
    }

    component SoundChannelLeaf: SoundChannel {
        id: soundChannel
        scene: root.scene
        nodeId: root.nodeId
        size: root.contentSize
        level: root.numberProp("level", 50)
        muted: root.props.muted === true
        channelIcon: root.stringProp("icon", "volume")
        width: root.declaredWidth >= 0 ? root.declaredWidth : implicitWidth
        height: root.declaredHeight >= 0 ? root.declaredHeight : implicitHeight
    }

    component SegmentedLeaf: Item {
        id: leaf

        property bool nodeEnabled: true
        property int hostIndex: Math.round(root.numberProp("selected", 0))
        readonly property var segments: ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight"]

        readonly property var events: ["changed"]
        readonly property var actions: [
            { "text": "reset", "trigger": () => {
                leaf.hostIndex = Math.round(root.numberProp("selected", 0))
                return true } }
        ]
        readonly property var controls: [
            { "label": "selection", "options": [
                { "label": "one", "set": { "hostIndex": 0 } },
                { "label": "two", "set": { "hostIndex": 1 } },
                { "label": "three", "set": { "hostIndex": 2 } },
                { "label": "four", "set": { "hostIndex": 3 } },
                { "label": "five", "set": { "hostIndex": 4 } },
                { "label": "six", "set": { "hostIndex": 5 } },
                { "label": "seven", "set": { "hostIndex": 6 } },
                { "label": "eight", "set": { "hostIndex": 7 } }
            ] },
            { "label": "availability", "options": [
                { "label": "enabled", "set": { "nodeEnabled": true } },
                { "label": "disabled", "set": { "nodeEnabled": false } }
            ] }
        ]
        readonly property var integration: ({
            events: leaf.events,
            observables: { "current-index": () => bar.currentIndex, "enabled": () => bar.enabled },
            idle: () => true
        })

        implicitWidth: Math.max(frame.implicitWidth, bar.implicitWidth)
        implicitHeight: frame.implicitHeight

        Field {
            id: frame
            width: root.width
            label: root.stringProp("label", "")
            sizeScale: bar._s

            Segmented {
                id: bar
                width: Math.max(implicitWidth, parent.width)
                enabled: leaf.nodeEnabled
                options: leaf.segments
                currentIndex: leaf.hostIndex
                onSelected: index => {
                    leaf.hostIndex = index
                    root.reportEvent("changed", { "index": index })
                }
            }
        }
    }

    component SpinBoxLeaf: Item {
        id: leaf

        property bool nodeEnabled: true
        property real hostValue: root.numberProp("value", 0)

        readonly property var events: ["changed"]
        readonly property var actions: [
            { "text": "increment", "trigger": () => spin.stepUp() },
            { "text": "decrement", "trigger": () => spin.stepDown() },
            { "text": "reset", "trigger": () => {
                leaf.hostValue = root.numberProp("value", 0)
                return true } }
        ]
        readonly property var controls: [
            { "label": "availability", "options": [
                { "label": "enabled", "set": { "nodeEnabled": true } },
                { "label": "disabled", "set": { "nodeEnabled": false } }
            ] }
        ]
        readonly property var integration: ({
            events: leaf.events,
            observables: {
                "value": () => spin.value,
                "acceptable-input": () => spin.acceptableInput,
                "enabled": () => spin.enabled
            },
            idle: () => true
        })

        implicitWidth: Math.max(frame.implicitWidth, spin.implicitWidth)
        implicitHeight: frame.implicitHeight

        Field {
            id: frame
            width: root.width
            label: root.stringProp("label", "")
            sizeScale: spin.sizeScale

            SpinBox {
                id: spin
                width: Math.max(implicitWidth, parent.width)
                enabled: leaf.nodeEnabled
                from: -1000
                to: 1000
                stepSize: 1
                decimals: 0
                value: leaf.hostValue
                onValueModified: {
                    leaf.hostValue = spin.value
                    root.reportEvent("changed", { "value": spin.value })
                }
            }
        }
    }

    Component { id: textFieldLeaf; TextFieldLeaf {} }
    Component { id: checkboxLeaf; CheckboxLeaf {} }
    Component { id: switchLeaf; SwitchLeaf {} }
    Component { id: radioLeaf; RadioLeaf {} }
    Component { id: sliderLeaf; SliderLeaf {} }
    Component { id: soundChannelLeaf; SoundChannelLeaf {} }
    Component {
        id: menuItemsLeaf
        Compositions.MenuInteractions {
            id: fixture
            size: root.enumProp("size", ["sm", "md", "lg"], "md")
            eventRecorder: (kind, name, payload) => root.reportEvent(name, payload, kind === "result" ? "result" : "component")
            readonly property var events: integration.events
            readonly property var actions: integration.actions.map(name => ({
                text: name, trigger: () => fixture.integration.runAction(name)
            }))
            function nativeTargetFor(name): Item {
                return Object.prototype.hasOwnProperty.call(fixture.integration.targets, name)
                    ? fixture.integration.targets[name]() : null
            }
        }
    }
    Component { id: segmentedLeaf; SegmentedLeaf {} }
    Component { id: spinBoxLeaf; SpinBoxLeaf {} }

    Component.onCompleted: {
        if (!root.known) {
            root.scene.failNode(root.nodeId, root.nodeType,
                "unsupported node type '" + root.nodeType + "'", root.generation)
            return
        }
        if (!root.isLeaf)
            root.scene.registerNode(root.nodeId, root, root.generation)
    }
}
