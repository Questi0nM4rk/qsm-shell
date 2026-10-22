pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import qs.QsmShell.Components
import qs.QsmShell.Style

// The host: a session menu in a popout frame, with a button before it so the
// keyboard has somewhere to arrive from. The host owns the cursor and mirrors
// every move the menu reports; a `Binding` keeps its selection control working
// after the menu has moved the cursor itself.
Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool modelled: false
    property int currentIndex: 1
    property string rowSize: "md"
    property bool longLabel: false
    property int activatedIndex: -1
    property int activations: 0
    property string modelSelection: ""

    readonly property var modelRows: ["Audio settings", "Network settings", "Display settings"]

    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    ColumnLayout {
        x: Style.snap((root.width - width) / 2, root)
        y: Style.snap((root.height - height) / 2, root)
        width: Style.controlWidth
        spacing: Style.space2

        Capsule {
            id: clear
            Layout.alignment: Qt.AlignLeft
            variant: "ghost"
            label: "Clear selection"
            onClicked: root.currentIndex = -1
        }

        Surface {
            Layout.fillWidth: true
            implicitHeight: menu.implicitHeight + Style.space2 * 2
            base: Style.overlay
            radius: Style.radiusLg

            Menu {
                id: menu

                x: Style.space2
                y: Style.space2
                width: parent.width - Style.space2 * 2
                model: root.modelled ? root.modelRows : null
                delegate: rowDelegate
                accessibleName: "Session"

                onCurrentIndexChanged: root.currentIndex = menu.currentIndex
                onActivated: index => {
                    root.activatedIndex = index
                    root.activations++
                    root.eventRecorder?.("intent", "activated", { index })
                }

                ListRow {
                    id: headerRow
                    size: root.rowSize
                    header: true
                    interactive: false
                    primary: "Session"
                }

                ListRow {
                    id: lockRow
                    size: root.rowSize
                    icon: "lock"
                    primary: root.longLabel
                        ? "Lock the screen and keep every running application exactly where it is"
                        : "Lock"
                    onActivated: root.eventRecorder?.("intent", "row-activated", { id: "lock" })
                }

                ListRow {
                    id: sleepRow
                    size: root.rowSize
                    icon: "moon"
                    primary: "Sleep"
                    disabled: true
                }

                ListRow {
                    id: powerRow
                    size: root.rowSize
                    icon: "power"
                    primary: "Power off"
                    danger: true
                    onActivated: root.eventRecorder?.("intent", "row-activated", { id: "power-off" })
                }
            }
        }
    }

    Binding {
        target: menu
        property: "currentIndex"
        value: root.currentIndex
    }

    Component {
        id: rowDelegate

        ListRow {
            required property string modelData
            size: root.rowSize
            primary: modelData
            onSelectedChanged: {
                if (selected)
                    root.modelSelection = modelData
                else if (root.modelSelection === modelData)
                    root.modelSelection = ""
            }
        }
    }

    readonly property var controls: [
        { label: "rows", options: [
            { label: "static", set: { modelled: false } },
            { label: "modelled", set: { modelled: true } }
        ] },
        { label: "selection", options: [
            { label: "lock", set: { currentIndex: 1 } },
            { label: "power-off", set: { currentIndex: 3 } },
            { label: "none", set: { currentIndex: -1 } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { rowSize: "sm" } },
            { label: "md", set: { rowSize: "md" } },
            { label: "lg", set: { rowSize: "lg" } }
        ] },
        { label: "label", options: [
            { label: "short", set: { longLabel: false } },
            { label: "long", set: { longLabel: true } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]

    // Which row the keyboard is in, by the name a person would give it.
    function _focusName(): string {
        for (let item = root.Window.window?.activeFocusItem ?? null; item; item = item.parent) {
            if (item === clear)
                return "clear"
            if (item === lockRow)
                return "lock"
            if (item === powerRow)
                return "power-off"
            if (item === menu)
                return "menu"
        }
        return ""
    }

    // The row Tab would land on.
    function _tabStopName(): string {
        const named = { lock: lockRow, sleep: sleepRow, "power-off": powerRow }
        return Object.keys(named).find(name => named[name].activeFocusOnTab) ?? ""
    }

    readonly property var integration: ({
        events: ["activated", "row-activated"],
        actions: ["step-next", "step-previous", "step-first", "step-last", "activate-current"],
        targets: ({
            clear: () => clear,
            menu: () => menu,
            lock: () => lockRow,
            "power-off": () => powerRow,
            scene: () => root
        }),
        observables: {
            "current-index": () => menu.currentIndex,
            "selected-lock": () => lockRow.selected,
            "selected-power-off": () => powerRow.selected,
            "model-selected": () => root.modelSelection,
            "activated-index": () => root.activatedIndex,
            activations: () => root.activations,
            focus: () => root._focusName(),
            "tab-stop": () => root._tabStopName(),
            "row-count": () => menu.rowCount,
            "group-name": () => menu.Accessible.name,
            "row-height": () => lockRow.height,
            "thumb-matches-row": () => root._thumbMatchesRow()
        },
        runAction: name => {
            if (name === "step-next") { menu.step(1); return true }
            if (name === "step-previous") { menu.step(-1); return true }
            if (name === "step-first") { menu.stepToEdge(true); return true }
            if (name === "step-last") { menu.stepToEdge(false); return true }
            if (name === "activate-current") { menu.activateCurrent(); return true }
            return false
        },
        keys: {
            "Enter": () => { menu.activateCurrent(); return true }
        }
    })

    // The thumb is the cursor row's rectangle, to the pixel.
    function _thumbMatchesRow(): bool {
        const row = menu.rowAt(menu.currentIndex) as ListRow
        if (!row)
            return true
        for (const item of menu.children) {
            if (item.objectName === "thumb") {
                const origin = row.mapToItem(menu, 0, 0)
                return item.x === origin.x && item.y === origin.y
                    && item.width === row.width && item.height === row.selectionHeight
            }
        }
        return false
    }
}
