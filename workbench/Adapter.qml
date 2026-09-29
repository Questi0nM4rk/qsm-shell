import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Style

// The provider's whole contribution to the storybook: it hosts ONE unit, the
// one its catalog names, and forwards that unit's contract to the harness.
//
// There is no window here and no view. The harness owns the catalog, the
// control strip, the scene switch and the tree dump; this file exists only so
// a unit can be loaded and addressed. Everything the unit does not declare, the
// harness must not assume — which is why `controls`, `actions` and the
// integration record are read from the unit rather than from a list kept here.
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

    // Read from the unit. A story with no harness, or a harness that has not
    // reported its states, says so here instead of pretending to be ready.
    readonly property bool _loaded: unitLoader.status === Loader.Ready && !!unitLoader.item
    readonly property var _unit: _loaded ? unitLoader.item : null

    readonly property string storyStatus: mode === "composition"
        ? (compositionStatus())
        : _loaded ? "ready" : unitLoader.status === Loader.Error ? "failed" : "loading"
    readonly property string storySource: _loaded ? String(_unit.objectName ?? storyKey) : ""
    readonly property string storyError: unitLoader.status === Loader.Error
        ? "could not load the unit for story '" + storyKey + "'"
        : mode === "composition" ? "compositions are not hosted by this provider" : ""
    readonly property var controls: _loaded ? asArray(_unit.controls) : []
    readonly property var actions: _loaded ? asArray(_unit.actions) : []
    readonly property real contentExtentWidth: _loaded && _unit.contentExtentWidth !== undefined
        ? Number(_unit.contentExtentWidth) : width
    readonly property real contentExtentHeight: _loaded && _unit.contentExtentHeight !== undefined
        ? Number(_unit.contentExtentHeight) : height

    // The unit's own event API, or nothing. `integration` is the contract a
    // flow drives; a unit that declares none is a story you can look at and
    // not test, and the harness reports exactly that rather than assuming.
    readonly property var integration: _loaded ? (_unit.integration ?? null) : null
    readonly property var events: asArray(integration?.events)
    readonly property var observables: integration?.observables ?? null
    readonly property bool _drivable: integration !== null

    signal eventRecorded(var record)
    signal inspectionReady(var inspection)

    width: viewportWidth > 0 ? viewportWidth : 1
    height: viewportHeight > 0 ? viewportHeight : 1

    // The catalog's `unit` arrives as an absolute URL from the launcher, so
    // this file does not care where the provider lives on disk.
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

    function compositionStatus() {
        return "empty"
    }

    // A control is applied to the UNIT, never to a list this file holds: the
    // option's `set` or `call` goes straight to the loaded item, so a state
    // the pointer cannot reach is reachable the same way for every type.
    function applyControl(groupIndex: int, optionIndex: int): bool {
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

    // An action is a function the unit lists in `actions`. Pointer, keyboard
    // and the harness all reach it the same way, so there is one door.
    function triggerAction(index: int): bool {
        if (!_loaded)
            return false
        const list = actions
        if (index < 0 || index >= list.length)
            return false
        const action = list[index]
        if (!action)
            return false
        const name = action.trigger !== undefined ? String(action.trigger)
            : action.text !== undefined ? String(action.text) : ""
        if (name === "" || typeof _unit[name] !== "function")
            return false
        _unit[name]()
        return true
    }

    // The tree dump is the unit's item tree plus the facts the harness cannot
    // see: which states it declared, and whether it can be driven at all.
    function dumpTree(): void {
        inspectionReady({
            story: storyKey,
            component: component,
            variant: variant,
            status: storyStatus,
            error: storyError,
            drivable: _drivable,
            events: events,
            controlGroups: controls.length,
            actionCount: actions.length
        })
    }

    Rectangle {
        anchors.fill: parent
        color: Style.background
    }

    Loader {
        id: unitLoader
        // `undefined` rather than an empty URL: an assigned source puts the
        // Loader in URL mode even when it is blank, and then `storyStatus`
        // never reaches "ready".
        source: root.mode === "story" ? root._unitSource : undefined
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
                item.eventRecorder = (kind, name, payload) => root.eventRecorded({ "origin": kind, "name": name, "payload": payload ?? {} })
        }
    }

    // Reset is a reconstruction, not a message: a unit that cached a value is
    // as reset as a freshly loaded one, and nothing has to implement it.
    onResetGenerationChanged: {
        if (_unitSource === "")
            return
        unitLoader.active = false
        unitLoader.active = true
    }

    Connections {
        target: unitLoader.item
        function onEventRecorded(record) { root.eventRecorded(record) }
        function onInspectionReady(inspection) { root.inspectionReady(inspection) }
    }
}
