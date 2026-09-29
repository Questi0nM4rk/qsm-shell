import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style
import "inspect.js" as Inspect

Rectangle {
    id: root

    property string component: "capsule"
    property string variant: "resting"
    property string storyKey: ""
    property var story: ({})
    property int resetGeneration: 0
    property var integrationController: null
    property var scenes: []
    property int viewportWidth: 1600
    property int viewportHeight: 900
    property bool interactive: false
    property bool captureDump: false
    property string theme: "deep-night"
    property var backend: null
    property var _deepNightBackend: ({})
    property int _eventSequence: 0

    readonly property string storyStatus: storyLoader.status === Loader.Ready ? "ready" : storyLoader.status === Loader.Error ? "failed" : "loading"
    readonly property string storySource: String(storyLoader.sourceComponent)
    readonly property string storyError: storyLoader.status === Loader.Error ? "failed to load story host component" : ""
    readonly property var controls: hostControls(storyLoader.item)
    readonly property var actions: hostActions(storyLoader.item)
    readonly property real contentExtentWidth: flick.contentWidth
    readonly property real contentExtentHeight: flick.contentHeight
    property var screenContext: ({ id: "preview-1", width: viewportWidth, height: viewportHeight, scale: 1, focused: true, safeInsets: Qt.rect(16, 16, 16, 16) })

    signal eventRecorded(var record)
    signal inspectionReady(var inspection)

    width: viewportWidth
    height: viewportHeight
    color: "#1c0e27"

    function _loadTheme(): void {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("theme.json"), false);
        request.send();
        if (request.responseText.length > 0)
            root._deepNightBackend = JSON.parse(request.responseText);
    }

    property var _themeFixtures: ({ "deep-night": root._deepNightBackend })
    property var activeBackend: backend !== null && backend !== undefined ? backend : (_themeFixtures[theme] || null)
    Component.onCompleted: {
        root._loadTheme();
        Style.backend = root.activeBackend;
        if (root.interactive || root.captureDump)
            settleDump.start();
    }
    onActiveBackendChanged: Style.backend = root.activeBackend
    onResetGenerationChanged: {
        root._eventSequence = 0;
        storyLoader.active = false;
        storyLoader.active = true;
    }

    function hostControls(item): var { return (item && Array.isArray(item.controls)) ? item.controls : []; }
    function hostActions(item): var { return (item && Array.isArray(item.actions)) ? item.actions : []; }
    function recordEvent(kind, name, payload, origin): var {
        root._eventSequence++;
        const record = { sequence: root._eventSequence, kind, name, payload: payload ?? {}, storyKey: root.storyKey, origin: origin ?? "component" };
        root.eventRecorded(record);
        return record;
    }
    function applyControl(groupIndex, optionIndex): bool {
        const groups = root.hostControls(storyLoader.item);
        if (groupIndex < 0 || groupIndex >= groups.length)
            return false;
        const options = groups[groupIndex].options;
        if (!options || optionIndex < 0 || optionIndex >= options.length)
            return false;
        controlStrip.apply("story", options[optionIndex]);
        root.recordEvent("control", groups[groupIndex].label + "/" + options[optionIndex].label, { group: groupIndex, option: optionIndex });
        return true;
    }
    function triggerAction(index): bool {
        const list = root.hostActions(storyLoader.item);
        if (index < 0 || index >= list.length)
            return false;
        const action = list[index];
        const label = action && action.text !== undefined ? String(action.text) : String(index);
        if (action && typeof action.trigger === "function")
            action.trigger();
        else if (action && typeof action.triggered === "function")
            action.triggered();
        root.recordEvent("action", label, { index });
        return true;
    }

    IntegrationBridge { id: flowBridge }
    function flowTarget(): var { return storyLoader.item; }
    function flowIntegration(): var { const target = root.flowTarget(); return target && target.integration !== undefined ? target.integration : null; }
    function flowCapabilities(): var {
        const integration = root.flowIntegration();
        return { events: integration && Array.isArray(integration.events) ? integration.events : [], actions: integration && Array.isArray(integration.actions) ? integration.actions : [], controls: flowBridge.canonicalControls(flowBridge.controlGroupsOf(root.flowTarget())), observables: integration && integration.observables ? Object.keys(integration.observables) : [], textDriver: integration ? typeof integration.writeText === "function" : false, keys: integration && Array.isArray(integration.keys) ? integration.keys : [], checkpoints: integration && Array.isArray(integration.checkpoints) ? integration.checkpoints : [] };
    }
    function flowDescribeStep(step, index): string {
        if (!step || typeof step !== "object") return "step " + index + ": not an object";
        const caps = root.flowCapabilities();
        const type = String(step.type ?? "");
        switch (type) {
        case "reset": case "awaitIdle": case "capture": return "";
        case "emit": return caps.events.indexOf(String(step.event ?? "")) < 0 ? "step " + index + " (emit): unavailable event '" + String(step.event ?? "") + "'" : "";
        case "action": return caps.actions.indexOf(String(step.name ?? "")) < 0 ? "step " + index + " (action): unavailable action '" + String(step.name ?? "") + "'" : "";
        case "control": {
            const groups = flowBridge.controlGroupsOf(root.flowTarget());
            const gi = flowBridge.findGroupIndex(groups, String(step.group ?? ""));
            if (gi < 0) return "step " + index + " (control): unavailable control '" + String(step.group ?? "") + "'";
            return flowBridge.findOptionIndex(groups[gi].options, String(step.option ?? "")) < 0 ? "step " + index + " (control): unavailable option '" + String(step.option ?? "") + "' for control '" + String(step.group ?? "") + "'" : "";
        }
        case "write": return !caps.textDriver ? "step " + index + " (write): no text driver" : (typeof step.text !== "string" || step.text.length > flowBridge.maxTextLength) ? "step " + index + " (write): text exceeds " + flowBridge.maxTextLength + " characters" : "";
        case "key": return caps.keys.indexOf(String(step.key ?? "")) < 0 ? "step " + index + " (key): unavailable key '" + String(step.key ?? "") + "'" : "";
        case "expect": return caps.observables.indexOf(String(step.observable ?? "")) < 0 ? "step " + index + " (expect): unavailable observable '" + String(step.observable ?? "") + "'" : "";
        case "expectEvent": return caps.events.indexOf(String(step.event ?? "")) < 0 ? "step " + index + " (expectEvent): unavailable event '" + String(step.event ?? "") + "'" : "";
        default: return "step " + index + " (" + (type || "<missing>") + "): unsupported in this bridge";
        }
    }
    function flowPreflight(steps): var { const missing = []; const list = flowBridge.asArray(steps); for (let i = 0; i < list.length; i++) { const problem = root.flowDescribeStep(list[i], i); if (problem !== "") missing.push(problem); } return missing; }
    function flowEmit(event, payload): var { const integration = root.flowIntegration(); const events = integration && Array.isArray(integration.events) ? integration.events : []; if (events.indexOf(String(event ?? "")) < 0) return null; return root.recordEvent("event", String(event ?? ""), payload ?? {}, "injected"); }
    function flowInvokeAction(name): bool { const integration = root.flowIntegration(); const want = String(name ?? ""); if (!integration || !Array.isArray(integration.actions) || integration.actions.indexOf(want) < 0 || typeof integration.runAction !== "function" || !integration.runAction(want)) return false; root.recordEvent("action", want, {}, "component"); return true; }
    function flowApplyControl(control, option): bool { const groups = flowBridge.controlGroupsOf(root.flowTarget()); const gi = flowBridge.findGroupIndex(groups, String(control ?? "")); if (gi < 0) return false; const oi = flowBridge.findOptionIndex(groups[gi].options, String(option ?? "")); if (oi < 0) return false; controlStrip.apply("story", groups[gi].options[oi]); root.recordEvent("control", flowBridge.canonicalName(String(control ?? "")) + "/" + flowBridge.canonicalName(String(option ?? "")), { control: flowBridge.canonicalName(String(control ?? "")), option: flowBridge.canonicalName(String(option ?? "")) }, "component"); return true; }
    function flowWrite(text): bool { const integration = root.flowIntegration(); return integration && typeof integration.writeText === "function" && integration.writeText(text) === true; }
    function flowPressKey(key): bool { const integration = root.flowIntegration(); return integration && typeof integration.pressKey === "function" && Array.isArray(integration.keys) && integration.keys.indexOf(String(key ?? "")) >= 0 && integration.pressKey(String(key ?? "")) === true; }
    function flowRead(name): var { const integration = root.flowIntegration(); const want = String(name ?? ""); if (!integration || !integration.observables || typeof integration.observables[want] !== "function") return flowBridge.failResult("unavailable observable '" + want + "'"); try { return flowBridge.okResult(integration.observables[want]()); } catch (e) { return flowBridge.failResult("observable '" + want + "' failed: " + e); } }
    function flowIdle(step): bool { const integration = root.flowIntegration(); return String(root.storyStatus) === "ready" && (!integration || typeof integration.idle !== "function" || integration.idle() === true); }

    function inspect(visibleOnly: bool): var { return { scene: `${root.component}/${root.variant}`, width: root.width, height: root.height, tree: Inspect.describe(root, visibleOnly) }; }
    function dumpTree(): void { const data = root.inspect(true); root.inspectionReady(data); console.info("QSM_INSPECT " + JSON.stringify(data)); }
    Shortcut { sequence: "F12"; onActivated: root.dumpTree() }
    Timer { id: settleDump; interval: Motion.fast; onTriggered: Qt.callLater(root.dumpTree) }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        Controls.ScrollBar.vertical: Controls.ScrollBar {}
        ColumnLayout {
            id: contentColumn
            width: flick.width
            spacing: Style.space4
            ColumnLayout {
                id: controlStrip
                spacing: Style.space2
                Layout.leftMargin: Style.space6 + Style.space4
                Layout.topMargin: Style.space6 + Style.space4
                Layout.rightMargin: Style.space6 + Style.space4
                property int revision: 0
                readonly property var groups: {
                    const list = [];
                    if (root.scenes.length > 0)
                        list.push({ label: "scene", target: "root", options: root.scenes.map(scene => ({ label: scene.key, set: { component: scene.component, variant: scene.variant } })) });
                    for (const group of root.hostControls(storyLoader.item))
                        list.push({ label: group.label, target: "story", options: group.options });
                    return list;
                }
                visible: root.interactive && controlStrip.groups.length > 0
                function targetItem(target): var { return target === "root" ? root : storyLoader.item; }
                function sameValue(a, b): bool { return a === b || (typeof a === "object" && a !== null && typeof b === "object" && b !== null && Qt.colorEqual(a, b)); }
                function isSelected(target, option): bool { void controlStrip.revision; if (option.set === undefined) return false; const item = controlStrip.targetItem(target); if (!item) return false; for (const key in option.set) if (!controlStrip.sameValue(item[key], option.set[key])) return false; return true; }
                function apply(target, option): void { const item = controlStrip.targetItem(target); if (!item) return; if (option.call !== undefined) item[option.call](); else for (const key in option.set) item[key] = option.set[key]; controlStrip.revision++; settleDump.restart(); }
                Repeater {
                    model: controlStrip.groups
                    RowLayout {
                        required property var modelData
                        property var group: modelData
                        spacing: Style.space2
                        Prose { role: "metadata"; text: parent.group.label }
                        Repeater {
                            id: optionRepeater
                            model: parent.group.options
                            Capsule {
                                required property var modelData
                                size: "sm"
                                label: modelData.label
                                readonly property var group: optionRepeater.parent.group
                                active: controlStrip.isSelected(group.target, modelData)
                                onClicked: controlStrip.apply(group.target, modelData)
                            }
                        }
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(sceneColumn.implicitHeight, flick.height - (controlStrip.visible ? controlStrip.height + contentColumn.spacing : 0))
                ColumnLayout {
                    id: sceneColumn
                    anchors.centerIn: parent
                    spacing: Style.space4
                    Prose { role: "section"; text: `${root.component} / ${root.variant}` }
                    Loader {
                        id: storyLoader
                        sourceComponent: root.storyComponent(root.component)
                        onLoaded: {
                            if (item && "componentKey" in item) item.componentKey = Qt.binding(() => root.component);
                            if (item && "variant" in item) item.variant = Qt.binding(() => root.variant);
                            if (item && "eventRecorder" in item) item.eventRecorder = (kind, name, payload) => root.recordEvent(kind, name, payload);
                        }
                    }
                }
            }
        }
    }

    function storyComponent(key: string): Component {
        switch (key) {
        case "text-input": case "search": case "password-input": case "number-input": return textFieldStory;
        case "level": case "osd-slider": return sliderStory;
        case "switch": return switchStory;
        case "checkbox": return checkboxStory;
        case "radio": return radioStory;
        case "spin-box": return spinBoxStory;
        case "segmented": case "tabs": return segmentedStory;
        case "progress": return progressStory;
        case "meter": return meterStory;
        case "skeleton": return skeletonStory;
        case "callout": return calloutStory;
        case "badge": return badgeStory;
        case "spinner": return spinnerStory;
        case "divider": return dividerStory;
        case "capsule": return capsuleStory;
        case "card": return cardStory;
        case "empty-state": return emptyStateStory;
        case "icon-button": return iconButtonStory;
        case "key-value": return keyValueStory;
        case "menu": return menuStory;
        case "notification": return notificationStory;
        case "notification-stack": return notificationStackStory;
        case "prose": case "prose-ladder": return proseStory;
        case "action-tile": return actionTileStory;
        case "stat": return statStory;
        case "stat-ring": return statRingStory;
        case "sparkline": return sparklineStory;
        case "swatch": return swatchStory;
        case "kbd": return kbdStory;
        case "avatar": return avatarStory;
        case "marquee": return marqueeStory;
        case "section": return sectionStory;
        case "disclosure": return disclosureStory;
        case "scroll": return scrollStory;
        case "field": return fieldStory;
        case "svg-icon": return svgIconStory;
        case "shell-border": return shellBorderStory;
        case "calendar": return calendarStory;
        case "list-row": case "device-row": case "result-row": return listRowStory;
        case "state-layer": return stateLayerStory;
        case "scene-pointer": return scenePointerStory;
        case "rollout-hover": return rolloutStory;
        default: return unsupportedStory;
        }
    }

    component TextFieldStory: TextField {
        id: field
        property string componentKey: "text-input"
        property string variant: ""
        property string purposeOverride: ""
        property bool showLeading: true
        property var eventRecorder: null
        readonly property string purpose: purposeOverride.length > 0 ? purposeOverride : componentKey === "search" || variant.startsWith("search") ? "search" : componentKey === "password-input" || variant.startsWith("password") ? "password" : componentKey === "number-input" || variant.startsWith("number") ? "number" : "text"
        readonly property bool passwordExample: purpose === "password"
        readonly property bool numberExample: purpose === "number"
        readonly property int _slotIconSize: Style.iconNear(Style.iconMd * field.sizeScale)
        size: "lg"
        inputType: passwordExample ? "password" : numberExample ? "number" : "text"
        failed: numberExample && text.length > 0 && !acceptableInput
        leadingSlotInset: purpose === "search" ? 0 : field._inset
        leadingCursorShape: purpose === "search" ? Qt.PointingHandCursor : Qt.IBeamCursor
        trailingCursorShape: readOnly && !passwordExample ? Qt.ArrowCursor : Qt.PointingHandCursor
        placeholder: purpose === "search" ? "Search components" : passwordExample ? "Password" : numberExample ? "Number" : "Enter text"
        text: variant.endsWith("filled") ? (purpose === "search" ? "qsm-lab" : passwordExample ? "correct horse" : numberExample ? "42.5" : "Plain text") : ""
        onAccepted: if (eventRecorder) eventRecorder("intent", "accepted", { text: text })
        onEscaped: if (eventRecorder) eventRecorder("intent", "escaped", {})
        onEdited: text => { if (eventRecorder) eventRecorder("intent", "edited", { text }) }
        leading: Loader { active: field.showLeading; sourceComponent: field.purpose === "search" ? searchAction : purposeGlyph }
        trailing: Loader { active: field.text.length > 0; sourceComponent: IconButton { objectName: "textFieldTrailingAction"; enabled: field.passwordExample || !field.readOnly; icon: field.passwordExample ? field.passwordVisible ? "eye-off" : "eye" : "x"; size: field._slotIconSize; padding: 0; color: Style.textMuted; onClicked: field.passwordExample ? field.toggleReveal() : field.clear() } }
        Component { id: searchAction; IconButton { objectName: "textFieldSearchAction"; icon: "search"; size: field._slotIconSize; padding: 0; leftPadding: field._inset; height: field.fieldHeight; color: Style.textMuted; onClicked: field.accept() } }
        Component { id: purposeGlyph; SvgIcon { objectName: "textFieldPurposeGlyph"; name: field.passwordExample ? "key" : field.numberExample ? "hash" : "type"; size: field._slotIconSize; color: field.enabled ? Style.textMuted : Style.disabled(Style.textMuted) } }
        readonly property var integration: ({ events: ["accepted", "changed"], actions: ["clear", "focus"], observables: { text: () => field.text, enabled: () => field.enabled, focused: () => field.focused, failed: () => field.failed, readonly: () => field.readOnly }, keys: ["Enter", "Escape"], writeText: value => { if (typeof value !== "string" || value.length > 200 || !field.enabled || field.readOnly) return false; field.text = value; return true; }, pressKey: key => { if (key === "Enter") return field.accept(); if (key === "Escape") { field.escaped(); return true; } return false; }, runAction: name => { if (name === "clear") { field.clear(); return true; } if (name === "focus") { field.forceActiveFocus(); return true; } return false; } })
        readonly property var controls: [ { label: "purpose", options: [ { label: "text", set: { purposeOverride: "text", passwordVisible: false, text: "Plain text" } }, { label: "search", set: { purposeOverride: "search", passwordVisible: false, text: "qsm-lab" } }, { label: "password", set: { purposeOverride: "password", passwordVisible: false, text: "correct horse" } }, { label: "number", set: { purposeOverride: "number", passwordVisible: false, text: "42.5" } } ] }, { label: "leading", options: [ { label: "glyph", set: { showLeading: true } }, { label: "none", set: { showLeading: false } } ] }, { label: "size", options: [ { label: "sm", set: { size: "sm" } }, { label: "md", set: { size: "md" } }, { label: "lg", set: { size: "lg" } }, { label: "xl", set: { size: "xl" } } ] }, { label: "failed", options: [ { label: "off", set: { failed: false } }, { label: "on", set: { failed: true } } ] }, { label: "readOnly", options: [ { label: "off", set: { readOnly: false } }, { label: "on", set: { readOnly: true } } ] }, { label: "state", options: [ { label: "enabled", set: { enabled: true } }, { label: "disabled", set: { enabled: false } } ] } ]
    }

    component SliderStory: Slider { property string componentKey: ""; property string variant: ""; orientation: componentKey === "osd-slider" ? Qt.Vertical : Qt.Horizontal; value: variant.includes("high") ? .82 : .35; Layout.preferredWidth: orientation === Qt.Vertical ? implicitWidth : 320; Layout.preferredHeight: orientation === Qt.Vertical ? 320 : implicitHeight }
    component SwitchStory: Switch { property string variant: ""; checked: variant === "on"; readonly property var controls: [{ label: "state", options: [{ label: "on", set: { checked: true } }, { label: "off", set: { checked: false } }, { label: "disabled", set: { enabled: false } }] }] }
    component CheckboxStory: Checkbox {
        id: box
        property string variant: ""
        property var eventRecorder: null
        checked: variant !== "off"
        onToggleRequested: nextChecked => {
            checked = nextChecked;
            if (eventRecorder)
                eventRecorder("intent", "toggled", { checked });
        }
        readonly property var integration: ({ events: ["toggled"], actions: ["toggle", "check", "uncheck"], observables: { checked: () => box.checked, enabled: () => box.enabled }, runAction: name => { if (name === "toggle") { box.flip(); return true; } if (name === "check") { box.indeterminate = false; box.checked = true; return true; } if (name === "uncheck") { box.indeterminate = false; box.checked = false; return true; } return false; } })
    }
    component RadioStory: Radio { property string variant: ""; checked: variant !== "off" }
    component SpinBoxStory: SpinBox { property string variant: ""; value: variant === "decimal" ? 42.5 : 7 }
    component SegmentedStory: Segmented { property string variant: ""; currentIndex: variant === "second" ? 1 : 0; options: ["One", "Two", "Three"] }
    component ProgressStory: ProgressBar { property string variant: ""; indeterminate: variant === "unknown"; value: .64; Layout.preferredWidth: 300 }
    component MeterStory: Meter {
        property string variant: ""
        value: variant === "low" ? .1 : .7
        low: .2
        Layout.preferredWidth: orientation === Qt.Vertical ? implicitWidth : 300
        Layout.preferredHeight: orientation === Qt.Vertical ? 300 : implicitHeight
        readonly property var controls: [
            { label: "orientation", options: [
                { label: "horizontal", set: { orientation: Qt.Horizontal } },
                { label: "vertical", set: { orientation: Qt.Vertical } }
            ] },
            { label: "threshold", options: [
                { label: "none", set: { low: -1, high: -1 } },
                { label: "low", set: { low: 0.2, high: -1 } },
                { label: "high", set: { low: -1, high: 0.8 } }
            ] },
            { label: "state", options: [
                { label: "enabled", set: { enabled: true } },
                { label: "disabled", set: { enabled: false } }
            ] }
        ]
    }
    component SkeletonStory: Skeleton { property string variant: ""; shape: "line"; role: "title"; Layout.preferredWidth: 280 }
    component CalloutStory: Callout { property string variant: ""; Layout.preferredWidth: 360; tone: variant === "danger" ? "danger" : "info"; title: "Callout"; body: "Workbench story" }
    component BadgeStory: Badge { property string variant: ""; text: variant === "warning" ? "Warning" : "Badge"; tone: variant }
    component SpinnerStory: Spinner { running: true }
    component DividerStory: Divider { Layout.preferredWidth: 320 }
    component CapsuleStory: Capsule {
        id: capsule
        property string variant: ""
        property var eventRecorder: null
        icon: "sparkle"
        label: "Capsule"
        active: variant === "active" || variant === "selected"
        onClicked: {
            capsule.active = !capsule.active
            if (eventRecorder)
                eventRecorder("intent", "clicked", { active: capsule.active })
        }
        readonly property var controls: [
            { label: "state", options: [
                { label: "active", set: { active: true } },
                { label: "inactive", set: { active: false } }
            ] },
            { label: "enabled", options: [
                { label: "on", set: { enabled: true } },
                { label: "off", set: { enabled: false } }
            ] }
        ]
        readonly property var integration: ({
            events: ["clicked"],
            actions: ["activate"],
            observables: { active: () => capsule.active, enabled: () => capsule.enabled },
            runAction: name => {
                if (name !== "activate" || !capsule.enabled)
                    return false;
                capsule.activate();
                return true;
            }
        })
    }
    component CardStory: Card { width: 240; height: 140 }
    component EmptyStateStory: EmptyState { title: "Nothing here"; detail: "Try another filter." }
    component IconButtonStory: IconButton {
        icon: "check"
        readonly property var controls: [
            { label: "state", options: [
                { label: "enabled", set: { enabled: true } },
                { label: "disabled", set: { enabled: false } }
            ] }
        ]
    }
    component KeyValueStory: KeyValueRow { Layout.preferredWidth: 280; label: "Battery"; value: "68%" }
    component MenuStory: Menu { width: 280; height: implicitHeight; ListRow { primary: "First"; selected: true } ListRow { primary: "Second" } }
    component NotificationStory: NotificationCard { width: implicitWidth; height: implicitHeight; animateEntrance: false; entry: ({ notificationId: 1, appName: "Workbench", summary: "Notification", body: "Expanded notification body", urgency: "normal", actions: [{ id: "open", label: "Open" }], createdAt: Date.now(), paused: false }) }
    component NotificationStackStory: NotificationStack { width: 380; stack: [{ notificationId: 20, appName: "Workbench", summary: "Stacked notification" }]; isAlive: id => id === 20 }
    component ProseStory: ColumnLayout {
        property string variant: ""
        spacing: Style.space2

        Prose {
            visible: parent.variant === "default"
            role: "hero"
            technical: true
            text: "10:42"
        }
        Prose { visible: parent.variant === "default"; role: "display"; technical: true; text: "42%" }
        Prose { visible: parent.variant === "default" || parent.variant === "heading"; role: "heading"; text: "Surface heading" }
        Prose { visible: parent.variant === "default"; role: "title"; text: "Row title" }
        Prose { visible: parent.variant === "default"; role: "label"; text: "Control label" }
        Prose { visible: parent.variant === "default"; role: "supporting"; text: "Supporting context explains the value above." }
        Prose { visible: parent.variant === "default"; role: "metadata"; text: "Updated just now" }
        Prose { visible: parent.variant === "default"; role: "reading"; text: "192.168.1.42" }
        Prose { visible: parent.variant === "default"; role: "section"; text: "Connection" }
        Prose {
            visible: parent.variant === "default"
            Layout.preferredWidth: Style.size("Prose", "md") * 12
            role: "body"
            text: "Wrapping body copy stays readable without expanding the surface."
        }
    }
    component ActionTileStory: ActionTile {
        id: tile
        property var eventRecorder: null
        icon: "power"
        label: "Power off"
        confirmLabel: "Confirm?"
        onActivated: if (eventRecorder) eventRecorder("intent", "activated", { selected: tile.selected, armed: tile.armed })
        readonly property var controls: [
            { label: "selection", options: [
                { label: "selected", set: { selected: true } },
                { label: "rest", set: { selected: false } }
            ] },
            { label: "armed", options: [
                { label: "on", set: { armed: true } },
                { label: "off", set: { armed: false } }
            ] },
            { label: "state", options: [
                { label: "enabled", set: { enabled: true } },
                { label: "disabled", set: { enabled: false } }
            ] }
        ]
        readonly property var integration: ({
            events: ["activated"],
            actions: ["activate"],
            observables: {
                selected: () => tile.selected,
                armed: () => tile.armed,
                enabled: () => tile.enabled
            },
            runAction: name => {
                if (name !== "activate" || !tile.enabled)
                    return false;
                tile.activate();
                return true;
            }
        })
    }
    component StatStory: Stat { value: "72"; unit: "%"; label: "CPU"; trend: "up"; good: "down" }
    component StatRingStory: StatRing {
        property string variant: ""
        // Shape follows the story variant until a control says otherwise, so
        // the binding to the host variant survives control input.
        property string shapeOverride: ""
        readonly property bool _open: shapeOverride.length > 0 ? shapeOverride === "open" : variant !== "closed"
        value: .7
        icon: "cpu"
        label: "CPU"
        reading: "70%"
        startAngle: _open ? -225 : -90
        sweepAngle: _open ? 270 : 360
        readonly property var controls: [
            { label: "shape", options: [
                { label: "open", set: { shapeOverride: "open" } },
                { label: "closed", set: { shapeOverride: "closed" } }
            ] },
            { label: "content", options: [
                { label: "full", set: { icon: "cpu", reading: "70%", label: "CPU" } },
                { label: "no icon", set: { icon: "", reading: "70%", label: "CPU" } },
                { label: "number", set: { icon: "", reading: "70%", label: "" } }
            ] }
        ]
    }
    component SparklineStory: Sparkline { values: [1, 4, 2, 8, 5]; Layout.preferredWidth: 220; Layout.preferredHeight: 80 }
    component SwatchStory: ColorSwatch {
        property var eventRecorder: null
        sample: "#f6f1f9"
        reading: "#F6F1F9"
        onClicked: if (eventRecorder) eventRecorder("intent", "clicked", {})
        readonly property var controls: [
            { label: "sample", options: [
                { label: "pale", set: { sample: "#f6f1f9", reading: "#F6F1F9", empty: false } },
                { label: "dark", set: { sample: "#1c0e27", reading: "#1C0E27", empty: false } },
                { label: "translucent", set: { sample: "#80c5a5e9", reading: "#C5A5E9", empty: false } },
                { label: "empty", set: { sample: "transparent", reading: "", empty: true } }
            ] },
            { label: "selection", options: [
                { label: "rest", set: { selected: false } },
                { label: "selected", set: { selected: true } }
            ] },
            { label: "state", options: [
                { label: "enabled", set: { enabled: true } },
                { label: "disabled", set: { enabled: false } }
            ] }
        ]
    }
    component KbdStory: Kbd { combo: "SUPER + SHIFT + Q" }
    component AvatarStory: Avatar { name: "Ada Lovelace" }
    component MarqueeStory: Marquee { width: 180; text: "A title far too long for this story" }
    component SectionStory: Section { Layout.preferredWidth: 320; title: "Devices" }
    component DisclosureStory: Disclosure { Layout.preferredWidth: 320; title: "Advanced"; expanded: true }
    component ScrollStory: ScrollArea { width: 260; height: 140; Rectangle { width: 260; height: 420; color: Style.surface } }
    component FieldStory: Field { Layout.preferredWidth: 360; label: "Name"; error: "Use first and last"; TextField { text: "Ada"; failed: true } }
    component SvgIconStory: SvgIcon { name: "check"; size: Style.iconLg; color: Style.accent }
    component ShellBorderStory: Item { width: 320; height: 180; ScenePointer { id: pointer } ShellBorder { anchors.fill: parent; pointer: pointer } }
    component CalendarStory: MonthCalendar { shown: new Date(2026, 7, 1); today: new Date(2026, 7, 28) }
    component ListRowStory: ListRow {
        id: listRow
        property string componentKey: ""
        property string variant: ""
        property var eventRecorder: null

        Layout.preferredWidth: 360
        icon: componentKey === "device-row" ? "headphones" : "sparkle"
        primary: componentKey === "result-row" ? "Search result"
            : componentKey === "device-row" ? "WH-1000XM4" : "List row"
        supporting: variant.includes("reading") ? "Connected" : "Secondary text"
        selected: variant.includes("selected")
        onActivated: if (eventRecorder) eventRecorder("intent", "activated", {})
        onHoveredEntered: listRow.selected = true

        readonly property var controls: [
            { label: "selection", options: [
                { label: "selected", set: { selected: true } },
                { label: "rest", set: { selected: false } }
            ] },
            { label: "availability", options: [
                { label: "enabled", set: { disabled: false } },
                { label: "disabled", set: { disabled: true } }
            ] },
            { label: "purpose", options: [
                { label: "action", set: { interactive: true } },
                { label: "report", set: { interactive: false } }
            ] }
        ]
        readonly property var integration: ({
            events: ["activated"],
            actions: ["activate"],
            observables: {
                selected: () => listRow.selected,
                disabled: () => listRow.disabled,
                interactive: () => listRow.interactive
            },
            runAction: name => {
                if (name !== "activate" || !listRow.selectable)
                    return false;
                listRow.activate();
                return true;
            }
        })
    }
    component StateLayerStory: Rectangle { width: 160; height: 64; radius: Style.radiusMd; color: Style.surface; StateLayer { anchors.fill: parent } }
    component ScenePointerStory: Rectangle { width: 240; height: 120; color: Style.surface; radius: Style.radiusMd; ScenePointer {} Prose { anchors.centerIn: parent; text: "ScenePointer" } }
    component RolloutStory: Rectangle { width: 260; height: 120; color: Style.surface; radius: Style.radiusMd; Prose { anchors.centerIn: parent; text: "Rollout" } }
    component UnsupportedStory: ColumnLayout { property string componentKey: ""; property string variant: ""; spacing: Style.space3; Prose { role: "section"; text: "Unsupported story" } Prose { role: "metadata"; text: parent.componentKey + " / " + parent.variant } }

    // Loader.sourceComponent needs Component objects, not inline component
    // type names. Extend this fixed allowlist as stories migrate.
    Component { id: textFieldStory; TextFieldStory {} }
    Component { id: sliderStory; SliderStory {} }
    Component { id: switchStory; SwitchStory {} }
    Component { id: checkboxStory; CheckboxStory {} }
    Component { id: radioStory; RadioStory {} }
    Component { id: spinBoxStory; SpinBoxStory {} }
    Component { id: segmentedStory; SegmentedStory {} }
    Component { id: progressStory; ProgressStory {} }
    Component { id: meterStory; MeterStory {} }
    Component { id: skeletonStory; SkeletonStory {} }
    Component { id: calloutStory; CalloutStory {} }
    Component { id: badgeStory; BadgeStory {} }
    Component { id: spinnerStory; SpinnerStory {} }
    Component { id: dividerStory; DividerStory {} }
    Component { id: capsuleStory; CapsuleStory {} }
    Component { id: cardStory; CardStory {} }
    Component { id: emptyStateStory; EmptyStateStory {} }
    Component { id: iconButtonStory; IconButtonStory {} }
    Component { id: keyValueStory; KeyValueStory {} }
    Component { id: menuStory; MenuStory {} }
    Component { id: notificationStory; NotificationStory {} }
    Component { id: notificationStackStory; NotificationStackStory {} }
    Component { id: proseStory; ProseStory {} }
    Component { id: actionTileStory; ActionTileStory {} }
    Component { id: statStory; StatStory {} }
    Component { id: statRingStory; StatRingStory {} }
    Component { id: sparklineStory; SparklineStory {} }
    Component { id: swatchStory; SwatchStory {} }
    Component { id: kbdStory; KbdStory {} }
    Component { id: avatarStory; AvatarStory {} }
    Component { id: marqueeStory; MarqueeStory {} }
    Component { id: sectionStory; SectionStory {} }
    Component { id: disclosureStory; DisclosureStory {} }
    Component { id: scrollStory; ScrollStory {} }
    Component { id: fieldStory; FieldStory {} }
    Component { id: svgIconStory; SvgIconStory {} }
    Component { id: shellBorderStory; ShellBorderStory {} }
    Component { id: calendarStory; CalendarStory {} }
    Component { id: listRowStory; ListRowStory {} }
    Component { id: stateLayerStory; StateLayerStory {} }
    Component { id: scenePointerStory; ScenePointerStory {} }
    Component { id: rolloutStory; RolloutStory {} }
    Component { id: unsupportedStory; UnsupportedStory {} }
}
